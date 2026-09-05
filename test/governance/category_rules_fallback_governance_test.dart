import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('🗂️ 【ガバナンス監査 17/18】CategoryRule 独立ルール設定フォールバック安全規約テスト', () {
    final defaultTournament = TournamentModel(
      id: 'tour_test_1',
      organizationId: 'dojo_1',
      name: '第1回 剛剣旗争奪全国大会',
      date: DateTime(2026, 9, 5),
      venue: '日本武道館',
      categories: const ['小学生の部', '中学生男子の部'],
      categoryRules: const {
        '小学生の部': CategoryRuleSet(
          normalRule: MatchRule(matchTimeMinutes: 2.0, hasHantei: true),
          advancedRule: MatchRule(matchTimeMinutes: 3.0, hasHantei: false),
          useAdvancedRule: true,
          matchType: '団体戦',
        ),
        '中学生男子の部': CategoryRuleSet(
          normalRule: MatchRule(matchTimeMinutes: 3.0, hasHantei: false),
          advancedRule: MatchRule(
            matchTimeMinutes: 4.0,
            isEnchoUnlimited: true,
          ),
          useAdvancedRule: true,
          matchType: '個人戦',
        ),
      },
    );

    test('1. 未設定・無効カテゴリフォールバック規約: 未知の部門でもクラッシュせず安全にフォールバックすること', () {
      // 存在しないカテゴリ
      final result1 = CategoryRuleMatchHelper.findRuleSetForMatch(
        defaultTournament.categoryRules,
        category: '高校生女子の部（未登録）',
        matchType: '団体戦',
      );
      expect(result1, isNull);

      // 空のルールマップ
      final result2 = CategoryRuleMatchHelper.findRuleSetForMatch(
        {},
        category: '小学生の部',
        matchType: '団体戦',
      );
      expect(result2, isNull);

      // ルール未発見時の安全なデフォルトMatchRule生成
      final fallbackRule = result1?.normalRule ?? const MatchRule();
      expect(fallbackRule.matchTimeMinutes, 3.0); // デフォルト3分
      expect(fallbackRule.isEnchoUnlimited, false);
    });

    test('2. 部門削除後の既存試合フォールバック規約: 部門削除後も試合モデルの整合性が保全されること', () {
      // '小学生の部' を削除
      final updatedTournament =
          CategoryRuleMatchHelper.deleteCategoryFromTournament(
            defaultTournament,
            '小学生の部',
          );
      expect(updatedTournament.categories.contains('小学生の部'), isFalse);
      expect(updatedTournament.categoryRules.containsKey('小学生の部'), isFalse);

      // 既存の試合（小学生の部）
      final existingMatch = const MatchModel(
        id: 'm_elem_1',
        matchType: '団体戦',
        redName: '先鋒A',
        whiteName: '先鋒B',
        tournamentId: 'tour_test_1',
        category: '小学生の部',
      );

      // 削除後のルール解決 ➔ null になるがクラッシュしない
      final resolvedRuleSet = CategoryRuleMatchHelper.findRuleSetForMatch(
        updatedTournament.categoryRules,
        category: existingMatch.category ?? '',
        matchType: existingMatch.matchType,
      );
      expect(resolvedRuleSet, isNull);

      // デフォルトルールが安全に適用可能であること
      final appliedRule = resolvedRuleSet?.normalRule ?? const MatchRule();
      expect(appliedRule, isNotNull);
    });

    test('3. 延長方式・ルール変更整合性規約: 延長無制限 ↔ 有制限切り替えが安全に行えること', () {
      const normalRule = MatchRule(
        matchTimeMinutes: 3.0,
        hasHantei: false,
        isEnchoUnlimited: false,
        enchoCount: 1,
      );

      // 延長無制限ルール
      final unlimitedRule = normalRule.copyWith(
        isEnchoUnlimited: true,
        enchoCount: 0,
      );

      expect(unlimitedRule.isEnchoUnlimited, isTrue);
      expect(unlimitedRule.enchoCount, 0);

      // 判定ありルール
      final hanteiRule = normalRule.copyWith(
        hasHantei: true,
        isEnchoUnlimited: false,
        enchoCount: 0,
      );

      expect(hanteiRule.hasHantei, isTrue);
      expect(hanteiRule.isEnchoUnlimited, isFalse);
    });

    test('4. 上位戦スマート判定規約: 準決勝・決勝等のキーワードで特別ルールが的確に選択されること', () {
      final ruleSet = defaultTournament.categoryRules['小学生の部']!;
      expect(ruleSet.useAdvancedRule, isTrue);

      // 通常戦
      final isNormalRound = CategoryRuleMatchHelper.isAdvancedMatchName(
        '1回戦 第1試合',
      );
      expect(isNormalRound, isFalse);
      final activeRule1 = isNormalRound
          ? ruleSet.advancedRule
          : ruleSet.normalRule;
      expect(activeRule1.matchTimeMinutes, 2.0);

      // 決勝戦
      final isFinalRound = CategoryRuleMatchHelper.isAdvancedMatchName('決勝戦');
      expect(isFinalRound, isTrue);
      final activeRule2 = isFinalRound
          ? ruleSet.advancedRule
          : ruleSet.normalRule;
      expect(activeRule2.matchTimeMinutes, 3.0);

      // 準決勝（短縮表記「準決」）
      final isSemisRound = CategoryRuleMatchHelper.isAdvancedMatchName(
        '第1コート 準決',
      );
      expect(isSemisRound, isTrue);
    });
  });
}
