import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/application/services/line_summary_formatter.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_calculator.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  group('Expedition Stats Team & Individual Separation Tests', () {
    test('団体戦と個人戦で選手別成績が正しく分離されて集計されること', () {
      final matches = [
        // 1. 団体戦の試合 (groupName: group_1) - 山田選手が勝利 (2本勝ち)
        MatchModel(
          id: 'm_team_1',
          groupName: 'group_1',
          redName: '道上剣友会 : 山田',
          whiteName: 'ライバル道場 : 相手1',
          matchType: '先鋒',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'ev1',
              timestamp: DateTime.now(),
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
            ),
            ScoreEvent(
              id: 'ev2',
              timestamp: DateTime.now(),
              side: Side.red,
              strikeType: StrikeType.kote,
              isIppon: true,
            ),
          ],
        ),
        // 2. 個人戦の試合 (groupName なし) - 山田選手が勝利 (1本勝ち)
        MatchModel(
          id: 'm_ind_1',
          groupName: null,
          redName: '道上剣友会 : 山田',
          whiteName: 'ライバル道場 : 相手2',
          matchType: '個人戦',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'ev3',
              timestamp: DateTime.now(),
              side: Side.red,
              strikeType: StrikeType.dou,
              isIppon: true,
            ),
          ],
        ),
      ];

      final summary = ExpeditionStatsCalculator.calculate(
        matches: matches,
        registeredTeamNames: {'道上剣友会'},
        registeredPlayerNames: {'山田'},
        selectedSummaryTeam: '道上剣友会',
      );

      final yamadaStats = summary.playerStatsMap['山田'];
      expect(yamadaStats, isNotNull);

      // 通算
      expect(yamadaStats!.win, 2);
      expect(yamadaStats.loss, 0);
      expect(yamadaStats.totalPoints, 3);

      // 団体戦内訳
      expect(yamadaStats.teamWin, 1);
      expect(yamadaStats.teamLoss, 0);
      expect(yamadaStats.teamPoints, 2);

      // 個人戦内訳
      expect(yamadaStats.individualWin, 1);
      expect(yamadaStats.individualLoss, 0);
      expect(yamadaStats.individualPoints, 1);

      // 個人戦サマリー
      expect(summary.individualTotalWins, 1);
      expect(summary.individualTotalLosses, 0);

      // LINEフォーマッターの出力検証
      final lineText = LineSummaryFormatter.formatExpeditionSummary(
        title: '道上剣友会',
        matches: matches,
      );

      expect(lineText.contains('【道上剣友会 結果速報】'), isTrue);
      expect(lineText.contains('【団体戦】'), isTrue);
      expect(lineText.contains('【個人戦】'), isTrue);
      expect(lineText.contains('Kendo_Sync より配信'), isTrue);
    });
  });
}
