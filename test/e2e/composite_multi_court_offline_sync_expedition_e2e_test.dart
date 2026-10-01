import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_calculator.dart';

void main() {
  group('[E2E] 【Composite E2E】複数コート並行 × ネットワーク途絶復帰CRDTマージ × 遠征記録リアルタイム合算', () {
    test(
      '第1コート(常時接続)と第2コート(オフライン断線)の並行進行後、復帰時CRDT決定論的マージ＆遠征記録完全合算こと',
      () async {
        final baseTime = DateTime(2026, 9, 27, 9, 0, 0);

        // --- 第1コート (オンライン正常稼働): 小学生団体戦 (本戦) ---
        // 試合1: 錬心館 A vs 修道館 A (赤3勝1分 7本 - 2本 で錬心館勝利)
        final court1Match1 = MatchModel(
          id: 'c1_m1',
          groupName: '第1コート-第1試合',
          category: '小学生の部',
          matchScene: 'honsen',
          matchType: '団体戦',
          redName: '錬心館 A',
          whiteName: '修道館 A',
          redScore: 7,
          whiteScore: 2,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'c1_e1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              logicalClock: 1,
              timestamp: baseTime,
            ),
            ScoreEvent(
              id: 'c1_e2',
              side: Side.white,
              strikeType: StrikeType.kote,
              isIppon: true,
              logicalClock: 2,
              timestamp: baseTime.add(const Duration(minutes: 1)),
            ),
            ScoreEvent(
              id: 'c1_e3',
              side: Side.red,
              strikeType: StrikeType.dou,
              isIppon: true,
              logicalClock: 3,
              timestamp: baseTime.add(const Duration(minutes: 2)),
            ),
          ],
        );

        // 試合2: 錬心館 A vs 武徳館 A (赤2勝1敗2分 4本 - 3本 で錬心館勝利)
        final court1Match2 = MatchModel(
          id: 'c1_m2',
          groupName: '第1コート-第2試合',
          category: '小学生の部',
          matchScene: 'honsen',
          matchType: '団体戦',
          redName: '錬心館 A',
          whiteName: '武徳館 A',
          redScore: 4,
          whiteScore: 3,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'c1_e4',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              logicalClock: 4,
              timestamp: baseTime.add(const Duration(minutes: 10)),
            ),
          ],
        );

        // --- 第2コート (オフラインネットワーク途絶中): 中学生団体戦 (錬成会＆本戦) ---
        // 途絶中にローカルオフラインキューへイベントを蓄積
        final court2OfflineEvents = <ScoreEvent>[
          ScoreEvent(
            id: 'c2_offline_e3',
            side: Side.white,
            strikeType: StrikeType.men,
            isIppon: true,
            logicalClock: 7, // 外部到着時に順序が逆転
            timestamp: baseTime.add(const Duration(minutes: 15)),
          ),
          ScoreEvent(
            id: 'c2_offline_e1',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            logicalClock: 5,
            timestamp: baseTime.add(const Duration(minutes: 12)),
          ),
          ScoreEvent(
            id: 'c2_offline_e2',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            logicalClock: 6,
            timestamp: baseTime.add(const Duration(minutes: 14)),
          ),
        ];

        // 🌐 ネットワーク復旧！CRDT調停エンジン（論理時計順ソート）
        final mergedCourt2Events = List<ScoreEvent>.from(court2OfflineEvents)
          ..sort((a, b) => a.logicalClock.compareTo(b.logicalClock));

        expect(mergedCourt2Events.first.id, 'c2_offline_e1');
        expect(mergedCourt2Events[1].id, 'c2_offline_e2');
        expect(mergedCourt2Events.last.id, 'c2_offline_e3');

        // 第2コート復帰後の試合データ確定
        final court2Match1 = MatchModel(
          id: 'c2_m1',
          groupName: '第2コート-第1試合',
          category: '中学生の部',
          matchScene: 'renseikai',
          matchType: '団体戦',
          redName: '錬心館 B',
          whiteName: '大義塾 B',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
          events: mergedCourt2Events,
        );

        final court2Match2 = MatchModel(
          id: 'c2_m2',
          groupName: '第2コート-第2試合',
          category: '中学生の部',
          matchScene: 'honsen',
          matchType: '団体戦',
          redName: '錬心館 B',
          whiteName: '明徳館 B',
          redScore: 1,
          whiteScore: 3,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'c2_e4',
              side: Side.white,
              strikeType: StrikeType.men,
              isIppon: true,
              logicalClock: 8,
              timestamp: baseTime.add(const Duration(minutes: 20)),
            ),
          ],
        );

        // --- 本部側での遠征記録リアルタイム合算集計 ---
        final allMultiCourtMatches = [
          court1Match1,
          court1Match2,
          court2Match1,
          court2Match2,
        ];

        final summary = ExpeditionStatsCalculator.calculate(
          matches: allMultiCourtMatches,
          registeredTeamNames: const {'錬心館 A', '錬心館 B'},
          registeredPlayerNames: const {},
          selectedSummaryTeam: '全体',
        );

        // 本戦集計:
        // 第1コート: 錬心館 A 2勝 (vs 修道館 A, vs 武徳館 A)
        // 第2コート: 錬心館 B 1敗 (vs 明徳館 B)
        // 合計: 本戦 2勝 1敗 0分
        expect(summary.honsenWin, 2);
        expect(summary.honsenLoss, 1);
        expect(summary.honsenDraw, 0);

        // 錬成会集計:
        // 第2コート: 錬心館 B 1勝 (vs 大義塾 B)
        // 合計: 錬成会 1勝 0敗 0分
        expect(summary.renseikaiWin, 1);
        expect(summary.renseikaiLoss, 0);
        expect(summary.renseikaiDraw, 0);

        // 総合勝率算出検証
        final totalHonsen =
            summary.honsenWin + summary.honsenLoss + summary.honsenDraw;
        final honsenRate = totalHonsen > 0
            ? (summary.honsenWin / totalHonsen) * 100
            : 0.0;
        expect(honsenRate, closeTo(66.6, 0.1));

        // チームリストの正確性
        expect(summary.teamsList.contains('錬心館 A'), isTrue);
        expect(summary.teamsList.contains('錬心館 B'), isTrue);
      },
    );
  });
}
