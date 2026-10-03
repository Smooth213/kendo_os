import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_quick_assign_bar.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 錬成会クイック選手アサインバー Pixel完全性テスト', () {
    const renseikaiRule = MatchRule(
      isRenseikai: true,
      skipEmptyRoster: true,
      teamName: '自チーム道場',
    );

    final List<MatchModel> teamMatches = [
      const MatchModel(
        id: 'm1',
        matchType: '先鋒',
        redName: '自チーム道場 : 選手A',
        whiteName: '相手道場 : 相手1',
        matchTimeMinutes: 2,
      ),
      const MatchModel(
        id: 'm2',
        matchType: '次鋒',
        redName: '自チーム道場 : 選手B',
        whiteName: '相手道場 : 相手2',
        matchTimeMinutes: 2,
      ),
      const MatchModel(
        id: 'm3',
        matchType: '中堅',
        redName: '自チーム道場 : 選手C',
        whiteName: '相手道場 : 相手3',
        matchTimeMinutes: 2,
      ),
      const MatchModel(
        id: 'm4',
        matchType: '副将',
        redName: '自チーム道場 : 選手D',
        whiteName: '相手道場 : 相手4',
        matchTimeMinutes: 2,
      ),
    ];

    Widget buildBarTestWidget({
      required bool isDark,
      required MatchModel targetMatch,
    }) {
      final themeColors = AppThemeColors.ofMode(
        isDark: isDark,
        mode: isDark ? 'dark' : 'normal',
      );

      return ProviderScope(
        child: MaterialApp(
          theme: isDark
              ? ThemeData.dark().copyWith(extensions: [themeColors])
              : ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: Center(
              child: Consumer(
                builder: (context, ref, _) {
                  return RenseikaiQuickAssignBar(
                    match: targetMatch,
                    rule: renseikaiRule,
                    teamMatches: teamMatches,
                    isDark: isDark,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('ライトモード未定枠において オレンジ強調ボーダーと出場選手選択UIが鮮明に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const emptyMatch = MatchModel(
        id: 'm5',
        matchType: '大将',
        redName: '自チーム道場 : 未定',
        whiteName: '相手道場 : 相手5',
        matchTimeMinutes: 2,
        rule: renseikaiRule,
      );

      await tester.pumpWidget(
        buildBarTestWidget(isDark: false, targetMatch: emptyMatch),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RenseikaiQuickAssignBar), findsOneWidget);
      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
      expect(find.text('出場選手を選択:'), findsOneWidget);

      // 4名の選手チップが配置されていること
      expect(find.text('選手A'), findsOneWidget);
      expect(find.text('選手B'), findsOneWidget);
      expect(find.text('選手C'), findsOneWidget);
      expect(find.text('選手D'), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(RenseikaiQuickAssignBar),
          matching: find.byType(Container),
        ),
      );
      final boxDecoration = container.decoration as BoxDecoration;
      final border = boxDecoration.border as Border;
      expect(border.top.color, AppKendoColors.orange);
      expect(border.top.width, 1.5);
    });

    testWidgets('ダークモード確定状態において 選手切替モードとして洗練されたUIが描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const assignedMatch = MatchModel(
        id: 'm5',
        matchType: '大将',
        redName: '自チーム道場 : 選手A',
        whiteName: '相手道場 : 相手5',
        matchTimeMinutes: 2,
        rule: renseikaiRule,
      );

      await tester.pumpWidget(
        buildBarTestWidget(isDark: true, targetMatch: assignedMatch),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RenseikaiQuickAssignBar), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
      expect(find.text('選手切替:'), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(RenseikaiQuickAssignBar),
          matching: find.byType(Container),
        ),
      );
      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.color, const Color(0xFF1E293B));
    });
  });
}
