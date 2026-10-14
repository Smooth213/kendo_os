import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_lookup_helper.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('[Unit] チーム登録からルール自動割り当てへの結合検証', () {
    late TournamentModel tournament;

    setUp(() {
      // 大会の部門ルール設定（6分類のルールを準備）
      final categoryRules = <String, CategoryRuleSet>{
        '小学生低学年の部（個人戦）': const CategoryRuleSet(
          matchType: '個人戦',
          normalRule: MatchRule(matchTimeMinutes: 2.0, enchoTimeMinutes: 2.0),
        ),
        '小学生低学年の部（団体戦）': const CategoryRuleSet(
          matchType: '団体戦',
          normalRule: MatchRule(matchTimeMinutes: 3.0),
        ),
        '小学生低学年の部（リーグ個人戦）': const CategoryRuleSet(
          matchType: 'リーグ個人戦',
          normalRule: MatchRule(
            matchTimeMinutes: 2.5,
            isLeague: true,
            hasHantei: true,
          ),
        ),
        '小学生低学年の部（リーグ団体戦）': const CategoryRuleSet(
          matchType: 'リーグ団体戦',
          normalRule: MatchRule(
            matchTimeMinutes: 3.0,
            isLeague: true,
            hasLeagueDaihyo: true,
          ),
        ),
        '小学生低学年の部（勝ち抜き戦）': const CategoryRuleSet(
          matchType: '勝ち抜き戦',
          normalRule: MatchRule(
            matchTimeMinutes: 4.0,
            isKachinuki: true,
            isEnchoUnlimited: true,
          ),
        ),
        '小学生低学年の部（剣道形）': const CategoryRuleSet(
          matchType: '剣道形',
          normalRule: MatchRule(
            matchTimeMinutes: 0.0,
            isKataMatch: true,
            hasHantei: true,
          ),
        ),
      };

      tournament = TournamentModel(
        id: 'tourney_test_1',
        organizationId: 'org_test',
        name: 'テスト大会',
        venue: 'テスト会場',
        date: DateTime(2026, 10, 14),
        categoryRules: categoryRules,
      );
    });

    test('チーム登録で「勝ち抜き戦（3人制）」を選んだ場合、勝ち抜き戦ルールが100%自動適用されること', () {
      final team = const TeamModel(
        id: 'team_kachinuki_3',
        tournamentId: 'tourney_test_1',
        category: '小学生低学年の部',
        teamName: '勇武館 A',
        matchType: '勝ち抜き戦（3人制）',
        playerNames: ['先鋒選手', '中堅選手', '大将選手'],
      );

      final ruleSet = CategoryRuleLookupHelper.findRuleSetForMatch(
        tournament.categoryRules,
        category: team.category,
        matchType: team.matchType,
      );

      expect(ruleSet, isNotNull);
      expect(ruleSet!.matchType, '勝ち抜き戦');
      expect(ruleSet.normalRule.isKachinuki, isTrue);
      expect(ruleSet.normalRule.matchTimeMinutes, 4.0);
      expect(ruleSet.normalRule.isEnchoUnlimited, isTrue);
    });

    test('チーム登録で「勝ち抜き戦（5人制）」を選んだ場合も、同様に勝ち抜き戦ルールが自動適用されること', () {
      final team = const TeamModel(
        id: 'team_kachinuki_5',
        tournamentId: 'tourney_test_1',
        category: '小学生低学年の部',
        teamName: '勇武館 B',
        matchType: '勝ち抜き戦（5人制）',
        playerNames: ['選手1', '選手2', '選手3', '選手4', '選手5'],
      );

      final ruleSet = CategoryRuleLookupHelper.findRuleSetForMatch(
        tournament.categoryRules,
        category: team.category,
        matchType: team.matchType,
      );

      expect(ruleSet, isNotNull);
      expect(ruleSet!.matchType, '勝ち抜き戦');
      expect(ruleSet.normalRule.isKachinuki, isTrue);
      expect(ruleSet.normalRule.matchTimeMinutes, 4.0);
    });

    test('チーム登録で「団体戦（5人制）」を選んだ場合、通常の団体戦ルールが適用されること', () {
      final team = const TeamModel(
        id: 'team_dantai_5',
        tournamentId: 'tourney_test_1',
        category: '小学生低学年の部',
        teamName: '勇武館 C',
        matchType: '団体戦（5人制）',
        playerNames: ['選手1', '選手2', '選手3', '選手4', '選手5'],
      );

      final ruleSet = CategoryRuleLookupHelper.findRuleSetForMatch(
        tournament.categoryRules,
        category: team.category,
        matchType: team.matchType,
      );

      expect(ruleSet, isNotNull);
      expect(ruleSet!.matchType, '団体戦');
      expect(ruleSet.normalRule.isKachinuki, isFalse);
      expect(ruleSet.normalRule.matchTimeMinutes, 3.0);
    });

    test('チーム登録で「リーグ個人戦」を選んだ場合、リーグ個人戦ルールが適用されること', () {
      final team = const TeamModel(
        id: 'team_league_indiv',
        tournamentId: 'tourney_test_1',
        category: '小学生低学年の部',
        teamName: '個人選手A',
        matchType: 'リーグ個人戦',
        playerNames: ['個人選手A'],
      );

      final ruleSet = CategoryRuleLookupHelper.findRuleSetForMatch(
        tournament.categoryRules,
        category: team.category,
        matchType: team.matchType,
      );

      expect(ruleSet, isNotNull);
      expect(ruleSet!.matchType, 'リーグ個人戦');
      expect(ruleSet.normalRule.isLeague, isTrue);
      expect(ruleSet.normalRule.matchTimeMinutes, 2.5);
    });

    test('チーム登録で「リーグ団体戦（3人制）」を選んだ場合、リーグ団体戦ルールが適用されること', () {
      final team = const TeamModel(
        id: 'team_league_team',
        tournamentId: 'tourney_test_1',
        category: '小学生低学年の部',
        teamName: '勇武館 リーグ組',
        matchType: 'リーグ団体戦（3人制）',
        playerNames: ['先鋒', '中堅', '大将'],
      );

      final ruleSet = CategoryRuleLookupHelper.findRuleSetForMatch(
        tournament.categoryRules,
        category: team.category,
        matchType: team.matchType,
      );

      expect(ruleSet, isNotNull);
      expect(ruleSet!.matchType, 'リーグ団体戦');
      expect(ruleSet.normalRule.isLeague, isTrue);
      expect(ruleSet.normalRule.hasLeagueDaihyo, isTrue);
    });

    test('チーム登録で「日本剣道形（太刀の形3本）」を選んだ場合、剣道形ルールが100%自動適用されること', () {
      final team = const TeamModel(
        id: 'team_kata',
        tournamentId: 'tourney_test_1',
        category: '小学生低学年の部',
        teamName: '形ペア A',
        matchType: '日本剣道形（太刀の形3本）',
        playerNames: ['打太刀選手', '仕太刀選手'],
      );

      final ruleSet = CategoryRuleLookupHelper.findRuleSetForMatch(
        tournament.categoryRules,
        category: team.category,
        matchType: team.matchType,
      );

      expect(ruleSet, isNotNull);
      expect(ruleSet!.matchType, '剣道形');
      expect(ruleSet.normalRule.isKataMatch, isTrue);
      expect(ruleSet.normalRule.hasHantei, isTrue);
    });

    test('試合メモ欄に「決勝トーナメント」と書かれていても、チーム種別が優先され勝ち抜き戦ルールが誤判定されないこと', () {
      final team = const TeamModel(
        id: 'team_kachinuki_final',
        tournamentId: 'tourney_test_1',
        category: '小学生低学年の部',
        teamName: '勇武館 決勝進出組',
        matchType: '勝ち抜き戦（3人制）',
        playerNames: ['選手1', '選手2', '選手3'],
      );

      // note に団体戦を連想させる「決勝トーナメント」が含まれている状況
      final ruleSet = CategoryRuleLookupHelper.findRuleSetForMatch(
        tournament.categoryRules,
        category: team.category,
        matchType: team.matchType,
        note: '第1コート 決勝トーナメント 第1試合',
      );

      // チームの勝ち抜き戦が最優先され、勝ち抜き戦ルールが確実に返ること
      expect(ruleSet, isNotNull);
      expect(ruleSet!.matchType, '勝ち抜き戦');
      expect(ruleSet.normalRule.isKachinuki, isTrue);
    });
  });
}
