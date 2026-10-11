import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_format_selector_view.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

  group('[Widget] MatchFormatSelectorView ウィジェットテスト', () {
    testWidgets('5大分類と詳細人数が正常に選択・コールバック発火すること', (tester) async {
      String matchType = '団体戦（5人制）';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MatchFormatSelectorView(
                  currentMatchType: matchType,
                  themeColors: themeColors,
                  onMatchTypeChanged: (val) {
                    setState(() {
                      matchType = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // 5大分類が表示されていること
      expect(find.text('団体戦'), findsOneWidget);
      expect(find.text('個人戦'), findsOneWidget);
      expect(find.text('リーグ戦'), findsOneWidget);
      expect(find.text('勝ち抜き戦'), findsOneWidget);
      expect(find.text('剣道形'), findsOneWidget);

      // 初期状態で「5人制」が表示されていること
      expect(find.text('5人制'), findsOneWidget);

      // 「3人制」をタップ
      await tester.tap(find.text('3人制'));
      await tester.pumpAndSettle();
      expect(matchType, '団体戦（3人制）');

      // 「個人戦」をタップすると1タップで確定すること
      await tester.tap(find.text('個人戦'));
      await tester.pumpAndSettle();
      expect(matchType, '個人戦');

      // 「勝ち抜き戦」をタップ
      await tester.tap(find.text('勝ち抜き戦'));
      await tester.pumpAndSettle();
      expect(matchType, '勝ち抜き戦（5人制）');
    });
  });
}
