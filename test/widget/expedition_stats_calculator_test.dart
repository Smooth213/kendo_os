import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_calculator.dart';

void main() {
  group('🛡️ ExpeditionStatsCalculator Unit Tests', () {
    test('1. calculate calculates win/loss and strike breakdown correctly', () {
      final matches = [
        MatchModel(
          id: 'm1',
          matchType: '団体戦',
          groupName: 'group1',
          redName: '青龍館: 山田',
          whiteName: '白虎館: 佐藤',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          matchScene: 'honsen',
          events: [
            ScoreEvent(
              id: 'e1',
              timestamp: DateTime.now(),
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
            ),
            ScoreEvent(
              id: 'e2',
              timestamp: DateTime.now(),
              side: Side.red,
              strikeType: StrikeType.kote,
              isIppon: true,
            ),
          ],
        ),
      ];

      final summary = ExpeditionStatsCalculator.calculate(
        matches: matches,
        registeredTeamNames: {'青龍館'},
        registeredPlayerNames: {'山田'},
        selectedSummaryTeam: '青龍館',
      );

      expect(summary.honsenWin, 1);
      expect(summary.honsenLoss, 0);
      expect(summary.teamMen, 1);
      expect(summary.teamKote, 1);
      expect(summary.teamTotalScored, 2);
      expect(summary.teamTotalConceded, 0);
      expect(summary.playerStatsMap['山田']?.win, 1);
      expect(summary.playerStatsMap['山田']?.men, 1);
      expect(summary.playerStatsMap['山田']?.kote, 1);
    });
  });
}
