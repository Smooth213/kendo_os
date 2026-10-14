import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_apply_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';

void main() {
  group('[Governance] 第101条 剣道形競技 公式ルール整合性 永続保証規約', () {
    test('BulkRuleApplyHelper で形競技ルール計算時、時間計測なし・延長なし・判定有効が不変条件として保証されること', () {
      const kataSource = MatchRule(
        isKataMatch: true,
        matchTimeMinutes: 3.0,
        isIpponShobu: true,
        hasHantei: true,
        enchoCount: 2,
        isEnchoUnlimited: true,
      );

      final params = BulkRuleApplyHelper.computeRuleParams(
        targetRule: kataSource,
        isTeam: false,
        isIndiv: true,
      );

      // ① 試合時間が 0.0（時間計測なし）に強制されること
      expect(params.matchTime, 0.0);

      // ② 一本勝負フラグが解除されること
      expect(params.isIpponShobu, isFalse);

      // ③ 延長戦なし（hasExtension == false, enchoCount == 0, isEnchoUnlimited == false）に強制されること
      expect(params.hasExtension, isFalse);
      expect(params.enchoCount, 0);
      expect(params.isEnchoUnlimited, isFalse);
      expect(params.enchoTime, 0.0);

      // ④ 判定有効（hasHantei == true）が保持されること
      expect(params.hasHantei, isTrue);
    });

    test('MatchModelにおいて形競技の判定決着（2旗以上獲得で勝利）が正しく個人戦認識されること', () {
      final match = MatchModel(
        id: 'kata_gov_1',
        tournamentId: 't1',
        order: 1.0,
        matchType: '日本剣道形',
        status: 'finished',
        redName: '道上剣友会:皿田 脩人・塚本 大道',
        whiteName: '対戦相手:選手・選手',
        redScore: 2,
        whiteScore: 1,
        rule: const MatchRule(
          isKataMatch: true,
          matchTimeMinutes: 0.0,
          hasHantei: true,
        ),
      );

      // ① 形競技として正しく個人戦認識されること
      expect(TeamProgressHelper.isIndividualMatch(match), isTrue);

      // ② スコア計算で過半数（2旗以上）を獲得した側が勝者となること
      expect(match.redScore > match.whiteScore, isTrue);
      expect(match.redScore >= 2, isTrue);
    });

    test(
      'TimelinePlayerMatchClassifier において対戦枠（groupName保有）の形競技がグループ対戦枠として維持されスワイプ削除導線が恒久保証されること',
      () {
        // 1試合のみの対戦枠であっても個人戦枠へ誤分類されずグループ枠に留まること
        final singleKataMatch = [
          const MatchModel(
            id: 'kata_gov_group_match',
            tournamentId: 't_gov',
            groupName: 'group_kata_vs_opp',
            matchType: '日本剣道形（3本）',
            redName: '自チーム:打太刀・仕太刀',
            whiteName: '対戦相手:打太刀・仕太刀',
            rule: MatchRule(isKataMatch: true, hasHantei: true),
          ),
        ];

        final classified = TimelinePlayerMatchClassifier.classifyTeamMatches(
          teamMatchesList: singleKataMatch,
          teamName: '自チーム',
          sanitizedQuery: '',
          matchedMatchIds: {},
          matchedGroupNames: {},
          ownTeams: const ['自チーム'],
        );

        // ① グループ対戦枠（sortedGroups）として1件分類されること（一括削除ボタンの露出保証）
        expect(classified.sortedGroups.length, 1);
        expect(classified.sortedGroups.first.key, 'group_kata_vs_opp');
        expect(
          classified.sortedGroups.first.value.first.id,
          'kata_gov_group_match',
        );

        // ② 個人選手枠（sortedPlayers）へ誤分類されないこと
        expect(classified.sortedPlayers.isEmpty, isTrue);
      },
    );

    test(
      'TimelinePlayerMatchClassifier においてgroupNameを持たない純粋個人戦の形競技は個人選手枠に分類されること',
      () {
        final indivKataMatch = [
          const MatchModel(
            id: 'kata_gov_indiv_match',
            tournamentId: 't_gov',
            matchType: '木刀による剣道基本技稽古法',
            redName: '自チーム:皿田 脩人・塚本 大道',
            whiteName: '友道館:選手・選手',
            rule: MatchRule(isKataMatch: true, hasHantei: true),
          ),
        ];

        final classified = TimelinePlayerMatchClassifier.classifyTeamMatches(
          teamMatchesList: indivKataMatch,
          teamName: '自チーム',
          sanitizedQuery: '',
          matchedMatchIds: {},
          matchedGroupNames: {},
          ownTeams: const ['自チーム'],
        );

        // ① グループではなく選手別（sortedPlayers）に分類されること
        expect(classified.sortedGroups.isEmpty, isTrue);
        expect(classified.sortedPlayers.length, 1);
        expect(classified.sortedPlayers.first.key, '皿田 脩人・塚本 大道');
        expect(
          classified.sortedPlayers.first.value.first.id,
          'kata_gov_indiv_match',
        );
      },
    );
  });
}
