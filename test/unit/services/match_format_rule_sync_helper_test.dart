import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_sync_helper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('[Unit] MatchFormatRuleSyncHelper 単体テスト', () {
    test('isAdvancedMatchNameにおいて 備考のキーワード判定が正常動作すること', () {
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

    test('determineInitialSceneにおいて ルール設定に応じた適切なシーンが選択されること', () {
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
    });

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
            useAdvancedRule: false,
          ),
        },
      );

      final isAdv = MatchFormatRuleSyncHelper.isAdvancedMatchName(
        note: '決勝戦',
        categoryName: '小学生の部',
        tournament: tourney,
      );
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
