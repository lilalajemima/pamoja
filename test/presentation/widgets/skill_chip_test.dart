// test/presentation/widgets/skill_chip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/presentation/widgets/skill_chip.dart';

void main() {
  group('SkillChip Widget', () {
    testWidgets('displays skill label correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkillChip(
              label: 'Flutter',
            ),
          ),
        ),
      );

      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('shows delete icon when onDelete is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillChip(
              label: 'Flutter',
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('does not show delete icon when onDelete is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkillChip(
              label: 'Flutter',
              onDelete: null,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('calls onDelete when delete icon is tapped', (tester) async {
      var deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillChip(
              label: 'Flutter',
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(deleted, true);
    });

    testWidgets('renders as Chip widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkillChip(
              label: 'Flutter',
            ),
          ),
        ),
      );

      expect(find.byType(Chip), findsOneWidget);
    });
  });
}