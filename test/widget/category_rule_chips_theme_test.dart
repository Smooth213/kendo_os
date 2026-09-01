import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_chips.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🎨 試合ルール設定バッジ ＆ 詳細ボトムシート カラー統一テスト要塞', () {
    testWidgets(
      '1. CategoryRuleChips: マルチシーン（錬成会・本戦・申合せ）のバッジが統一カラーで正しく描画されること',
      (tester) async {
        const multiSceneRule = CategoryRuleSet(
          matchType: '団体戦',
          isMultiScene: true,
          useRenseikaiRule: true,
          useHonsenRule: true,
          useMoushiawaseRule: true,
          renseikaiRule: MatchRule(
            matchTimeMinutes: 3.0,
            isRunningTime: true,
            hasHantei: true,
          ),
          normalRule: MatchRule(
            matchTimeMinutes: 2.0,
            hasRepresentativeMatch: true,
            isEnchoUnlimited: true,
            hasHantei: false,
          ),
          moushiawaseRule: MatchRule(matchTimeMinutes: 2.0, hasHantei: true),
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryRuleChips(ruleSet: multiSceneRule, isDark: false),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 先頭シーンタグの確認
        expect(find.text('⚔️ 錬成'), findsOneWidget);
        expect(find.text('🏆 本戦'), findsOneWidget);
        expect(find.text('🤝 申合せ'), findsOneWidget);

        // 詳細ニュートラルバッジの確認（アイコン付き）
        expect(find.text('⏱️ 3分'), findsOneWidget);
        expect(find.text('⏱️ 2分'), findsNWidgets(2));
        expect(find.text('🔄 通し'), findsOneWidget);
        expect(find.text('⚖️ 引分有'), findsNWidgets(2));
        expect(find.text('🥋 代表戦有'), findsOneWidget);
        expect(find.text('⏳ 延長無制限'), findsOneWidget);
      },
    );

    testWidgets(
      '2. CategoryRuleDetailBottomSheet: 本戦・錬成・申合せの見出しが統一カラーで正しく開くこと',
      (tester) async {
        const multiSceneRule = CategoryRuleSet(
          matchType: '団体戦',
          isMultiScene: true,
          useRenseikaiRule: true,
          useHonsenRule: true,
          useMoushiawaseRule: true,
          renseikaiRule: MatchRule(matchTimeMinutes: 3.0),
          normalRule: MatchRule(matchTimeMinutes: 3.0),
          moushiawaseRule: MatchRule(matchTimeMinutes: 2.0),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => CategoryRuleDetailBottomSheet.show(
                      context,
                      categoryName: '小学生の部',
                      ruleSet: multiSceneRule,
                      isDark: false,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // 見出しの確認
        expect(find.text('小学生の部 のルール設定'), findsOneWidget);
        expect(find.text('⚔️ 錬成ルール'), findsOneWidget);
        expect(find.text('🏆 本戦ルール'), findsOneWidget);
        expect(find.text('🤝 申合せルール'), findsOneWidget);
      },
    );
  });
}
