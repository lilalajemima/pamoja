import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/domain/models/volunteer_activity.dart';

void main() {
  group('VolunteerActivity Model', () {
    test('should create activity with different statuses', () {
      final activity = VolunteerActivity(
        id: '1',
        title: 'Test Activity',
        description: 'Test Description',
        imageUrl: 'https://example.com/test.jpg',
        status: ActivityStatus.confirmed,
        appliedDate: DateTime.now(),
        confirmedDate: DateTime.now(),
      );

      expect(activity.status, ActivityStatus.confirmed);
      expect(activity.id, '1');
    });

    test('should handle null dates correctly', () {
      final activity = VolunteerActivity(
        id: '1',
        title: 'Test Activity',
        description: 'Test Description',
        imageUrl: 'https://example.com/test.jpg',
        status: ActivityStatus.applied,
      );

      expect(activity.confirmedDate, isNull);
      expect(activity.completedDate, isNull);
    });
  });
}