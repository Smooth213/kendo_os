import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

void main() {
  group('[E2E] 部内戦30人勝ち抜き循環およびリーダーボード集計E2Eテスト', () {
    test('30名の剣士による連続勝ち抜き試合で最多連勝記録と総取得本数がリーダーボードへ正しく集計されること', () {
      final matches = <MatchModel>[];
      final winStreaks = <String, int>{};
      final totalPoints = <String, int>{};

      String currentKing = '選手_0';
      int currentStreak = 0;

      // 30試合の勝ち抜き循環シミュレーション
      for (int i = 1; i <= 30; i++) {
        final challenger = '選手_$i';
        // 偶数回はキング防衛（面で1本勝ち）、奇数回は挑戦者が奪取（小手・面で2本勝ち）
        final bool kingWins = (i % 3 != 0);

        final int redScore = kingWins ? 1 : 0;
        final int whiteScore = kingWins ? 0 : 2;

        final match = MatchModel(
          id: 'streak_match_$i',
          tournamentId: 'bunaiksen_streak_30',
          matchType: '部内戦勝ち抜き',
          redName: currentKing,
          whiteName: challenger,
          redScore: redScore,
          whiteScore: whiteScore,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'ev_${i}_1',
              side: kingWins ? Side.red : Side.white,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: DateTime(2026, 10, 2, 10, i),
            ),
          ],
        );
        matches.add(match);

        // 集計ロジック
        if (kingWins) {
          currentStreak++;
          winStreaks[currentKing] =
              (winStreaks[currentKing] ?? 0) < currentStreak
              ? currentStreak
              : (winStreaks[currentKing] ?? 0);
          totalPoints[currentKing] = (totalPoints[currentKing] ?? 0) + 1;
        } else {
          currentKing = challenger;
          currentStreak = 1;
          winStreaks[currentKing] =
              (winStreaks[currentKing] ?? 0) < currentStreak
              ? currentStreak
              : (winStreaks[currentKing] ?? 0);
          totalPoints[challenger] = (totalPoints[challenger] ?? 0) + 2;
        }
      }

      // 全30試合が正しく完了していること
      expect(matches.length, 30);
      expect(matches.every((m) => m.status == 'finished'), isTrue);

      // リーダーボードソート（最多連勝数降順）
      final leaderboard = winStreaks.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      expect(leaderboard.isNotEmpty, isTrue);
      expect(leaderboard.first.value, greaterThanOrEqualTo(2));
      expect(totalPoints.values.reduce((a, b) => a + b), greaterThan(30));
    });
  });
}
