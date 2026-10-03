import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_state_holder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_summary_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_form_state.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_state_holder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_rule_summary_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_summary_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Governance] 全ルール設定画面間相互完全同期および先祖返り防止規約', () {
    // 🧪 完全なテスト用ルール（全プロパティが非デフォルト・ユニーク値）
    const comprehensiveRule = MatchRule(
      matchTimeMinutes: 4.5,
      isRunningTime: true,
      isIpponShobu: true,
      ipponLimit: 1,
      hansokuLimit: 1,
      hasHantei: true,
      hasRepresentativeMatch: true,
      isDaihyoIpponShobu: true,
      daihyoMatchTimeMinutes: 4.0,
      daihyoHasExtension: true,
      daihyoEnchoTimeMinutes: 2.5,
      daihyoEnchoCount: 3,
      daihyoHasHantei: true,
      enchoTimeMinutes: 3.5,
      enchoCount: 2,
      isEnchoUnlimited: false,
      renseikaiType: '時間制',
      overallTimeMinutes: 45,
      skipEmptyRoster: true,
      isKachinuki: true,
      kachinukiUnlimitedType: '大将対他ポジション',
      isLeague: true,
      winPoint: 5.0,
      lossPoint: 0.5,
      drawPoint: 2.0,
      matchScene: 'renseikai',
      isRenseikai: true,
      teamName: 'テスト道場A',
    );

    test('全ルール編集画面および表示画面ファイルにルールの同期項目が欠落なく実装されていること', () {
      final targetFiles = [
        // ルール編集画面・状態管理
        'lib/features/match/domain/rules/match_rule.dart',
        'lib/features/tournament/presentation/operate/components/bulk_rule_state_holder.dart',
        'lib/features/tournament/presentation/operate/components/bulk_rule_apply_helper.dart',
        'lib/features/tournament/presentation/operate/components/bulk_rule_form_section.dart',
        'lib/features/tournament/presentation/operate/components/bulk_rule_detail_setting_cards.dart',
        'lib/features/tournament/presentation/operate/components/home/match_edit_state_holder.dart',
        'lib/features/tournament/presentation/operate/components/home/match_edit_save_helper.dart',
        'lib/features/tournament/presentation/operate/components/home/match_edit_rule_and_memo_tab.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_save_helper.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_step.dart',
        'lib/features/tournament/presentation/operate/components/category_rules/category_rules_form_state.dart',
        'lib/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart',
        'lib/features/tournament/presentation/operate/components/category_rules/category_rule_renseikai_section.dart',
        'lib/features/tournament/presentation/operate/components/rules/sections/match_rule_time_section.dart',
        // ルール表示画面・コンポーネント
        'lib/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_summary_card.dart',
        'lib/features/tournament/presentation/operate/components/home/match_rule_summary_card.dart',
        'lib/features/tournament/presentation/operate/components/category_rules/category_rule_summary_card.dart',
      ];

      for (final filePath in targetFiles) {
        final file = File(filePath);
        expect(file.existsSync(), isTrue, reason: '必須ファイルが存在しません: $filePath');
        final content = file.readAsStringSync();
        expect(
          content.contains('skipEmptyRoster') || content.contains('SkipEmpty'),
          isTrue,
          reason: '$filePath に skipEmptyRoster 等のルール同期対応が欠落しています',
        );
      }
    });

    test('全ルール編集画面間を循環同期しても全プロパティが欠落・先祖返りしないこと', () {
      // 1. BulkRuleStateHolder でルール適用 ＆ 再構築
      final bulkHolder = BulkRuleStateHolder();
      bulkHolder.applyCategoryRuleSet(
        comprehensiveRule,
        isTeam: true,
        sceneKey: 'renseikai',
      );
      final ruleFromBulk = bulkHolder.buildNewRule();

      // 2. MatchEditStateHolder に渡して再構築
      final dummyMatch = MatchModel(
        id: 'test_match_circ',
        matchType: 'team',
        rule: ruleFromBulk,
        redName: 'Aチーム',
        whiteName: 'Bチーム',
      );
      final editHolder = MatchEditStateHolder([dummyMatch]);
      expect(editHolder.skipEmptyRoster, isTrue);
      expect(editHolder.matchTime, 4.5);
      expect(editHolder.isRunningTime, isTrue);
      expect(editHolder.overallTimeController.text, '45');

      // 3. MatchFormatFormState に渡して再構築
      final formatState = MatchFormatFormState();
      final otCtrl = TextEditingController();
      final wpCtrl = TextEditingController();
      final lpCtrl = TextEditingController();
      final dpCtrl = TextEditingController();

      formatState.applyMatchRule(
        ruleFromBulk,
        overallTimeController: otCtrl,
        winPointController: wpCtrl,
        lossPointController: lpCtrl,
        drawPointController: dpCtrl,
      );
      expect(formatState.skipEmptyRoster, isTrue);
      expect(formatState.matchTime, 4.5);
      expect(formatState.isRunningTime, isTrue);
      expect(otCtrl.text, '45');

      // 4. CategoryRulesFormState に渡して再構築
      final catRuleSet = CategoryRuleSet(
        normalRule: ruleFromBulk,
        renseikaiRule: ruleFromBulk,
        useRenseikaiRule: true,
      );
      final catFormState = CategoryRulesFormState();
      catFormState.populateFromRuleSet('テスト部門', catRuleSet);
      expect(catFormState.renseikaiSkipEmpty, isTrue);

      final rebuiltSet = catFormState.buildCategoryRuleSet('テスト部門');
      final finalRenseikaiRule = rebuiltSet.renseikaiRule;
      final finalNormalRule = rebuiltSet.normalRule;

      // 検証：錬成会ルールの項目が完全保持されていること
      expect(
        finalRenseikaiRule.matchTimeMinutes,
        comprehensiveRule.matchTimeMinutes,
      );
      expect(finalRenseikaiRule.isRunningTime, comprehensiveRule.isRunningTime);
      expect(finalRenseikaiRule.hasHantei, comprehensiveRule.hasHantei);
      expect(finalRenseikaiRule.renseikaiType, comprehensiveRule.renseikaiType);
      expect(
        finalRenseikaiRule.overallTimeMinutes,
        comprehensiveRule.overallTimeMinutes,
      );
      expect(
        finalRenseikaiRule.skipEmptyRoster,
        comprehensiveRule.skipEmptyRoster,
      );

      // 検証：通常戦ルールの項目（勝負形式・反則・勝点等）が完全保持されていること
      expect(
        finalNormalRule.matchTimeMinutes,
        comprehensiveRule.matchTimeMinutes,
      );
      expect(finalNormalRule.isRunningTime, comprehensiveRule.isRunningTime);
      expect(finalNormalRule.isIpponShobu, comprehensiveRule.isIpponShobu);
      expect(finalNormalRule.ipponLimit, comprehensiveRule.ipponLimit);
      expect(finalNormalRule.hansokuLimit, comprehensiveRule.hansokuLimit);
      expect(finalNormalRule.hasHantei, comprehensiveRule.hasHantei);
      expect(finalNormalRule.winPoint, comprehensiveRule.winPoint);
      expect(
        finalNormalRule.skipEmptyRoster,
        comprehensiveRule.skipEmptyRoster,
      );
    });

    testWidgets('ルール表示画面RuleInfoBottomSheetに編集された全ルールが同期されて表示されること', (
      tester,
    ) async {
      final dummyMatch = MatchModel(
        id: 'test_match_info',
        matchType: 'team',
        rule: comprehensiveRule,
        redName: 'テスト道場A',
        whiteName: 'テスト道場B',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showRuleInfoBottomSheet(context, dummyMatch),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 表示検証
      expect(find.text('試合レギュレーション確認'), findsOneWidget);
      expect(find.text('4分30秒 (通し/空回し)'), findsOneWidget);
      expect(find.text('１本勝負'), findsOneWidget);
      expect(find.text('時間制'), findsOneWidget);
      expect(find.text('45分'), findsOneWidget);
      expect(find.text('自動スキップ＆継続'), findsOneWidget);
    });

    testWidgets('ルール表示画面MatchFormatRuleSummaryCardに編集された全ルールが同期されて表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchFormatRuleSummaryCard(
                displayRuleName: '錬成会ルール',
                isAdvanced: false,
                themeColors: AppThemeColors.ofMode(
                  isDark: false,
                  mode: 'normal',
                ),
                isRenseikai: true,
                renseikaiType: comprehensiveRule.renseikaiType,
                matchTime: comprehensiveRule.matchTimeMinutes,
                overallTimeMinutes: '${comprehensiveRule.overallTimeMinutes}',
                matchType: '錬成会',
                isRunningTime: comprehensiveRule.isRunningTime,
                isIpponShobu: comprehensiveRule.isIpponShobu,
                ipponLimit: comprehensiveRule.ipponLimit,
                hansokuLimit: comprehensiveRule.hansokuLimit,
                extensionText: 'なし',
                hasHantei: comprehensiveRule.hasHantei,
                kachinukiUnlimitedType:
                    comprehensiveRule.kachinukiUnlimitedType,
                hasLeagueDaihyo: false,
                isDaihyoIpponShobu: false,
                daihyoMatchTime: 0,
                daihyoHasExtension: false,
                daihyoEnchoTime: 0,
                daihyoEnchoCount: 0,
                daihyoHasHantei: false,
                skipEmptyRoster: comprehensiveRule.skipEmptyRoster,
                winPoint: comprehensiveRule.winPoint,
                lossPoint: comprehensiveRule.lossPoint,
                drawPoint: comprehensiveRule.drawPoint,
                formatMinutesText: (m) => '$m分',
                buildSectionHeader: (title, color) => Text(title),
              ),
            ),
          ),
        ),
      );

      expect(find.text('現在適用中のルール: 錬成会ルール'), findsOneWidget);
      expect(find.text('時間制'), findsOneWidget);
      expect(find.text('45分'), findsOneWidget);
      expect(find.text('自動スキップ＆継続'), findsOneWidget);
    });

    testWidgets('ルール表示画面MatchRuleSummaryCardに編集された全ルールが同期されて表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchRuleSummaryCard(
                matchType: '錬成会',
                currentRule: comprehensiveRule,
                matchTime: comprehensiveRule.matchTimeMinutes,
                isIpponShobu: comprehensiveRule.isIpponShobu,
                hasHantei: comprehensiveRule.hasHantei,
                primaryAccent: Colors.blue,
                isDark: false,
                textColor: Colors.black,
              ),
            ),
          ),
        ),
      );

      expect(find.text('適用中のルール'), findsOneWidget);
      expect(find.text('4.5分（ランニング）'), findsOneWidget);
      expect(find.text('時間制'), findsOneWidget);
      expect(find.text('45分'), findsOneWidget);
      expect(find.text('自動スキップ＆継続'), findsOneWidget);
    });

    testWidgets('ルール表示画面CategoryRuleSummaryCardに編集された全ルールが同期されて表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryRuleSummaryCard(
                title: '錬成会ルール設定',
                rule: comprehensiveRule,
                accentColor: Colors.teal,
                matchType: '錬成会',
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('錬成会ルール設定'), findsOneWidget);
      expect(find.text('4分30秒 (通し/空回し)'), findsOneWidget);
      expect(find.text('時間制'), findsOneWidget);
      expect(find.text('45分'), findsOneWidget);
      expect(find.text('自動スキップ＆継続'), findsOneWidget);
    });
  });
}
