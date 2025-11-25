// test/presentation/widgets/activity_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/domain/models/volunteer_activity.dart';
import 'package:pamoja_app/presentation/widgets/activity_card.dart';

void main() {
  group('ActivityCard Widget', () {
    testWidgets('displays activity information correctly', (tester) async {
      final activity = VolunteerActivity(
        id: '1',
        title: 'Beach Cleanup',
        description: 'Clean the beach',
        imageUrl: 'https://example.com/beach.jpg',
        status: ActivityStatus.confirmed,
        appliedDate: DateTime.now(),
        confirmedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Beach Cleanup'), findsOneWidget);
      expect(find.text('Clean the beach'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;
      final activity = VolunteerActivity(
        id: '1',
        title: 'Test Activity',
        description: 'Test Description',
        imageUrl: 'https://example.com/test.jpg',
        status: ActivityStatus.applied,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ActivityCard));
      expect(tapped, true);
    });

    testWidgets('displays correct status for applied activity', (tester) async {
      final activity = VolunteerActivity(
        id: '1',
        title: 'Test Activity',
        description: 'Test Description',
        imageUrl: 'https://example.com/test.jpg',
        status: ActivityStatus.applied,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Applied'), findsOneWidget);
    });

    testWidgets('displays correct status for completed activity', (tester) async {
      final activity = VolunteerActivity(
        id: '1',
        title: 'Test Activity',
        description: 'Test Description',
        imageUrl: 'https://example.com/test.jpg',
        status: ActivityStatus.completed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('displays correct status for rejected activity', (tester) async {
      final activity = VolunteerActivity(
        id: '1',
        title: 'Test Activity',
        description: 'Test Description',
        imageUrl: 'https://example.com/test.jpg',
        status: ActivityStatus.rejected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('displays progress indicator', (tester) async {
      final activity = VolunteerActivity(
        id: '1',
        title: 'Test Activity',
        description: 'Test Description',
        imageUrl: 'https://example.com/test.jpg',
        status: ActivityStatus.confirmed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays chevron right icon', (tester) async {
      final activity = VolunteerActivity(
        id: '1',
        title: 'Test Activity',
        description: 'Test Description',
        imageUrl: 'https://example.com/test.jpg',
        status: ActivityStatus.applied,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });
}