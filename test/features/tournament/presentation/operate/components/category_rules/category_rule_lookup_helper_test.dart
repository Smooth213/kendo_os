import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_lookup_helper.dart';

void main() {
  group('[Widget] CategoryRuleLookupHelper テスト', () {
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

    test('findRuleSetForMatch: 団体戦・個人戦・勝ち抜き戦に応じたルールセット解決こと', () {
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

    test('findRuleEntryForMatch: note のサブタイトルやキーワードから適切なエントリを解決こと', () {
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

    test('normalizeMatchType: 6分類および人数・形の本数表記を正しく正規化できること', () {
      expect(
        CategoryRuleLookupHelper.normalizeMatchType('勝ち抜き戦（3人制）'),
        '勝ち抜き戦',
      );
      expect(
        CategoryRuleLookupHelper.normalizeMatchType('勝ち抜き戦（5人制）'),
        '勝ち抜き戦',
      );
      expect(
        CategoryRuleLookupHelper.normalizeMatchType('勝ち抜き戦（7人制）'),
        '勝ち抜き戦',
      );
      expect(CategoryRuleLookupHelper.normalizeMatchType('団体戦（5人制）'), '団体戦');
      expect(CategoryRuleLookupHelper.normalizeMatchType('団体戦（3人制）'), '団体戦');
      expect(
        CategoryRuleLookupHelper.normalizeMatchType('リーグ団体戦（5人制）'),
        'リーグ団体戦',
      );
      expect(CategoryRuleLookupHelper.normalizeMatchType('リーグ個人戦'), 'リーグ個人戦');
      expect(
        CategoryRuleLookupHelper.normalizeMatchType('日本剣道形（太刀の形3本）'),
        '剣道形',
      );
      expect(
        CategoryRuleLookupHelper.normalizeMatchType('木刀による剣道基本技稽古法（5本）'),
        '剣道形',
      );
      expect(CategoryRuleLookupHelper.normalizeMatchType('個人戦'), '個人戦');
    });

    test('findRuleSetForMatch: 6分類（勝ち抜き3人制/5人制、リーグ個人/団体、剣道形等）で正確に解決できること', () {
      final kachinukiRule = const CategoryRuleSet(
        normalRule: MatchRule(matchTimeMinutes: 4.0, isKachinuki: true),
        matchType: '勝ち抜き戦',
      );
      final leagueIndivRule = const CategoryRuleSet(
        normalRule: MatchRule(matchTimeMinutes: 2.0, isLeague: true),
        matchType: 'リーグ個人戦',
      );
      final leagueTeamRule = const CategoryRuleSet(
        normalRule: MatchRule(matchTimeMinutes: 3.0, isLeague: true),
        matchType: 'リーグ団体戦',
      );
      final kataRule = const CategoryRuleSet(
        normalRule: MatchRule(matchTimeMinutes: 0.0, isKataMatch: true),
        matchType: '剣道形',
      );
      final teamRule = const CategoryRuleSet(
        normalRule: MatchRule(matchTimeMinutes: 3.5),
        matchType: '団体戦',
      );

      final rules = <String, CategoryRuleSet>{
        '小学生の部（勝ち抜き戦）': kachinukiRule,
        '小学生の部（リーグ個人戦）': leagueIndivRule,
        '小学生の部（リーグ団体戦）': leagueTeamRule,
        '小学生の部（剣道形）': kataRule,
        '小学生の部（団体戦）': teamRule,
      };

      // 勝ち抜き戦（3人制でも5人制でも「勝ち抜き戦」ルールが返る）
      final matchedKachinuki3 = CategoryRuleLookupHelper.findRuleSetForMatch(
        rules,
        category: '小学生の部',
        matchType: '勝ち抜き戦（3人制）',
      );
      expect(matchedKachinuki3?.matchType, '勝ち抜き戦');
      expect(matchedKachinuki3?.normalRule.matchTimeMinutes, 4.0);

      final matchedKachinuki5 = CategoryRuleLookupHelper.findRuleSetForMatch(
        rules,
        category: '小学生の部',
        matchType: '勝ち抜き戦（5人制）',
      );
      expect(matchedKachinuki5?.matchType, '勝ち抜き戦');
      expect(matchedKachinuki5?.normalRule.matchTimeMinutes, 4.0);

      // リーグ個人戦とリーグ団体戦が明確に区別されて解決する
      final matchedLeagueIndiv = CategoryRuleLookupHelper.findRuleSetForMatch(
        rules,
        category: '小学生の部',
        matchType: 'リーグ個人戦',
      );
      expect(matchedLeagueIndiv?.matchType, 'リーグ個人戦');
      expect(matchedLeagueIndiv?.normalRule.matchTimeMinutes, 2.0);

      final matchedLeagueTeam = CategoryRuleLookupHelper.findRuleSetForMatch(
        rules,
        category: '小学生の部',
        matchType: 'リーグ団体戦（5人制）',
      );
      expect(matchedLeagueTeam?.matchType, 'リーグ団体戦');
      expect(matchedLeagueTeam?.normalRule.matchTimeMinutes, 3.0);

      // 剣道形（日本剣道形でも基本技稽古法でも「剣道形」ルールが返る）
      final matchedKata1 = CategoryRuleLookupHelper.findRuleSetForMatch(
        rules,
        category: '小学生の部',
        matchType: '日本剣道形（太刀の形3本）',
      );
      expect(matchedKata1?.matchType, '剣道形');
      expect(matchedKata1?.normalRule.isKataMatch, true);

      final matchedKata2 = CategoryRuleLookupHelper.findRuleSetForMatch(
        rules,
        category: '小学生の部',
        matchType: '木刀による剣道基本技稽古法（5本）',
      );
      expect(matchedKata2?.matchType, '剣道形');
      expect(matchedKata2?.normalRule.isKataMatch, true);
    });
  });
}
