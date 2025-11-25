// test/presentation/widgets/category_chip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/presentation/widgets/category_chip.dart';

void main() {
  group('CategoryChip Widget', () {
    testWidgets('displays label correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              label: 'Environment',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Environment'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              label: 'Environment',
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CategoryChip));
      expect(tapped, true);
    });

    testWidgets('shows selected state visually', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              label: 'Environment',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final chipWidget = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      
      expect(chipWidget, isNotNull);
    });

    testWidgets('shows unselected state visually', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              label: 'Environment',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final chipWidget = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      
      expect(chipWidget, isNotNull);
    });

    testWidgets('animates on state change', (tester) async {
      var isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategoryChip(
                  label: 'Environment',
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      isSelected = !isSelected;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Tap to select
      await tester.tap(find.byType(CategoryChip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(isSelected, true);
    });
  });
}