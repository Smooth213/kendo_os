import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_chips.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] 部門ルール チップバッジ ＆ 詳細ボトムシート 統合検証テスト', () {
    testWidgets('標準ルールチップが正しく描画されること', (WidgetTester tester) async {
      const ruleSet = CategoryRuleSet(
        normalRule: MatchRule(
          matchTimeMinutes: 3.0,
          enchoCount: 0,
          isEnchoUnlimited: true,
          hasHantei: false,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryRuleChips(ruleSet: ruleSet, isDark: false),
          ),
        ),
      );

      expect(find.text('🥋 個人戦'), findsOneWidget);
      expect(find.text('⏱️ 3分'), findsOneWidget);
      expect(find.text('⏳ 延長無制限'), findsOneWidget);
    });

    testWidgets('マルチシーン（錬成会・本戦・申合せ）のバッジが統一カラーで正しく描画されること', (
      WidgetTester tester,
    ) async {
      const ruleSet = CategoryRuleSet(
        matchType: '団体戦',
        isMultiScene: true,
        useRenseikaiRule: true,
        useHonsenRule: true,
        useMoushiawaseRule: true,
        renseikaiRule: MatchRule(
          matchTimeMinutes: 2.0,
          isRunningTime: true,
          hasHantei: true,
        ),
        normalRule: MatchRule(
          matchTimeMinutes: 4.0,
          hasRepresentativeMatch: true,
          isEnchoUnlimited: true,
        ),
        moushiawaseRule: MatchRule(matchTimeMinutes: 2.0, hasHantei: true),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryRuleChips(ruleSet: ruleSet, isDark: true),
          ),
        ),
      );

      expect(find.text('⚔️ 錬成'), findsOneWidget);
      expect(find.text('🔄 通し'), findsOneWidget);
      expect(find.text('🏆 本戦'), findsOneWidget);
      expect(find.text('⏱️ 4分'), findsOneWidget);
      expect(find.text('🤝 申合せ'), findsOneWidget);
      expect(find.text('🥋 代表戦有'), findsOneWidget);
      expect(find.text('⏳ 延長無制限'), findsOneWidget);
    });

    testWidgets('上位戦（1本勝負設定）を含むチップバッジが正しく描画されること', (WidgetTester tester) async {
      const ruleSet = CategoryRuleSet(
        useAdvancedRule: true,
        normalRule: MatchRule(matchTimeMinutes: 3.0, isIpponShobu: false),
        advancedRule: MatchRule(
          matchTimeMinutes: 2.5,
          isIpponShobu: true,
          isEnchoUnlimited: true,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryRuleChips(ruleSet: ruleSet, isDark: false),
          ),
        ),
      );

      expect(find.text('🥋 個人戦'), findsOneWidget);
      expect(find.text('⏱️ 3分'), findsOneWidget);
      expect(find.text('🔥 上位戦'), findsOneWidget);
      expect(find.text('⏱️ 2分30秒'), findsOneWidget);
      expect(find.text('⚡ 1本勝負'), findsOneWidget);
      expect(find.text('⏳ 延長無制限'), findsOneWidget);
    });

    testWidgets('詳細ボトムシートにおいて標準設定および代表戦設定が正しく描画されること', (
      WidgetTester tester,
    ) async {
      const ruleSet = CategoryRuleSet(
        matchType: '団体戦',
        normalRule: MatchRule(
          matchTimeMinutes: 4.0,
          hasRepresentativeMatch: true,
          isDaihyoIpponShobu: true,
          daihyoMatchTimeMinutes: 3.0,
          daihyoEnchoCount: -2,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryRuleDetailBottomSheet(
              categoryName: '高校男子団体の部',
              ruleSet: ruleSet,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('高校男子団体の部 のルール設定'), findsOneWidget);
      expect(find.text('団体戦・チーム設定'), findsOneWidget);
      expect(find.text('代表戦'), findsOneWidget);
      expect(find.text('代表戦勝負形式'), findsOneWidget);
      expect(find.text('代表戦時間'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('詳細ボトムシートにおいてサブタイトルと特記事項コメントが正しく描画されること', (
      WidgetTester tester,
    ) async {
      const ruleSet = CategoryRuleSet(
        subtitle: '決勝トーナメント',
        comment: '3人制・代表戦あり',
        normalRule: MatchRule(matchTimeMinutes: 3.0),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryRuleDetailBottomSheet(
              categoryName: '小学生の部',
              ruleSet: ruleSet,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('小学生の部 決勝トーナメント のルール設定'), findsOneWidget);
      expect(find.text('コメント・特記事項'), findsOneWidget);
      expect(find.text('3人制・代表戦あり'), findsOneWidget);
    });
  });
}
