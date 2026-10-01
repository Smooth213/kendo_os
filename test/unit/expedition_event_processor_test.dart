import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_event_processor.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';

void main() {
  group('[Unit] 遠征成績スコアイベント集計プロセッサ単体テスト', () {
    test('有効打突種別および自チーム得失本数が正確に積算され未消化試合が除外されること', () {
      final now = DateTime.now();
      final match1 = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '先鋒',
        groupName: '予選A',
        redName: '剣友会:山田',
        whiteName: '道場B:佐藤',
        status: 'finished',
        events: [
          ScoreEvent(
            id: 'ev1',
            isIppon: true,
            side: Side.red,
            strikeType: StrikeType.men,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'ev2',
            isIppon: true,
            side: Side.red,
            strikeType: StrikeType.kote,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'ev3',
            isIppon: true,
            side: Side.white,
            strikeType: StrikeType.dou,
            timestamp: now,
          ),
          // 取り消されたイベント
          ScoreEvent(
            id: 'ev4',
            isIppon: true,
            side: Side.red,
            strikeType: StrikeType.tsuki,
            isCanceled: true,
            timestamp: now,
          ),
        ],
      );

      final match2 = MatchModel(
        id: 'm2',
        tournamentId: 't1',
        matchType: '次鋒',
        groupName: '予選A',
        redName: '道場C:鈴木',
        whiteName: '剣友会:田中',
        status: 'finished',
        events: [
          ScoreEvent(
            id: 'ev5',
            isIppon: true,
            isHansoku: true,
            side: Side.white,
            timestamp: now,
          ),
        ],
      );

      // 未消化試合
      final matchUnplayed = MatchModel(
        id: 'm3',
        tournamentId: 't1',
        matchType: '中堅',
        groupName: '予選A',
        redName: '剣友会:高橋',
        whiteName: '道場B:渡辺',
        status: 'pending',
        events: [
          ScoreEvent(
            id: 'ev6',
            isIppon: true,
            side: Side.red,
            strikeType: StrikeType.men,
            timestamp: now,
          ),
        ],
      );

      final playerStatsMap = <String, DetailedPlayerStats>{};

      final result = ExpeditionEventProcessor.processEvents(
        matches: [match1, match2, matchUnplayed],
        selectedSummaryTeam: '全体',
        isMyTeam: (team) => team == '剣友会',
        isMyPlayer: (player, team) => team == '剣友会',
        isMatchPlayed: (m) => m.status == 'finished',
        playerStatsMap: playerStatsMap,
      );

      // match1: 山田が面・小手取得(2点)、佐藤が胴取得(失点1)
      // match2: 田中が反則取得(1点)
      // matchUnplayed: statusがpendingのためスキップ
      expect(result.teamMen, 1);
      expect(result.teamKote, 1);
      expect(result.teamDou, 0); // 自チームの胴はゼロ
      expect(result.teamTsuki, 0); // 取り消しのためゼロ
      expect(result.teamHansoku, 1);
      expect(result.teamTotalScored, 3);
      expect(result.teamTotalConceded, 1);

      expect(playerStatsMap.containsKey('山田'), isTrue);
      expect(playerStatsMap['山田']!.totalPoints, 2);
      expect(playerStatsMap['山田']!.men, 1);
      expect(playerStatsMap['山田']!.kote, 1);
      expect(playerStatsMap['山田']!.concededPoints, 1);

      expect(playerStatsMap.containsKey('田中'), isTrue);
      expect(playerStatsMap['田中']!.totalPoints, 1);
      expect(playerStatsMap['田中']!.hansoku, 1);
    });
  });
}
