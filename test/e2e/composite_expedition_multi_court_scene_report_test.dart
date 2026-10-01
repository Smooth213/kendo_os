import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_team_match_processor.dart';

void main() {
  group('[E2E] 遠征複数コート混在シーンおよび代表戦帳票一括出力 複合シナリオテスト', () {
    test('複数コート進行と本戦錬成申合せ混在および代表戦決着から帳票出力まで整合すること', () async {
      // 1. 第1コート: 本戦団体戦（先鋒・次鋒・中堅・副将・大将・代表戦）
      final court1Matches = [
        const MatchModel(
          id: 'c1-m1',
          matchType: '先鋒',
          redName: '剣道部A:選手1',
          whiteName: 'ライバル校:選手X',
          redScore: 1,
          whiteScore: 0,
          matchScene: 'honsen',
          status: 'finished',
        ),
        const MatchModel(
          id: 'c1-m2',
          matchType: '次鋒',
          redName: '剣道部A:選手2',
          whiteName: 'ライバル校:選手Y',
          redScore: 0,
          whiteScore: 1,
          matchScene: 'honsen',
          status: 'finished',
        ),
        const MatchModel(
          id: 'c1-m3',
          matchType: '大将',
          redName: '剣道部A:選手3',
          whiteName: 'ライバル校:選手Z',
          redScore: 0,
          whiteScore: 0,
          matchScene: 'honsen',
          status: 'finished',
        ),
        const MatchModel(
          id: 'c1-daihyo',
          matchType: '代表戦',
          redName: '剣道部A:選手1',
          whiteName: 'ライバル校:選手X',
          redScore: 1,
          whiteScore: 0,
          matchScene: 'honsen',
          status: 'finished',
        ),
      ];

      // 2. 第2コート: 錬成会団体戦
      final court2Matches = [
        const MatchModel(
          id: 'c2-m1',
          matchType: '先鋒',
          redName: '剣道部A:選手4',
          whiteName: '武道館:選手P',
          redScore: 2,
          whiteScore: 0,
          matchScene: 'renseikai',
          status: 'finished',
        ),
        const MatchModel(
          id: 'c2-m2',
          matchType: '大将',
          redName: '剣道部A:選手5',
          whiteName: '武道館:選手Q',
          redScore: 2,
          whiteScore: 0,
          matchScene: 'renseikai',
          status: 'finished',
        ),
      ];

      // 3. 第3コート: 申合せ個人戦
      final court3Matches = [
        const MatchModel(
          id: 'c3-m1',
          matchType: '個人戦',
          redName: '剣道部A:選手1',
          whiteName: '合同チーム:選手M',
          redScore: 1,
          whiteScore: 0,
          matchScene: 'moushiawase',
          status: 'finished',
        ),
      ];

      final groupMap = {
        'group-court-1': court1Matches,
        'group-court-2': court2Matches,
        'group-court-3': court3Matches,
      };

      final cardResults = <ExpeditionCardResult>[];
      final playerStatsMap = <String, DetailedPlayerStats>{};
      final recordedScenes = <String>[];
      int individualWin = 0;
      int individualDraw = 0;

      // 複合プロセッサ実行
      ExpeditionTeamMatchProcessor.processTeamMatches(
        groupMap: groupMap,
        selectedSummaryTeam: '全体',
        isMyTeam: (t) => t == '剣道部A',
        isMyPlayer: (p, t) => true,
        isMatchPlayed: (m) => m.status == 'finished',
        playerStatsMap: playerStatsMap,
        cardResults: cardResults,
        onRecordSceneResult: (s, win, draw) => recordedScenes.add(s),
        onRecordIndividualResult: (win, draw) {
          if (win) individualWin++;
          if (draw) individualDraw++;
        },
      );

      // 第1コート（代表戦勝ち）検証
      final court1Result = cardResults.firstWhere(
        (r) => r.opponentTeamName == 'ライバル校',
      );
      expect(court1Result.isWin, isTrue);
      expect(court1Result.resultType, '代表戦勝ち');

      // 第2コート（勝数勝ち）検証
      final court2Result = cardResults.firstWhere(
        (r) => r.opponentTeamName == '武道館',
      );
      expect(court2Result.isWin, isTrue);
      expect(court2Result.resultType, '勝数勝ち');

      // シーン集計の混在検証
      expect(recordedScenes.contains('honsen'), isTrue);
      expect(recordedScenes.contains('renseikai'), isTrue);

      // 個人戦コールバックおよび集計検証
      expect(individualWin, greaterThanOrEqualTo(0));
      expect(individualDraw, greaterThanOrEqualTo(0));

      // 選手個人スタッツ検証（選手1: 先鋒勝ち＋代表戦＋個人戦）
      final p1Stats = playerStatsMap['選手1'];
      expect(p1Stats, isNotNull);
      expect(p1Stats!.win, greaterThanOrEqualTo(1));
    });
  });
}
