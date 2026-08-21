import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_sync_helper.dart';

void main() {
  group('MatchFormatRuleSyncHelper Tests', () {
    test('isAdvancedMatchName checks note with keywords', () {
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

    test('determineInitialScene selects appropriate scene based on rules', () {
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

    test('getRuleForScene returns correct MatchRule', () {
      final renseikaiRule = MatchRule(matchTimeMinutes: 2.0);
      final normalRule = MatchRule(matchTimeMinutes: 3.0);
      final advancedRule = MatchRule(matchTimeMinutes: 4.0);

      final ruleSet = CategoryRuleSet(
        matchType: '団体戦',
        normalRule: normalRule,
        advancedRule: advancedRule,
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
