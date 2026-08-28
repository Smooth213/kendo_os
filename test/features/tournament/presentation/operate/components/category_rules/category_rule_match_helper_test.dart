import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('🥋 CategoryRuleMatchHelper 同一カテゴリ複数ルール共存・解決テスト要塞', () {
    late TournamentModel baseTournament;

    setUp(() {
      baseTournament = TournamentModel(
        id: 't1',
        organizationId: 'org1',
        name: '第50回 記念剣道大会',
        date: DateTime(2026, 8, 28),
        venue: '武道館',
      );
    });

    test('1. generateUniqueRuleKey: 同名部門でも種別サフィックスや番号で一意キーが生成されること', () {
      final existingRules = <String, CategoryRuleSet>{
        '小学生の部': const CategoryRuleSet(matchType: '団体戦'),
      };

      // 種別が個人戦の場合 -> '小学生の部（個人戦）'
      final key1 = CategoryRuleMatchHelper.generateUniqueRuleKey(
        existingRules,
        '小学生の部',
        matchType: '個人戦',
      );
      expect(key1, '小学生の部（個人戦）');

      // 既に '小学生の部（個人戦）' もある場合 -> '小学生の部 (2)'
      existingRules['小学生の部（個人戦）'] = const CategoryRuleSet(matchType: '個人戦');
      final key2 = CategoryRuleMatchHelper.generateUniqueRuleKey(
        existingRules,
        '小学生の部',
        matchType: '個人戦',
      );
      expect(key2, '小学生の部 (2)');
    });

    test(
      '2. addCategoryToTournament: 同一カテゴリを2回追加しても上書きされず、2つとも共存して登録されること',
      () {
        // 1回目: 小学生の部（団体戦）を追加
        final (t1, key1, _) = CategoryRuleMatchHelper.addCategoryToTournament(
          baseTournament,
          '小学生の部',
          matchType: '団体戦',
        );
        expect(key1, '小学生の部');
        expect(t1.categoryRules.length, 1);
        expect(t1.categoryRules.containsKey('小学生の部'), isTrue);

        // 2回目: 再び「小学生の部」を個人戦として追加
        final (t2, key2, _) = CategoryRuleMatchHelper.addCategoryToTournament(
          t1,
          '小学生の部',
          matchType: '個人戦',
        );
        expect(key2, '小学生の部（個人戦）');
        expect(t2.categoryRules.length, 2);
        expect(t2.categoryRules.containsKey('小学生の部'), isTrue);
        expect(t2.categoryRules.containsKey('小学生の部（個人戦）'), isTrue);
      },
    );

    test('3. findRuleSetForMatch: 試合の種別（団体戦/個人戦）に応じて最適なルールが自動解決されること', () {
      final teamRule = const CategoryRuleSet(
        normalRule: MatchRule(matchTimeMinutes: 3.0),
        matchType: '団体戦',
      );
      final indivRule = const CategoryRuleSet(
        normalRule: MatchRule(matchTimeMinutes: 2.0),
        matchType: '個人戦',
      );

      final rules = <String, CategoryRuleSet>{
        '小学生の部': teamRule,
        '小学生の部（個人戦）': indivRule,
      };

      // 団体戦の試合 -> teamRule (3分) が選ばれること
      final matchedTeam = CategoryRuleMatchHelper.findRuleSetForMatch(
        rules,
        category: '小学生の部',
        matchType: '先鋒',
      );
      expect(matchedTeam, isNotNull);
      expect(matchedTeam?.normalRule.matchTimeMinutes, 3.0);
      expect(matchedTeam?.matchType, '団体戦');

      // 個人戦の試合 -> indivRule (2分) が選ばれること
      final matchedIndiv = CategoryRuleMatchHelper.findRuleSetForMatch(
        rules,
        category: '小学生の部',
        matchType: '個人戦',
      );
      expect(matchedIndiv, isNotNull);
      expect(matchedIndiv?.normalRule.matchTimeMinutes, 2.0);
      expect(matchedIndiv?.matchType, '個人戦');
    });

    test('4. cleanCategoryBaseName: サフィックスを除いた基底部門名が正確に抽出されること', () {
      expect(CategoryRuleMatchHelper.cleanCategoryBaseName('小学生の部'), '小学生の部');
      expect(
        CategoryRuleMatchHelper.cleanCategoryBaseName('小学生の部（個人戦）'),
        '小学生の部',
      );
      expect(
        CategoryRuleMatchHelper.cleanCategoryBaseName('小学生の部(団体戦)'),
        '小学生の部',
      );
      expect(
        CategoryRuleMatchHelper.cleanCategoryBaseName('中学生の部 (2)'),
        '中学生の部',
      );
    });

    test(
      '5. updateTournamentWithRuleSet & deleteCategoryFromTournament: 特定ルールの更新・削除が独立して行われること',
      () {
        final (t1, _, _) = CategoryRuleMatchHelper.addCategoryToTournament(
          baseTournament,
          '小学生の部',
          matchType: '団体戦',
        );
        final (t2, _, _) = CategoryRuleMatchHelper.addCategoryToTournament(
          t1,
          '小学生の部',
          matchType: '個人戦',
        );

        expect(t2.categoryRules.length, 2);

        // 個人戦側のみ更新
        final updatedIndivRule = const CategoryRuleSet(
          normalRule: MatchRule(matchTimeMinutes: 2.5),
          matchType: '個人戦',
        );
        final t3 = CategoryRuleMatchHelper.updateTournamentWithRuleSet(
          tournament: t2,
          category: '小学生の部（個人戦）',
          ruleSet: updatedIndivRule,
        );

        expect(
          t3.categoryRules['小学生の部（個人戦）']?.normalRule.matchTimeMinutes,
          2.5,
        );
        expect(
          t3.categoryRules['小学生の部']?.normalRule.matchTimeMinutes,
          3.0,
        ); // 団体戦側は破壊されない！

        // 団体戦側を削除
        final t4 = CategoryRuleMatchHelper.deleteCategoryFromTournament(
          t3,
          '小学生の部',
        );
        expect(t4.categoryRules.length, 1);
        expect(t4.categoryRules.containsKey('小学生の部（個人戦）'), isTrue);
        expect(t4.categoryRules.containsKey('小学生の部'), isFalse);
      },
    );
  });
}
