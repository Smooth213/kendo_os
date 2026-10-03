import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_state_holder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_form_state.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_state_holder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart';

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

    test('全StateHolderおよびHelperクラスにskipEmptyRosterが欠落なく実装されていること', () {
      final targetFiles = [
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
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_summary_card.dart',
        'lib/features/tournament/presentation/operate/components/category_rules/category_rules_form_state.dart',
        'lib/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart',
        'lib/features/tournament/presentation/operate/components/category_rules/category_rule_renseikai_section.dart',
        'lib/features/tournament/presentation/operate/components/rules/sections/match_rule_time_section.dart',
        'lib/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart',
      ];

      for (final filePath in targetFiles) {
        final file = File(filePath);
        expect(file.existsSync(), isTrue, reason: '必須ファイルが存在しません: $filePath');
        final content = file.readAsStringSync();
        expect(
          content.contains('skipEmptyRoster') || content.contains('SkipEmpty'),
          isTrue,
          reason: '$filePath に skipEmptyRoster の対応が欠落しています',
        );
      }
    });

    test('BulkRuleStateHolderが全ルールを完全同期し再構築時に値が欠落しないこと', () {
      final holder = BulkRuleStateHolder();
      holder.applyCategoryRuleSet(
        comprehensiveRule,
        isTeam: true,
        sceneKey: 'renseikai',
      );

      expect(holder.matchTime, comprehensiveRule.matchTimeMinutes);
      expect(holder.isRunningTime, isTrue);
      expect(holder.isIpponShobu, isTrue);
      expect(holder.ipponLimit, 1);
      expect(holder.hansokuLimit, 1);
      expect(holder.hasHantei, isTrue);
      expect(holder.skipEmptyRoster, isTrue);
      expect(holder.renseikaiType, '時間制');
      expect(holder.overallTimeController.text, '45');

      final rebuilt = holder.buildNewRule();
      expect(rebuilt.skipEmptyRoster, isTrue);
      expect(rebuilt.isRunningTime, isTrue);
      expect(rebuilt.matchTimeMinutes, 4.5);
      expect(rebuilt.isIpponShobu, isTrue);
      expect(rebuilt.ipponLimit, 1);
      expect(rebuilt.hansokuLimit, 1);
      expect(rebuilt.hasHantei, isTrue);
      expect(rebuilt.renseikaiType, '時間制');
      expect(rebuilt.overallTimeMinutes, 45);
    });

    test('MatchEditStateHolderが既存ルールをロードした際に全項目を保持すること', () {
      final dummyMatch = MatchModel(
        id: 'test_match_001',
        matchType: 'team',
        rule: comprehensiveRule,
        redName: 'テスト道場A : 先鋒選手',
        whiteName: '対戦道場B : 相手選手',
        matchTimeMinutes: comprehensiveRule.matchTimeMinutes,
        hasExtension: false,
        hasHantei: true,
      );

      final holder = MatchEditStateHolder([dummyMatch]);

      expect(holder.matchTime, comprehensiveRule.matchTimeMinutes);
      expect(holder.isRunningTime, isTrue);
      expect(holder.isIpponShobu, isTrue);
      expect(holder.ipponLimit, 1);
      expect(holder.hansokuLimit, 1);
      expect(holder.hasHantei, isTrue);
      expect(holder.skipEmptyRoster, isTrue);
      expect(holder.renseikaiType, '時間制');
      expect(holder.overallTimeController.text, '45');
      expect(holder.isKachinuki, isTrue);
      expect(holder.isLeague, isTrue);
      expect(holder.winPoint, 5.0);

      // プリセット適用時も skipEmptyRoster が保持・同期されること
      holder.applyTargetPresetRule(comprehensiveRule, 'renseikai');
      expect(holder.skipEmptyRoster, isTrue);
      expect(holder.isRunningTime, isTrue);
    });

    test('MatchFormatFormStateがルール適用時に全項目を同期すること', () {
      final formState = MatchFormatFormState();
      final overallTimeController = TextEditingController();
      final winPointController = TextEditingController();
      final lossPointController = TextEditingController();
      final drawPointController = TextEditingController();

      formState.applyMatchRule(
        comprehensiveRule,
        overallTimeController: overallTimeController,
        winPointController: winPointController,
        lossPointController: lossPointController,
        drawPointController: drawPointController,
      );

      expect(formState.matchTime, comprehensiveRule.matchTimeMinutes);
      expect(formState.isRunningTime, isTrue);
      expect(formState.isIpponShobu, isTrue);
      expect(formState.ipponLimit, 1);
      expect(formState.hansokuLimit, 1);
      expect(formState.hasHantei, isTrue);
      expect(formState.skipEmptyRoster, isTrue);
      expect(formState.renseikaiType, '時間制');
      expect(overallTimeController.text, '45');
      expect(winPointController.text, '5.0');
    });

    test('CategoryRulesFormStateがルールセットのロードと再構築で項目を保持すること', () {
      final ruleSet = CategoryRuleSet(
        normalRule: comprehensiveRule.copyWith(skipEmptyRoster: false),
        advancedRule: comprehensiveRule.copyWith(skipEmptyRoster: true),
        renseikaiRule: comprehensiveRule.copyWith(skipEmptyRoster: true),
        useRenseikaiRule: true,
        useAdvancedRule: true,
        useHonsenRule: true,
      );

      final formState = CategoryRulesFormState();
      formState.populateFromRuleSet('中学生男子の部', ruleSet);

      expect(formState.renseikaiSkipEmpty, isTrue);

      final rebuiltSet = formState.buildCategoryRuleSet('中学生男子の部');

      expect(rebuiltSet.renseikaiRule.skipEmptyRoster, isTrue);
      expect(rebuiltSet.advancedRule.skipEmptyRoster, isTrue);
    });
  });
}
