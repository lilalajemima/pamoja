// lib/presentation/blocs/notifications/notifications_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/notification_model.dart';

// Events
abstract class NotificationsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {}

class StartListening extends NotificationsEvent {}

class StopListening extends NotificationsEvent {}

class MarkAsRead extends NotificationsEvent {
  final String notificationId;

  MarkAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllAsRead extends NotificationsEvent {}

class DeleteNotification extends NotificationsEvent {
  final String notificationId;

  DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

// States
abstract class NotificationsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationsError extends NotificationsState {
  final String message;

  NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  bool _isListening = false;

  NotificationsBloc({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
  }

  Future<void> _onStartListening(
    StartListening event,
    Emitter<NotificationsState> emit,
  ) async {
    if (_isListening) return;
    
    _isListening = true;
    final user = _auth.currentUser;
    if (user == null) {
      emit(NotificationsError('No user logged in'));
      return;
    }

    // Cancel existing subscription if any
    await _notificationsSubscription?.cancel();

    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      _handleNotificationsSnapshot(querySnapshot);
    }, onError: (error) {
      if (_isListening) {
        add(LoadNotifications()); // Fallback to manual load
      }
    });
  }

  Future<void> _onStopListening(
    StopListening event,
    Emitter<NotificationsState> emit,
  ) async {
    _isListening = false;
    await _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
  }

  void _handleNotificationsSnapshot(QuerySnapshot querySnapshot) {
    final notifications = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      
      DateTime timestamp;
      if (data['timestamp'] is Timestamp) {
        timestamp = (data['timestamp'] as Timestamp).toDate();
      } else if (data['timestamp'] is String) {
        timestamp = DateTime.parse(data['timestamp']);
      } else {
        timestamp = DateTime.now();
      }

      return NotificationModel(
        id: doc.id,
        userId: data['userId'] ?? '',
        type: _parseNotificationType(data['type']),
        title: data['title'] ?? '',
        message: data['message'] ?? '',
        read: data['read'] ?? false,
        timestamp: timestamp,
        relatedId: data['relatedId'],
        imageUrl: data['imageUrl'],
      );
    }).toList();

    final unreadCount = notifications.where((n) => !n.read).length;

    // Emit the new state
    if (state is! NotificationsLoaded || 
        (state as NotificationsLoaded).notifications.length != notifications.length) {
      // Use a small delay to ensure we're in a valid state to emit
      Future.microtask(() {
        if (_isListening) {
          // We need to access the emitter, so we'll use add instead
          add(LoadNotifications());
        }
      });
    }
  }

  NotificationType _parseNotificationType(String typeString) {
    try {
      return NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.$typeString',
        orElse: () => NotificationType.opportunityPosted,
      );
    } catch (e) {
      return NotificationType.opportunityPosted;
    }
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(NotificationsError('No user logged in'));
        return;
      }

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      final notifications = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        DateTime timestamp;
        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else if (data['timestamp'] is String) {
          timestamp = DateTime.parse(data['timestamp']);
        } else {
          timestamp = DateTime.now();
        }

        return NotificationModel(
          id: doc.id,
          userId: data['userId'] ?? '',
          type: _parseNotificationType(data['type'] ?? 'opportunityPosted'),
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          read: data['read'] ?? false,
          timestamp: timestamp,
          relatedId: data['relatedId'],
          imageUrl: data['imageUrl'],
        );
      }).toList();

      final unreadCount = notifications.where((n) => !n.read).length;

      emit(NotificationsLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationsError('Failed to load notifications: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(event.notificationId)
          .update({'read': true});

      // Reload to reflect changes
      add(LoadNotifications());
    } catch (e) {
      emit(NotificationsError('Failed to mark as read: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      add(LoadNotifications());
    } catch (e) {
      emit(NotificationsError('Failed to mark all as read: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(event.notificationId)
          .delete();

      add(LoadNotifications());
    } catch (e) {
      emit(NotificationsError('Failed to delete notification: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _isListening = false;
    _notificationsSubscription?.cancel();
    return super.close();
  }
}