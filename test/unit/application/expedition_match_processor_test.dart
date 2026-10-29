import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_team_match_processor.dart';

void main() {
  group('[Unit] 遠征試合プロセッサ 単体テスト', () {
    test('団体戦勝敗4分岐において 勝数・本数差・代表戦・引分が正確に判定されること', () {
      // 1. 勝数勝ち (2勝 vs 1勝)
      final cardResults1 = <ExpeditionCardResult>[];
      final group1Matches = [
        const MatchModel(
          id: 'm1-senpo',
          matchType: '先鋒',
          redName: '自チーム:選手A',
          whiteName: '相手チーム:選手X',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
        ),
        const MatchModel(
          id: 'm1-jiho',
          matchType: '次鋒',
          redName: '自チーム:選手B',
          whiteName: '相手チーム:選手Y',
          redScore: 0,
          whiteScore: 1,
          status: 'finished',
        ),
        const MatchModel(
          id: 'm1-taisho',
          matchType: '大将',
          redName: '自チーム:選手C',
          whiteName: '相手チーム:選手Z',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
      ];

      ExpeditionTeamMatchProcessor.processTeamMatches(
        groupMap: {'g1': group1Matches},
        selectedSummaryTeam: '全体',
        isMyTeam: (t) => t == '自チーム',
        isMyPlayer: (p, t) => true,
        isMatchPlayed: (m) => true,
        playerStatsMap: {},
        cardResults: cardResults1,
        onRecordSceneResult: (scene, win, draw) {},
      );

      expect(cardResults1.length, 1);
      expect(cardResults1.first.isWin, isTrue);
      expect(cardResults1.first.resultType, '勝数勝ち');

      // 2. 本数差勝ち (1勝1敗 同勝数だが本数差 2本 vs 1本)
      final cardResults2 = <ExpeditionCardResult>[];
      final group2Matches = [
        const MatchModel(
          id: 'm2-senpo',
          matchType: '先鋒',
          redName: '自チーム:選手A',
          whiteName: '相手チーム:選手X',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
        ),
        const MatchModel(
          id: 'm2-taisho',
          matchType: '大将',
          redName: '自チーム:選手B',
          whiteName: '相手チーム:選手Y',
          redScore: 0,
          whiteScore: 1,
          status: 'finished',
        ),
      ];

      ExpeditionTeamMatchProcessor.processTeamMatches(
        groupMap: {'g2': group2Matches},
        selectedSummaryTeam: '全体',
        isMyTeam: (t) => t == '自チーム',
        isMyPlayer: (p, t) => true,
        isMatchPlayed: (m) => true,
        playerStatsMap: {},
        cardResults: cardResults2,
        onRecordSceneResult: (scene, win, draw) {},
      );

      expect(cardResults2.length, 1);
      expect(cardResults2.first.isWin, isTrue);
      expect(cardResults2.first.resultType, '本数差勝ち');

      // 3. 代表戦勝ち (同勝数・同本数からの代表戦)
      final cardResults3 = <ExpeditionCardResult>[];
      final group3Matches = [
        const MatchModel(
          id: 'm3-senpo',
          matchType: '先鋒',
          redName: '自チーム:選手A',
          whiteName: '相手チーム:選手X',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
        const MatchModel(
          id: 'm3-taisho',
          matchType: '大将',
          redName: '自チーム:選手B',
          whiteName: '相手チーム:選手Y',
          redScore: 0,
          whiteScore: 1,
          status: 'finished',
        ),
        const MatchModel(
          id: 'm3-daihyo',
          matchType: '代表戦',
          redName: '自チーム:選手A',
          whiteName: '相手チーム:選手Y',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
      ];

      ExpeditionTeamMatchProcessor.processTeamMatches(
        groupMap: {'g3': group3Matches},
        selectedSummaryTeam: '全体',
        isMyTeam: (t) => t == '自チーム',
        isMyPlayer: (p, t) => true,
        isMatchPlayed: (m) => true,
        playerStatsMap: {},
        cardResults: cardResults3,
        onRecordSceneResult: (scene, win, draw) {},
      );

      expect(cardResults3.length, 1);
      expect(cardResults3.first.isWin, isTrue);
      expect(cardResults3.first.resultType, '代表戦勝ち');

      // 4. 引き分け (同勝数・同本数・代表戦なし)
      final cardResults4 = <ExpeditionCardResult>[];
      final group4Matches = [
        const MatchModel(
          id: 'm4-senpo',
          matchType: '先鋒',
          redName: '自チーム:選手A',
          whiteName: '相手チーム:選手X',
          redScore: 1,
          whiteScore: 1,
          status: 'finished',
        ),
      ];

      ExpeditionTeamMatchProcessor.processTeamMatches(
        groupMap: {'g4': group4Matches},
        selectedSummaryTeam: '全体',
        isMyTeam: (t) => t == '自チーム',
        isMyPlayer: (p, t) => true,
        isMatchPlayed: (m) => true,
        playerStatsMap: {},
        cardResults: cardResults4,
        onRecordSceneResult: (scene, win, draw) {},
      );

      expect(cardResults4.length, 1);
      expect(cardResults4.first.isDraw, isTrue);
      expect(cardResults4.first.resultType, '引き分け');
    });

    test('シーン自動判定において 本戦・錬成・申合せのラベルが適切に分類されること', () {
      final cardResults = <ExpeditionCardResult>[];
      final scenes = <String>[];

      final matchHonsen = [
        const MatchModel(
          id: 'm-honsen',
          matchType: '先鋒',
          redName: '自チーム:選手A',
          whiteName: '相手チーム:選手B',
          matchScene: 'honsen',
          status: 'finished',
        ),
      ];

      final matchRensei = [
        const MatchModel(
          id: 'm-rensei',
          matchType: '先鋒',
          redName: '自チーム:選手A',
          whiteName: '相手チーム:選手B',
          matchScene: 'renseikai',
          status: 'finished',
        ),
      ];

      final matchMoushiawase = [
        const MatchModel(
          id: 'm-moushiawase',
          matchType: '先鋒',
          redName: '自チーム:選手A',
          whiteName: '相手チーム:選手B',
          matchScene: 'moushiawase',
          status: 'finished',
        ),
      ];

      ExpeditionTeamMatchProcessor.processTeamMatches(
        groupMap: {
          'g-h': matchHonsen,
          'g-r': matchRensei,
          'g-m': matchMoushiawase,
        },
        selectedSummaryTeam: '全体',
        isMyTeam: (t) => t == '自チーム',
        isMyPlayer: (p, t) => true,
        isMatchPlayed: (m) => true,
        playerStatsMap: {},
        cardResults: cardResults,
        onRecordSceneResult: (scene, win, draw) => scenes.add(scene),
      );

      expect(scenes.contains('honsen'), isTrue);
      expect(scenes.contains('renseikai'), isTrue);
      expect(scenes.contains('moushiawase'), isTrue);
    });

    test('個人戦および団体戦スタッツ集計において 選手ごとの勝敗引分が正確に積算されること', () {
      final playerStatsMap = <String, DetailedPlayerStats>{};
      final matches = [
        const MatchModel(
          id: 'm-stat-1',
          matchType: '先鋒',
          redName: '自チーム:山田',
          whiteName: '相手チーム:佐藤',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
        ),
        const MatchModel(
          id: 'm-stat-2',
          matchType: '次鋒',
          redName: '自チーム:山田',
          whiteName: '相手チーム:鈴木',
          redScore: 0,
          whiteScore: 1,
          status: 'finished',
        ),
      ];

      ExpeditionTeamMatchProcessor.processTeamMatches(
        groupMap: {'g-stat': matches},
        selectedSummaryTeam: '全体',
        isMyTeam: (t) => t == '自チーム',
        isMyPlayer: (p, t) => p == '山田',
        isMatchPlayed: (m) => true,
        playerStatsMap: playerStatsMap,
        cardResults: [],
        onRecordSceneResult: (scene, win, draw) {},
      );

      final yamadaStats = playerStatsMap['山田'];
      expect(yamadaStats, isNotNull);
      expect(yamadaStats!.win, 1);
      expect(yamadaStats.loss, 1);
      expect(yamadaStats.draw, 0);
    });
  });
}
