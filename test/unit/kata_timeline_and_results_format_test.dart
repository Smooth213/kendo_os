import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_group_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';

void main() {
  group('[Unit] 剣道形 タイムライン・公式記録分類テスト', () {
    test(
      'TimelinePlayerMatchClassifier で対戦枠（groupName保有）の形競技がグループ対戦（sortedGroups）として分類されスワイプ削除可能になること',
      () {
        final kataMatch = MatchModel(
          id: 'kata_1',
          tournamentId: 't1',
          order: 1.0,
          matchType: '木刀による剣道基本技稽古法（5本）',
          status: 'pending',
          redName: '道上剣友会:皿田 脩人・塚本 大道',
          whiteName: '対戦相手:選手・選手',
          groupName: '道上剣友会 vs 対戦相手',
          rule: const MatchRule(isKataMatch: true),
        );

        final result = TimelinePlayerMatchClassifier.classifyTeamMatches(
          teamMatchesList: [kataMatch],
          teamName: '道上剣友会',
          sanitizedQuery: '',
          matchedMatchIds: {},
          matchedGroupNames: {},
          ownTeams: ['道上剣友会'],
        );

        // 対戦枠として sortedGroups に分類され、一括スワイプ削除が可能となる
        expect(result.sortedGroups.length, 1);
        expect(result.sortedGroups.first.key, '道上剣友会 vs 対戦相手');
        expect(result.sortedGroups.first.value.first.id, 'kata_1');
        expect(result.sortedPlayers.isEmpty, isTrue);
      },
    );

    test(
      'OfficialRecordGroupHelper で形競技の試合が個人戦グループ（__merged_individual__）に統合されること',
      () {
        final kataMatch = MatchModel(
          id: 'kata_2',
          tournamentId: 't1',
          order: 2.0,
          matchType: '日本剣道形',
          status: 'finished',
          redName: '道上剣友会:皿田 脩人・塚本 大道',
          whiteName: '対戦相手:選手・選手',
          groupName: '道上剣友会 vs 対戦相手',
          rule: const MatchRule(isKataMatch: true),
        );

        final groupsMap = {
          '道上剣友会 vs 対戦相手': [kataMatch],
        };

        final merged = OfficialRecordGroupHelper.mergeIndividualGroups(
          groupsMap,
        );

        expect(merged.containsKey('__merged_individual__'), isTrue);
        expect(merged['__merged_individual__']!.first.id, 'kata_2');
      },
    );

    test('TeamMatchCalculator で形競技の団体戦において本数差が存在しても勝数のみで判定され本数勝ちは発生しないこと', () {
      // 先鋒: 赤勝ち (3-0), 次鋒: 白勝ち (1-2), 中堅: 引き分け (0-0)
      // 勝数: 赤1勝, 白1勝 (勝数同数)
      // 旗数(本数): 赤4本 (3+1), 白2本 (0+2)
      // 形試合では「本数」は存在しないため、赤4対白2でも勝数同数なら引き分け判定となる
      final match1 = MatchModel(
        id: 'k_1',
        tournamentId: 't1',
        order: 1.0,
        matchType: '日本剣道形',
        status: 'finished',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 3,
        whiteScore: 0,
        rule: const MatchRule(isKataMatch: true),
      );
      final match2 = MatchModel(
        id: 'k_2',
        tournamentId: 't1',
        order: 2.0,
        matchType: '日本剣道形',
        status: 'finished',
        redName: '選手C',
        whiteName: '選手D',
        redScore: 1,
        whiteScore: 2,
        rule: const MatchRule(isKataMatch: true),
      );
      final match3 = MatchModel(
        id: 'k_3',
        tournamentId: 't1',
        order: 3.0,
        matchType: '日本剣道形',
        status: 'finished',
        redName: '選手E',
        whiteName: '選手F',
        redScore: 0,
        whiteScore: 0,
        rule: const MatchRule(isKataMatch: true),
      );

      final result = TeamMatchCalculator.calculate([match1, match2, match3]);
      expect(result.redWins, 1);
      expect(result.whiteWins, 1);
      expect(result.redPoints, 4);
      expect(result.whitePoints, 2);
      expect(result.isTie, isTrue);
      expect(result.teamWinner, 'draw');
    });
  });
}
