// lib/core/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // Check if user has notifications enabled
      final prefs = await SharedPreferences.getInstance();
      final inAppEnabled = prefs.getBool('inAppNotifications') ?? true;
      
      if (!inAppEnabled) return;

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

      // Send email notification if enabled
      await _sendEmailNotification(userId, title, message);
    } catch (e) {
      print('Error creating notification: $e');
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

        // Send email to each user
        final userData = userDoc.data();
        if (userData['email'] != null) {
          await _sendEmailToUser(userData['email'], title, message);
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Error creating notifications for all users: $e');
    }
  }

  // Send email notification
  Future<void> _sendEmailNotification(
    String userId,
    String title,
    String message,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailEnabled = prefs.getBool('emailNotifications') ?? true;
      
      if (!emailEnabled) return;

      // Get user email
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userEmail = userDoc.data()?['email'];
      
      if (userEmail != null) {
        await _sendEmailToUser(userEmail, title, message);
      }
    } catch (e) {
      print('Error sending email notification: $e');
    }
  }

  // Send email using Firestore trigger
  Future<void> _sendEmailToUser(
    String email,
    String title,
    String message,
  ) async {
    try {
      await _firestore.collection('mail').add({
        'to': email,
        'message': {
          'subject': 'Pamoja - $title',
          'html': '''
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #00D66B; color: white; padding: 20px; text-align: center; }
                .content { background-color: #f9f9f9; padding: 20px; }
                .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>Pamoja</h1>
                </div>
                <div class="content">
                  <h2>$title</h2>
                  <p>$message</p>
                  <p>Open the Pamoja app to view details.</p>
                </div>
                <div class="footer">
                  <p>You received this email because you have notifications enabled in Pamoja.</p>
                  <p>To manage your notification preferences, open the app and go to Settings.</p>
                </div>
              </div>
            </body>
            </html>
          ''',
        },
      });
    } catch (e) {
      print('Error adding email to queue: $e');
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