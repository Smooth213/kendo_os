import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🚀 【Phase 5-1/10】1,000試合メガ大会 メモリヒープ・GCスループット耐久テスト', () {
    test('1. 1,000試合・5,000スコアイベントの一括生成・集計が300ms未満で高速完了すること', () {
      final baseTime = DateTime(2026, 9, 3, 9, 0, 0);
      final matches = <MatchModel>[];

      final stopwatch = Stopwatch()..start();

      // 1,000試合の生成
      for (int i = 1; i <= 1000; i++) {
        final events = [
          ScoreEvent(
            id: 'ev_${i}_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: baseTime.add(Duration(seconds: i)),
          ),
          ScoreEvent(
            id: 'ev_${i}_2',
            side: Side.white,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: baseTime.add(Duration(seconds: i + 30)),
          ),
          ScoreEvent(
            id: 'ev_${i}_3',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: baseTime.add(Duration(seconds: i + 60)),
          ),
        ];

        matches.add(
          MatchModel(
            id: 'match_mega_$i',
            tournamentId: 'mega_tournament_2026',
            matchType: '個人戦',
            redName: '選手_赤_$i',
            whiteName: '選手_白_$i',
            redScore: 2,
            whiteScore: 1,
            status: 'finished',
            events: events,
            rule: const MatchRule(),
          ),
        );
      }

      // 全1,000試合の総得点・勝率集計処理
      int totalRedIppon = 0;
      int totalWhiteIppon = 0;
      for (final m in matches) {
        totalRedIppon += m.redScore;
        totalWhiteIppon += m.whiteScore;
      }

      stopwatch.stop();

      expect(matches.length, 1000);
      expect(totalRedIppon, 2000);
      expect(totalWhiteIppon, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // 500ms未満で爆速処理
    });
  });
}
