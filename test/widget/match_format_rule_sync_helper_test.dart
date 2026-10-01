import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_sync_helper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('[Widget] MatchFormatRuleSyncHelper テスト', () {
    test('isAdvancedMatchName checks note with keywordsこと', () {
      final isAdv = MatchFormatRuleSyncHelper.isAdvancedMatchName(
        note: '決勝戦',
        categoryName: '小学生の部',
        tournament: null,
      );
      expect(isAdv, isTrue);

      final isNormal = MatchFormatRuleSyncHelper.isAdvancedMatchName(
        note: '1回戦',
        categoryName: '小学生の部',
        tournament: null,
      );
      expect(isNormal, isFalse);
    });

    test(
      'determineInitialScene selects appropriate scene based on rulesこと',
      () {
        final ruleSet = CategoryRuleSet(
          matchType: '団体戦',
          normalRule: MatchRule(),
          advancedRule: MatchRule(),
          useAdvancedRule: true,
          useHonsenRule: true,
        );

        final sceneAdv = MatchFormatRuleSyncHelper.determineInitialScene(
          ruleSet: ruleSet,
          currentScene: 'honsen',
          isAdvanced: true,
        );
        expect(sceneAdv, 'advanced');

        final sceneNormal = MatchFormatRuleSyncHelper.determineInitialScene(
          ruleSet: ruleSet,
          currentScene: 'honsen',
          isAdvanced: false,
        );
        expect(sceneNormal, 'honsen');
      },
    );

    test('詳細ルール無効時は詳細試合名判定がfalseを返すこと', () {
      final tourney = TournamentModel(
        id: 't1',
        organizationId: 'org1',
        name: '大会',
        date: DateTime.now(),
        venue: '道場',
        categories: ['小学生の部'],
        categoryRules: {
          '小学生の部': const CategoryRuleSet(
            matchType: '団体戦',
            normalRule: MatchRule(matchTimeMinutes: 3.0),
            advancedRule: MatchRule(matchTimeMinutes: 4.0),
            useAdvancedRule: false, // 上位戦ルールOFF
          ),
        },
      );

      final isAdv = MatchFormatRuleSyncHelper.isAdvancedMatchName(
        note: '決勝戦',
        categoryName: '小学生の部',
        tournament: tourney,
      );
      // 🔥 上位戦ルールが無効なため、決勝戦と書いてあっても上位戦判定にならないこと
      expect(isAdv, isFalse);
    });

    test('詳細ルール無効時は通常ルールが返却されること', () {
      final normalRule = MatchRule(matchTimeMinutes: 3.0);
      final advancedRule = MatchRule(matchTimeMinutes: 4.0);

      final ruleSet = CategoryRuleSet(
        matchType: '団体戦',
        normalRule: normalRule,
        advancedRule: advancedRule,
        useAdvancedRule: false,
      );

      // 上位戦ルール無効時は advanced を指定しても normalRule にフォールバック
      expect(
        MatchFormatRuleSyncHelper.getRuleForScene(
          scene: 'advanced',
          ruleSet: ruleSet,
        ).matchTimeMinutes,
        3.0,
      );
    });

    test('シーンに応じた正しいMatchRuleが返却されること', () {
      final renseikaiRule = MatchRule(matchTimeMinutes: 2.0);
      final normalRule = MatchRule(matchTimeMinutes: 3.0);
      final advancedRule = MatchRule(matchTimeMinutes: 4.0);

      final ruleSet = CategoryRuleSet(
        matchType: '団体戦',
        normalRule: normalRule,
        advancedRule: advancedRule,
        useAdvancedRule: true,
        renseikaiRule: renseikaiRule,
      );

      expect(
        MatchFormatRuleSyncHelper.getRuleForScene(
          scene: 'renseikai',
          ruleSet: ruleSet,
        ).matchTimeMinutes,
        2.0,
      );
      expect(
        MatchFormatRuleSyncHelper.getRuleForScene(
          scene: 'advanced',
          ruleSet: ruleSet,
        ).matchTimeMinutes,
        4.0,
      );
    });
  });
}
