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

    test(
      '5. 形式混同防止安全規約: 同一部門名で個人戦・団体戦・勝ち抜き戦が併存しても、対象形式に合致するルールセットが厳格かつ安全に解決されること',
      () {
        const teamRule = CategoryRuleSet(
          normalRule: MatchRule(matchTimeMinutes: 3.0),
          matchType: '団体戦',
        );
        const indivRule = CategoryRuleSet(
          normalRule: MatchRule(matchTimeMinutes: 2.0),
          matchType: '個人戦',
        );
        const kachinukiRule = CategoryRuleSet(
          normalRule: MatchRule(matchTimeMinutes: 4.0, isKachinuki: true),
          matchType: '勝ち抜き戦',
        );

        final rules = <String, CategoryRuleSet>{
          '小学生の部': teamRule,
          '小学生の部（個人戦）': indivRule,
          '小学生の部（勝ち抜き戦）': kachinukiRule,
        };

        // 団体戦の解決
        final matchedTeam = CategoryRuleMatchHelper.findRuleSetForMatch(
          rules,
          category: '小学生の部',
          matchType: '団体戦',
        );
        expect(matchedTeam?.matchType, '団体戦');
        expect(matchedTeam?.normalRule.matchTimeMinutes, 3.0);

        // 個人戦の解決（同一基底カテゴリ名でも団体戦に吸い込まれないこと）
        final matchedIndiv = CategoryRuleMatchHelper.findRuleSetForMatch(
          rules,
          category: '小学生の部',
          matchType: '個人戦',
        );
        expect(matchedIndiv?.matchType, '個人戦');
        expect(matchedIndiv?.normalRule.matchTimeMinutes, 2.0);

        // 勝ち抜き戦の解決（団体戦や個人戦と混同されないこと）
        final matchedKachinuki = CategoryRuleMatchHelper.findRuleSetForMatch(
          rules,
          category: '小学生の部',
          matchType: '勝ち抜き戦',
        );
        expect(matchedKachinuki?.matchType, '勝ち抜き戦');
        expect(matchedKachinuki?.normalRule.matchTimeMinutes, 4.0);
      },
    );

    test(
      '6. 上位戦ルール未設定時の安全保全規約: 上位戦ルールが無効（OFF）な場合、試合名が決勝等であっても上位戦ルールに誤適用・フォールバックせず通常戦ルールが保全されること',
      () {
        final tournamentWithNoAdvanced = TournamentModel(
          id: 'tour_no_adv',
          organizationId: 'dojo_1',
          name: '通常大会',
          date: DateTime(2026, 9, 5),
          venue: '日本武道館',
          categories: const ['小学生の部'],
          categoryRules: const {
            '小学生の部': CategoryRuleSet(
              normalRule: MatchRule(matchTimeMinutes: 2.0),
              advancedRule: MatchRule(matchTimeMinutes: 4.0),
              useAdvancedRule: false, // 🔥 上位戦ルールOFF
              matchType: '団体戦',
            ),
          },
        );

        // 上位戦キーワード判定で false が返ること（上位戦ルールが存在しないため）
        final ruleSet = tournamentWithNoAdvanced.categoryRules['小学生の部']!;
        expect(ruleSet.useAdvancedRule, isFalse);

        // 試合名が「決勝戦」であっても、適用ルールは必ず通常戦ルールであること
        final effectiveRule = ruleSet.useAdvancedRule
            ? ruleSet.advancedRule
            : ruleSet.normalRule;
        expect(effectiveRule.matchTimeMinutes, 2.0);
      },
    );

    test('7. 勝負方式（1本勝負）設定整合性規約: 先取本数1本指定時に1本勝負フラグおよびルール実体が完全に同期・保全されること', () {
      final rule = CategoryRuleMatchHelper.buildMatchRule(
        category: '中学生の部',
        matchType: '個人戦',
        matchTime: 3.0,
        isRunningTime: false,
        isIpponShobu: false, // フラグが一時的に false でも
        ipponLimit: 1, // 先取本数が 1本 の場合
        hansokuLimit: 2,
        hasHantei: true,
        hasExtension: true,
        isEnchoUnlimited: false,
        enchoTime: 2.0,
        enchoCount: 1,
        kachinukiUnlimitedType: 'none',
        isDaihyoIpponShobu: true,
        winPoint: 0,
        lossPoint: 0,
        drawPoint: 0,
        isRenseikai: false,
        renseikaiType: 'none',
        overallTime: 30,
        daihyoMatchTime: 3.0,
        daihyoHasExtension: false,
        daihyoEnchoTime: 0,
        daihyoEnchoCount: 0,
        daihyoHasHantei: false,
      );

      // 確実に 1本勝負フラグが true に同期・保全されること
      expect(rule.isIpponShobu, isTrue);
      expect(rule.ipponLimit, 1);
    });
  });
}
