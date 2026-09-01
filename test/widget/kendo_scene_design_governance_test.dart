import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_chips.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🏛️ 試合シーン（本戦・錬成・申合せ）表記＆配色 デザインガバナンス回帰テスト要塞', () {
    test('1. KendoSceneHelper: 表記および白飛びゼロカラーの定義整合性検証', () {
      // 1) 表記の完全統一
      expect(KendoSceneHelper.getLabel(KendoMatchScene.honsen), '【本戦】');
      expect(KendoSceneHelper.getLabel(KendoMatchScene.renseikai), '【錬成】');
      expect(KendoSceneHelper.getLabel(KendoMatchScene.moushiawase), '【申合せ】');
      expect(KendoSceneHelper.getLabel(KendoMatchScene.bunaiksen), '【部内戦】');

      expect(KendoSceneHelper.getIconLabel(KendoMatchScene.honsen), '🏆 本戦');
      expect(KendoSceneHelper.getIconLabel(KendoMatchScene.renseikai), '⚔️ 錬成');
      expect(
        KendoSceneHelper.getIconLabel(KendoMatchScene.moushiawase),
        '🤝 申合せ',
      );
      expect(
        KendoSceneHelper.getIconLabel(KendoMatchScene.bunaiksen),
        '🛡️ 部内戦',
      );

      // 2) ライトモードの白飛び防止カラー検証
      final lightRenseikaiColor = KendoSceneHelper.getColor(
        KendoMatchScene.renseikai,
        isDark: false,
      );
      final lightMoushiawaseColor = KendoSceneHelper.getColor(
        KendoMatchScene.moushiawase,
        isDark: false,
      );
      final lightHonsenColor = KendoSceneHelper.getColor(
        KendoMatchScene.honsen,
        isDark: false,
      );

      // 錬成（ライトモード）は白飛びしない濃橙・ディープオレンジ (#C2410C)
      expect(lightRenseikaiColor, const Color(0xFFC2410C));
      // 申合せ（ライトモード）は白飛びしない濃紅・ディープローズ (#BE185D)
      expect(lightMoushiawaseColor, const Color(0xFFBE185D));
      // 本戦（ライトモード）はロイヤルインディゴ (#1D4ED8)
      expect(lightHonsenColor, const Color(0xFF1D4ED8));

      // 3) ダークモードのルミナスカラー検証
      final darkRenseikaiColor = KendoSceneHelper.getColor(
        KendoMatchScene.renseikai,
        isDark: true,
      );
      final darkMoushiawaseColor = KendoSceneHelper.getColor(
        KendoMatchScene.moushiawase,
        isDark: true,
      );
      expect(darkRenseikaiColor, const Color(0xFFFB923C));
      expect(darkMoushiawaseColor, const Color(0xFFF472B6));
    });

    testWidgets('2. KendoSceneBadge: 各シーンのバッジが正しく描画され、旧表記が存在しないこと', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                KendoSceneBadge(scene: KendoMatchScene.honsen),
                KendoSceneBadge(scene: KendoMatchScene.renseikai),
                KendoSceneBadge(scene: KendoMatchScene.moushiawase),
                KendoSceneBadge(scene: KendoMatchScene.bunaiksen),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('【本戦】'), findsOneWidget);
      expect(find.text('【錬成】'), findsOneWidget);
      expect(find.text('【申合せ】'), findsOneWidget);
      expect(find.text('【部内戦】'), findsOneWidget);

      // 旧表記がUI上に存在しないことの保証
      expect(find.text('【錬成会】'), findsNothing);
      expect(find.text('【申し合わせ】'), findsNothing);
    });

    testWidgets(
      '3. CategoryRuleChips & DetailSheet: 統一表記（⚔️ 錬成 / 🤝 申合せ）で開くこと',
      (tester) async {
        const multiSceneRule = CategoryRuleSet(
          matchType: '団体戦',
          isMultiScene: true,
          useRenseikaiRule: true,
          useHonsenRule: true,
          useMoushiawaseRule: true,
          renseikaiRule: MatchRule(matchTimeMinutes: 3.0, isRunningTime: true),
          normalRule: MatchRule(matchTimeMinutes: 3.0),
          moushiawaseRule: MatchRule(matchTimeMinutes: 2.0),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    const CategoryRuleChips(
                      ruleSet: multiSceneRule,
                      isDark: false,
                    ),
                    ElevatedButton(
                      onPressed: () => CategoryRuleDetailBottomSheet.show(
                        context,
                        categoryName: '小学生の部',
                        ruleSet: multiSceneRule,
                        isDark: false,
                      ),
                      child: const Text('OpenSheet'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 一覧バッジの確認
        expect(find.text('⚔️ 錬成'), findsOneWidget);
        expect(find.text('🏆 本戦'), findsOneWidget);
        expect(find.text('🤝 申合せ'), findsOneWidget);
        expect(find.text('⚔️ 錬成会'), findsNothing);
        expect(find.text('🤝 申し合わせ'), findsNothing);

        // ボトムシートを開く
        await tester.tap(find.text('OpenSheet'));
        await tester.pumpAndSettle();

        expect(find.text('⚔️ 錬成ルール'), findsOneWidget);
        expect(find.text('🏆 本戦ルール'), findsOneWidget);
        expect(find.text('🤝 申合せルール'), findsOneWidget);
        expect(find.text('⚔️ 錬成会ルール'), findsNothing);
        expect(find.text('🤝 申し合わせルール'), findsNothing);
      },
    );
  });
}
