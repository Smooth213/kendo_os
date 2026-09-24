import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_lookup_helper.dart';

void main() {
  group('CategoryRuleLookupHelper Tests', () {
    test('cleanCategoryBaseName: 種別サフィックスや数字サフィックスを除去できること', () {
      expect(
        CategoryRuleLookupHelper.cleanCategoryBaseName('小学生の部（個人戦）'),
        '小学生の部',
      );
      expect(
        CategoryRuleLookupHelper.cleanCategoryBaseName('小学生の部（勝ち抜き戦）'),
        '小学生の部',
      );
      expect(
        CategoryRuleLookupHelper.cleanCategoryBaseName('中学生男子 (2)'),
        '中学生男子',
      );
      expect(CategoryRuleLookupHelper.cleanCategoryBaseName('一般の部'), '一般の部');
    });

    test('findRuleSetForMatch: 団体戦・個人戦・勝ち抜き戦に応じたルールセット解決', () {
      final teamRule = const CategoryRuleSet(
        normalRule: MatchRule(matchTimeMinutes: 3.0),
        matchType: '団体戦',
      );
      final indivRule = const CategoryRuleSet(
        normalRule: MatchRule(matchTimeMinutes: 2.0),
        matchType: '個人戦',
      );
      final kachinukiRule = const CategoryRuleSet(
        normalRule: MatchRule(matchTimeMinutes: 4.0, isKachinuki: true),
        matchType: '勝ち抜き戦',
      );

      final rules = <String, CategoryRuleSet>{
        '小学生の部': teamRule,
        '小学生の部（個人戦）': indivRule,
        '小学生の部（勝ち抜き戦）': kachinukiRule,
      };

      final matchedTeam = CategoryRuleLookupHelper.findRuleSetForMatch(
        rules,
        category: '小学生の部',
        matchType: '団体戦',
      );
      expect(matchedTeam?.normalRule.matchTimeMinutes, 3.0);
      expect(matchedTeam?.matchType, '団体戦');

      final matchedIndiv = CategoryRuleLookupHelper.findRuleSetForMatch(
        rules,
        category: '小学生の部',
        matchType: '個人戦',
      );
      expect(matchedIndiv?.normalRule.matchTimeMinutes, 2.0);
      expect(matchedIndiv?.matchType, '個人戦');

      final matchedKachinuki = CategoryRuleLookupHelper.findRuleSetForMatch(
        rules,
        category: '小学生の部',
        matchType: '勝ち抜き戦',
      );
      expect(matchedKachinuki?.normalRule.matchTimeMinutes, 4.0);
      expect(matchedKachinuki?.matchType, '勝ち抜き戦');
    });

    test('findRuleEntryForMatch: note のサブタイトルやキーワードから適切なエントリを解決', () {
      final prelimRule = const CategoryRuleSet(
        subtitle: '予選リーグ',
        normalRule: MatchRule(matchTimeMinutes: 2.0),
      );
      final finalRule = const CategoryRuleSet(
        subtitle: '決勝トーナメント',
        normalRule: MatchRule(matchTimeMinutes: 3.0),
      );

      final rules = <String, CategoryRuleSet>{
        '中学生の部 (予選)': prelimRule,
        '中学生の部 (決勝)': finalRule,
      };

      final entry = CategoryRuleLookupHelper.findRuleEntryForMatch(
        rules,
        category: '中学生の部',
        matchType: '団体戦',
        note: '第1コート 決勝トーナメント 第1試合',
      );
      expect(entry?.value.subtitle, '決勝トーナメント');
      expect(entry?.value.normalRule.matchTimeMinutes, 3.0);
    });
  });
}
