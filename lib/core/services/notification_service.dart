// lib/core/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore;

  // Updated constructor with optional parameter - fully backward compatible!
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // All your existing methods remain exactly the same - just use _firestore instead of FirebaseFirestore.instance
  // Create notification for a single user
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? relatedId,
    String? imageUrl,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'relatedId': relatedId,
        'imageUrl': imageUrl,
      });

      print('✅ Notification created for user: $userId');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  // Create notification for all users (e.g., new opportunity)
  Future<void> createNotificationForAllUsers({
    required String type,
    required String title,
    required String message,
    String? relatedId,
    String? imageUrl,
  }) async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      
      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': userDoc.id,
          'type': type,
          'title': title,
          'message': message,
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
          'relatedId': relatedId,
          'imageUrl': imageUrl,
        });
      }
      
      await batch.commit();
      print('✅ Notifications created for ${usersSnapshot.docs.length} users');
    } catch (e) {
      print('❌ Error creating notifications for all users: $e');
    }
  }

  // Notification for new opportunity
  Future<void> notifyNewOpportunity({
    required String opportunityTitle,
    required String opportunityId,
    String? imageUrl,
  }) async {
    await createNotificationForAllUsers(
      type: 'opportunityPosted',
      title: 'New Opportunity Available',
      message: 'Check out "$opportunityTitle" and apply now!',
      relatedId: opportunityId,
      imageUrl: imageUrl,
    );
  }

  // Notification for application status
  Future<void> notifyApplicationStatus({
    required String userId,
    required String opportunityTitle,
    required bool accepted,
    required String opportunityId,
  }) async {
    await createNotification(
      userId: userId,
      type: accepted ? 'applicationAccepted' : 'applicationRejected',
      title: accepted ? 'Application Accepted! 🎉' : 'Application Update',
      message: accepted
          ? 'Congratulations! Your application for "$opportunityTitle" has been accepted.'
          : 'Your application for "$opportunityTitle" was not accepted this time. Keep trying!',
      relatedId: opportunityId,
    );
  }

  // Notification for new comment
  Future<void> notifyNewComment({
    required String postAuthorId,
    required String commenterName,
    required String postId,
  }) async {
    await createNotification(
      userId: postAuthorId,
      type: 'comment',
      title: 'New Comment on Your Post',
      message: '$commenterName commented on your post.',
      relatedId: postId,
    );
  }
}