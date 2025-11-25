import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/domain/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    // Use final instead of const for DateTime
    final testNotification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: NotificationType.opportunityPosted,
      title: 'New Opportunity',
      message: 'A new opportunity is available',
      read: false,
      timestamp: DateTime(2024, 1, 1),
      relatedId: 'opp1',
      imageUrl: 'image.jpg',
    );

    test('should create NotificationModel with correct properties', () {
      expect(testNotification.id, '1');
      expect(testNotification.userId, 'user1');
      expect(testNotification.type, NotificationType.opportunityPosted);
      expect(testNotification.title, 'New Opportunity');
      expect(testNotification.read, false);
      expect(testNotification.relatedId, 'opp1');
    });

    test('props should contain all properties', () {
      expect(testNotification.props, [
        '1',
        'user1',
        NotificationType.opportunityPosted,
        'New Opportunity',
        'A new opportunity is available',
        false,
        DateTime(2024, 1, 1),
        'opp1',
        'image.jpg',
      ]);
    });

    test('should create NotificationModel from json', () {
      final json = {
        'id': '1',
        'userId': 'user1',
        'type': 'opportunityPosted',
        'title': 'New Opportunity',
        'message': 'A new opportunity is available',
        'read': false,
        'timestamp': '2024-01-01T00:00:00.000',
        'relatedId': 'opp1',
        'imageUrl': 'image.jpg',
      };

      final notification = NotificationModel.fromJson(json);

      expect(notification.id, '1');
      expect(notification.userId, 'user1');
      expect(notification.type, NotificationType.opportunityPosted);
      expect(notification.title, 'New Opportunity');
      expect(notification.read, false);
      expect(notification.relatedId, 'opp1');
    });

    test('should handle null optional fields in fromJson', () {
      final json = {
        'id': '1',
        'userId': 'user1',
        'type': 'opportunityPosted',
        'title': 'New Opportunity',
        'message': 'A new opportunity is available',
        'read': false,
        'timestamp': '2024-01-01T00:00:00.000',
      };

      final notification = NotificationModel.fromJson(json);

      expect(notification.relatedId, isNull);
      expect(notification.imageUrl, isNull);
    });

    test('should convert NotificationModel to json', () {
      final json = testNotification.toJson();

      expect(json['id'], '1');
      expect(json['userId'], 'user1');
      expect(json['type'], 'opportunityPosted');
      expect(json['title'], 'New Opportunity');
      expect(json['read'], false);
      expect(json['relatedId'], 'opp1');
      expect(json['imageUrl'], 'image.jpg');
      expect(json['timestamp'], '2024-01-01T00:00:00.000');
    });

    test('copyWith should update specified fields', () {
      final updated = testNotification.copyWith(
        read: true,
        title: 'Updated Title',
      );

      expect(updated.id, '1');
      expect(updated.read, true);
      expect(updated.title, 'Updated Title');
      expect(updated.userId, 'user1'); // unchanged
    });

    test('should handle unknown notification type with default', () {
      final json = {
        'id': '1',
        'userId': 'user1',
        'type': 'unknownType',
        'title': 'Test',
        'message': 'Test message',
        'read': false,
        'timestamp': '2024-01-01T00:00:00.000',
      };

      final notification = NotificationModel.fromJson(json);

      expect(notification.type, NotificationType.opportunityPosted);
    });

    test('should be equal when properties are same', () {
      final notif1 = NotificationModel(
        id: '1',
        userId: 'user1',
        type: NotificationType.opportunityPosted,
        title: 'Test',
        message: 'Message',
        read: false,
        timestamp: DateTime(2024, 1, 1),
      );

      final notif2 = NotificationModel(
        id: '1',
        userId: 'user1',
        type: NotificationType.opportunityPosted,
        title: 'Test',
        message: 'Message',
        read: false,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(notif1, notif2);
    });
  });
}