import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/domain/models/opportunity.dart';
import 'package:pamoja_app/presentation/widgets/opportunity_card.dart';

void main() {
  group('OpportunityCard Widget', () {
    testWidgets('displays opportunity information', (tester) async {
      final opportunity = Opportunity(
        id: '1',
        title: 'Beach Cleanup',
        description: 'Help clean the beach',
        category: 'Environment',
        location: 'Santa Monica',
        timeCommitment: '3 hours',
        requirements: 'None',
        imageUrl: 'https://example.com/beach.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpportunityCard(
              opportunity: opportunity,
              onTap: () {},
              isSaved: false,
              onSaveToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Beach Cleanup'), findsOneWidget);
      expect(find.text('Environment'), findsOneWidget);
      expect(find.text('Santa Monica'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      final opportunity = Opportunity(
        id: '1',
        title: 'Test',
        description: 'Test',
        category: 'Test',
        location: 'Test',
        timeCommitment: 'Test',
        requirements: 'Test',
        imageUrl: 'https://example.com/test.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpportunityCard(
              opportunity: opportunity,
              onTap: () => tapped = true,
              isSaved: false,
              onSaveToggle: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OpportunityCard));
      expect(tapped, true);
    });
  });
}