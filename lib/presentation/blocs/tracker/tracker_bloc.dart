import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/volunteer_activity.dart';
import '../../../core/services/notification_service.dart';

// Events
abstract class TrackerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadActivities extends TrackerEvent {}

class ApplyToOpportunity extends TrackerEvent {
  final String opportunityId;
  final String opportunityTitle;
  final String description;
  final String imageUrl;

  ApplyToOpportunity({
    required this.opportunityId,
    required this.opportunityTitle,
    required this.description,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [opportunityId, opportunityTitle, description, imageUrl];
}

class UpdateActivityStatus extends TrackerEvent {
  final String activityId;
  final ActivityStatus newStatus;
  final String opportunityTitle;
  final String opportunityId;

  UpdateActivityStatus(
    this.activityId, 
    this.newStatus, {
    required this.opportunityTitle,
    required this.opportunityId,
  });

  @override
  List<Object?> get props => [activityId, newStatus, opportunityTitle, opportunityId];
}

// States
abstract class TrackerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TrackerInitial extends TrackerState {}

class TrackerLoading extends TrackerState {}

class TrackerLoaded extends TrackerState {
  final List<VolunteerActivity> upcomingActivities;
  final List<VolunteerActivity> pastActivities;

  TrackerLoaded({
    required this.upcomingActivities,
    required this.pastActivities,
  });

  @override
  List<Object?> get props => [upcomingActivities, pastActivities];
}

class TrackerError extends TrackerState {
  final String message;

  TrackerError(this.message);

  @override
  List<Object?> get props => [message];
}

class TrackerOperationSuccess extends TrackerState {
  final String message;
  final List<VolunteerActivity> upcomingActivities;
  final List<VolunteerActivity> pastActivities;

  TrackerOperationSuccess({
    required this.message,
    required this.upcomingActivities,
    required this.pastActivities,
  });

  @override
  List<Object?> get props => [message, upcomingActivities, pastActivities];
}

// BLoC
class TrackerBloc extends Bloc<TrackerEvent, TrackerState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  TrackerBloc({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService(),
        super(TrackerInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<ApplyToOpportunity>(_onApplyToOpportunity);
    on<UpdateActivityStatus>(_onUpdateActivityStatus);
  }

  Future<void> _onLoadActivities(
    LoadActivities event,
    Emitter<TrackerState> emit,
  ) async {
    emit(TrackerLoading());

    try {
      final user = _auth.currentUser;

      if (user == null) {
        emit(TrackerError('No user logged in'));
        return;
      }

      final querySnapshot = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('appliedAt', descending: true)
          .get();

      final allActivities = querySnapshot.docs.map((doc) {
        final data = doc.data();

        DateTime? appliedDate;
        if (data['appliedAt'] is Timestamp) {
          appliedDate = (data['appliedAt'] as Timestamp).toDate();
        } else if (data['appliedAt'] is String) {
          appliedDate = DateTime.parse(data['appliedAt']);
        }

        DateTime? confirmedDate;
        if (data['confirmedAt'] is Timestamp) {
          confirmedDate = (data['confirmedAt'] as Timestamp).toDate();
        } else if (data['confirmedAt'] is String) {
          confirmedDate = DateTime.parse(data['confirmedAt']);
        }

        DateTime? completedDate;
        if (data['completedAt'] is Timestamp) {
          completedDate = (data['completedAt'] as Timestamp).toDate();
        } else if (data['completedAt'] is String) {
          completedDate = DateTime.parse(data['completedAt']);
        }

        ActivityStatus status = ActivityStatus.applied;
        if (data['status'] != null) {
          try {
            status = ActivityStatus.values.firstWhere(
              (e) => e.toString() == 'ActivityStatus.${data['status']}',
              orElse: () => ActivityStatus.applied,
            );
          } catch (e) {
            status = ActivityStatus.applied;
          }
        }

        return VolunteerActivity(
          id: doc.id,
          title: data['opportunityTitle'] ?? 'Activity',
          description: data['description'] ?? 'Volunteer activity',
          imageUrl: data['imageUrl'] ?? 'https://images.unsplash.com/photo-1559027615-cd4628902d4a',
          status: status,
          appliedDate: appliedDate,
          confirmedDate: confirmedDate,
          completedDate: completedDate,
          rejectionReason: data['rejectionReason'] as String?,
        );
      }).toList();

      final upcoming = allActivities
          .where((a) =>
              a.status != ActivityStatus.completed &&
              a.status != ActivityStatus.rejected)
          .toList();

      final past = allActivities
          .where((a) =>
              a.status == ActivityStatus.completed ||
              a.status == ActivityStatus.rejected)
          .toList();

      emit(TrackerLoaded(
        upcomingActivities: upcoming,
        pastActivities: past,
      ));
    } catch (e) {
      emit(TrackerError('Failed to load activities: ${e.toString()}'));
    }
  }

  Future<void> _onApplyToOpportunity(
    ApplyToOpportunity event,
    Emitter<TrackerState> emit,
  ) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        emit(TrackerError('You must be logged in to apply'));
        return;
      }

      final existingApplication = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .where('opportunityId', isEqualTo: event.opportunityId)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        emit(TrackerError('You have already applied to this opportunity'));
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      await _firestore.collection('applications').add({
        'userId': user.uid,
        'userName': userData['name'] ?? 'User',
        'userEmail': userData['email'] ?? user.email,
        'userAvatar': userData['avatarUrl'] ?? 'https://i.pravatar.cc/150?u=${user.uid}',
        'opportunityId': event.opportunityId,
        'opportunityTitle': event.opportunityTitle,
        'imageUrl': event.imageUrl,
        'description': event.description,
        'status': 'applied',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      await _loadAndEmitActivities(emit, 'Application submitted successfully!');
    } catch (e) {
      emit(TrackerError('Failed to apply: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateActivityStatus(
    UpdateActivityStatus event,
    Emitter<TrackerState> emit,
  ) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        emit(TrackerError('No user logged in'));
        return;
      }

      final updateData = <String, dynamic>{
        'status': event.newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (event.newStatus == ActivityStatus.confirmed) {
        updateData['confirmedAt'] = FieldValue.serverTimestamp();
      } else if (event.newStatus == ActivityStatus.completed) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('applications').doc(event.activityId).update(updateData);

      // Send notification about application status change
      if (event.newStatus == ActivityStatus.confirmed || 
          event.newStatus == ActivityStatus.rejected) {
        print('📢 Sending application status notification to user: ${user.uid}');
        
        await _notificationService.notifyApplicationStatus(
          userId: user.uid,
          opportunityTitle: event.opportunityTitle,
          accepted: event.newStatus == ActivityStatus.confirmed,
          opportunityId: event.opportunityId,
        );
        
        print('✅ Application status notification sent!');
      }

      if (event.newStatus == ActivityStatus.completed) {
        await _firestore.collection('users').doc(user.uid).update({
          'completedActivities': FieldValue.increment(1),
          'totalHours': FieldValue.increment(3),
        });
      }

      await _loadAndEmitActivities(emit, 'Status updated successfully!');
    } catch (e) {
      print('❌ Error updating activity status: $e');
      emit(TrackerError('Failed to update status: ${e.toString()}'));
    }
  }

  Future<void> _loadAndEmitActivities(
    Emitter<TrackerState> emit,
    String message,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final querySnapshot = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('appliedAt', descending: true)
          .get();

      final allActivities = querySnapshot.docs.map((doc) {
        final data = doc.data();

        DateTime? appliedDate;
        if (data['appliedAt'] is Timestamp) {
          appliedDate = (data['appliedAt'] as Timestamp).toDate();
        } else if (data['appliedAt'] is String) {
          appliedDate = DateTime.parse(data['appliedAt']);
        }

        DateTime? confirmedDate;
        if (data['confirmedAt'] is Timestamp) {
          confirmedDate = (data['confirmedAt'] as Timestamp).toDate();
        } else if (data['confirmedAt'] is String) {
          confirmedDate = DateTime.parse(data['confirmedAt']);
        }

        DateTime? completedDate;
        if (data['completedAt'] is Timestamp) {
          completedDate = (data['completedAt'] as Timestamp).toDate();
        } else if (data['completedAt'] is String) {
          completedDate = DateTime.parse(data['completedAt']);
        }

        ActivityStatus status = ActivityStatus.applied;
        if (data['status'] != null) {
          try {
            status = ActivityStatus.values.firstWhere(
              (e) => e.toString() == 'ActivityStatus.${data['status']}',
              orElse: () => ActivityStatus.applied,
            );
          } catch (e) {
            status = ActivityStatus.applied;
          }
        }

        return VolunteerActivity(
          id: doc.id,
          title: data['opportunityTitle'] ?? 'Activity',
          description: data['description'] ?? 'Volunteer activity',
          imageUrl: data['imageUrl'] ?? 'https://images.unsplash.com/photo-1559027615-cd4628902d4a',
          status: status,
          appliedDate: appliedDate,
          confirmedDate: confirmedDate,
          completedDate: completedDate,
          rejectionReason: data['rejectionReason'] as String?,
        );
      }).toList();

      final upcoming = allActivities
          .where((a) =>
              a.status != ActivityStatus.completed &&
              a.status != ActivityStatus.rejected)
          .toList();

      final past = allActivities
          .where((a) =>
              a.status == ActivityStatus.completed ||
              a.status == ActivityStatus.rejected)
          .toList();

      emit(TrackerOperationSuccess(
        message: message,
        upcomingActivities: upcoming,
        pastActivities: past,
      ));
    } catch (e) {
      print('❌ Load error: $e');
      emit(TrackerError('Failed to reload activities: ${e.toString()}'));
    }
  }
}