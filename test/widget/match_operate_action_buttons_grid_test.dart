import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_operate_action_buttons_grid.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ MatchOperateActionButtonsGrid Widget Tests', () {
    testWidgets('Renders all 4 buttons and triggers callbacks', (
      WidgetTester tester,
    ) async {
      bool shareClicked = false;
      bool restoreClicked = false;
      bool checkScoreClicked = false;
      bool checkRuleClicked = false;

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchOperateActionButtonsGrid(
              isViewOnly: false,
              isKachinuki: false,
              onShareUrl: () {
                shareClicked = true;
              },
              onRestoreHistory: () {
                restoreClicked = true;
              },
              onCheckScore: () {
                checkScoreClicked = true;
              },
              onCheckRule: () {
                checkRuleClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('観戦URLを共有'), findsOneWidget);
      expect(find.text('履歴から復元'), findsOneWidget);
      expect(find.text('スコアを確認'), findsOneWidget);
      expect(find.text('ルールを確認'), findsOneWidget);

      // タップ検証
      await tester.tap(find.text('観戦URLを共有'));
      await tester.pump();
      expect(shareClicked, isTrue);

      await tester.tap(find.text('履歴から復元'));
      await tester.pump();
      expect(restoreClicked, isTrue);

      await tester.tap(find.text('スコアを確認'));
      await tester.pump();
      expect(checkScoreClicked, isTrue);

      await tester.tap(find.text('ルールを確認'));
      await tester.pump();
      expect(checkRuleClicked, isTrue);
    });

    testWidgets('Disables restore button when isViewOnly is true', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchOperateActionButtonsGrid(
              isViewOnly: true,
              isKachinuki: true,
              onShareUrl: () {},
              onRestoreHistory: null,
              onCheckScore: () {},
              onCheckRule: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('履歴から復元'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });
}
