import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_selection_card.dart';

void main() {
  group('🛡️ TeamRegistrationSelectionCard Widget Tests', () {
    testWidgets('Renders selectable player card and handles tap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamRegistrationSelectionCard(
              name: '佐藤 太郎',
              subtitle: '三段 / 20歳',
              isUsed: false,
              usedPos: '',
              isDark: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('佐藤 太郎'), findsOneWidget);
      expect(find.text('三段 / 20歳'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      await tester.tap(find.text('佐藤 太郎'));
      expect(tapped, isTrue);
    });

    testWidgets('Renders used/helper player card with swap badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamRegistrationSelectionCard(
              name: '鈴木 次郎',
              subtitle: '二段 / 18歳',
              isUsed: true,
              usedPos: '先鋒',
              isDark: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('鈴木 次郎'), findsOneWidget);
      expect(find.text('先鋒と入替'), findsOneWidget);
    });
  });
}
