// test/presentation/widgets/simple_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/presentation/widgets/activity_card.dart';
import 'package:pamoja_app/domain/models/volunteer_activity.dart';

void main() {
  group('ActivityCard Widget Tests', () {
    testWidgets('ActivityCard displays activity information correctly', (tester) async {
      final activity = VolunteerActivity(
        id: '1',
        title: 'Beach Cleanup',
        description: 'Help clean the beach',
        imageUrl: 'https://example.com/beach.jpg',
        status: ActivityStatus.applied,
        appliedDate: DateTime.now(),
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

      // Verify the activity title is displayed
      expect(find.text('Beach Cleanup'), findsOneWidget);
      
      // Verify the activity description is displayed
      expect(find.text('Help clean the beach'), findsOneWidget);
    });

    testWidgets('ActivityCard handles tap correctly', (tester) async {
      var tapped = false;
      final activity = VolunteerActivity(
        id: '1',
        title: 'Test Activity',
        description: 'Test Description',
        imageUrl: 'https://example.com/test.jpg',
        status: ActivityStatus.applied,
        appliedDate: DateTime.now(),
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
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('ActivityCard displays correct status badge', (tester) async {
      final activity = VolunteerActivity(
        id: '1',
        title: 'Test Activity',
        description: 'Test Description',
        imageUrl: 'https://example.com/test.jpg',
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

      // Verify the status label is displayed
      expect(find.text('Confirmed'), findsOneWidget);
    });
  });
}