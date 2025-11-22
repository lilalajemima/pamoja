import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/volunteer_activity.dart';

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

  UpdateActivityStatus(this.activityId, this.newStatus);

  @override
  List<Object?> get props => [activityId, newStatus];
}

class CancelApplication extends TrackerEvent {
  final String activityId;

  CancelApplication(this.activityId);

  @override
  List<Object?> get props => [activityId];
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

  TrackerBloc({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(TrackerInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<ApplyToOpportunity>(_onApplyToOpportunity);
    on<UpdateActivityStatus>(_onUpdateActivityStatus);
    on<CancelApplication>(_onCancelApplication);
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

      // Get all activities for this user
      final querySnapshot = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('appliedAt', descending: true)
          .get();

      final allActivities = querySnapshot.docs.map((doc) {
        final data = doc.data();

        // Handle Firestore Timestamp
        DateTime? date;
        if (data['appliedAt'] is Timestamp) {
          date = (data['appliedAt'] as Timestamp).toDate();
        } else if (data['appliedAt'] is String) {
          date = DateTime.parse(data['appliedAt']);
        }

        // Parse status
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
          date: date,
          progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      // Split into upcoming and past
      final now = DateTime.now();
      final upcoming = allActivities
          .where((a) =>
              a.status != ActivityStatus.completed &&
              a.status != ActivityStatus.cancelled &&
              (a.date == null || a.date!.isAfter(now)))
          .toList();

      final past = allActivities
          .where((a) =>
              a.status == ActivityStatus.completed ||
              a.status == ActivityStatus.cancelled ||
              (a.date != null && a.date!.isBefore(now)))
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

      // Check if user already applied
      final existingApplication = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .where('opportunityId', isEqualTo: event.opportunityId)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        emit(TrackerError('You have already applied to this opportunity'));
        return;
      }

      // Get user info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Create application in Firebase
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
        'progress': 0.0,
      });

      // Reload activities
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

      // Update status in Firebase
      await _firestore.collection('applications').doc(event.activityId).update({
        'status': event.newStatus.toString().split('.').last,
        'progress': event.newStatus == ActivityStatus.completed ? 1.0 : 0.5,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If completed, update user's completed activities count
      if (event.newStatus == ActivityStatus.completed) {
        await _firestore.collection('users').doc(user.uid).update({
          'completedActivities': FieldValue.increment(1),
          'totalHours': FieldValue.increment(3), // Assume 3 hours per activity
        });
      }

      // Reload activities
      await _loadAndEmitActivities(emit, 'Status updated successfully!');
    } catch (e) {
      emit(TrackerError('Failed to update status: ${e.toString()}'));
    }
  }

  Future<void> _onCancelApplication(
    CancelApplication event,
    Emitter<TrackerState> emit,
  ) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        emit(TrackerError('No user logged in'));
        return;
      }

      // Get application to check status
      final appDoc = await _firestore.collection('applications').doc(event.activityId).get();
      
      if (!appDoc.exists) {
        emit(TrackerError('Application not found'));
        return;
      }

      final appData = appDoc.data()!;
      final status = appData['status'];

      // Don't allow cancellation if already rejected
      if (status == 'rejected') {
        emit(TrackerError('Cannot cancel a rejected application'));
        return;
      }

      // Update status to cancelled
      await _firestore.collection('applications').doc(event.activityId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Reload activities
      await _loadAndEmitActivities(emit, 'Application cancelled successfully!');
    } catch (e) {
      emit(TrackerError('Failed to cancel application: ${e.toString()}'));
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

        DateTime? date;
        if (data['appliedAt'] is Timestamp) {
          date = (data['appliedAt'] as Timestamp).toDate();
        } else if (data['appliedAt'] is String) {
          date = DateTime.parse(data['appliedAt']);
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
          date: date,
          progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      final now = DateTime.now();
      final upcoming = allActivities
          .where((a) =>
              a.status != ActivityStatus.completed &&
              a.status != ActivityStatus.cancelled &&
              (a.date == null || a.date!.isAfter(now)))
          .toList();

      final past = allActivities
          .where((a) =>
              a.status == ActivityStatus.completed ||
              a.status == ActivityStatus.cancelled ||
              (a.date != null && a.date!.isBefore(now)))
          .toList();

      emit(TrackerOperationSuccess(
        message: message,
        upcomingActivities: upcoming,
        pastActivities: past,
      ));
    } catch (e) {
      emit(TrackerError('Failed to reload activities: ${e.toString()}'));
    }
  }
}