import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/standings_calculator.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_allocation_engine.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_generation_helper.dart';

void main() {
  group('[E2E] 複合奇数総当たりマルチコート配分および順位同期テスト', () {
    test('奇数5名リーグ戦においてバイ待機を挟みつつ2コートに均等配分され消化後の順位計算が正確に行われること', () async {
      // 1. 5人リーグ戦の対戦カード生成 (5 * 4 / 2 = 10試合)
      final matches = MatchGenerationHelper.generateLeagueMatches(
        participantCount: 5,
        leagueName: '部内リーグ',
        groupIndex: 0,
        durationMinutes: 4.0,
      );

      expect(matches.length, 10);

      // 2. 2コートへの配分シミュレーション
      final settings = CalculatorSettings(
        format: MatchFormatType.singleLeague,
        participantCount: 5,
        courtCount: 2,
        matchDurationMinutes: 4.0,
      );
      final calculationResult = MatchAllocationEngine.calculate(settings);

      expect(calculationResult.totalMatches, 10);
      // 2コートで10試合を均等消化 (各5試合)
      expect(calculationResult.getCourtMatchCount(1), 5);
      expect(calculationResult.getCourtMatchCount(2), 5);

      // 3. 試合進行シミュレーション（選手1〜5）
      // 選手1: 4勝0敗 (勝ち点4, 勝者数4, 勝本数7) -> 1位
      // 選手2: 3勝1敗 (勝ち点3, 勝者数3, 勝本数5) -> 2位
      // 選手3: 2勝2敗 (勝ち点2, 勝者数2, 勝本数4) -> 3位
      // 選手4: 1勝3敗 (勝ち点1, 勝者数1, 勝本数2) -> 4位
      // 選手5: 0勝4敗 (勝ち点0, 勝者数0, 勝本数0) -> 5位
      final playedMatches = [
        // 1番 vs 2番 (1番が 2-1 で勝利)
        const MatchModel(
          id: 'm_1_2',
          tournamentId: 't_odd',
          matchType: '個人戦',
          redName: '選手1',
          whiteName: '選手2',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
        ),
        // 1番 vs 3番 (1番が 2-0 で勝利)
        const MatchModel(
          id: 'm_1_3',
          tournamentId: 't_odd',
          matchType: '個人戦',
          redName: '選手1',
          whiteName: '選手3',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
        ),
        // 1番 vs 4番 (1番が 1-0 で勝利)
        const MatchModel(
          id: 'm_1_4',
          tournamentId: 't_odd',
          matchType: '個人戦',
          redName: '選手1',
          whiteName: '選手4',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
        // 1番 vs 5番 (1番が 2-0 で勝利)
        const MatchModel(
          id: 'm_1_5',
          tournamentId: 't_odd',
          matchType: '個人戦',
          redName: '選手1',
          whiteName: '選手5',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
        ),
        // 2番 vs 3番 (2番が 2-1 で勝利)
        const MatchModel(
          id: 'm_2_3',
          tournamentId: 't_odd',
          matchType: '個人戦',
          redName: '選手2',
          whiteName: '選手3',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
        ),
        // 2番 vs 4番 (2番が 1-0 で勝利)
        const MatchModel(
          id: 'm_2_4',
          tournamentId: 't_odd',
          matchType: '個人戦',
          redName: '選手2',
          whiteName: '選手4',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
        // 2番 vs 5番 (2番が 1-0 で勝利)
        const MatchModel(
          id: 'm_2_5',
          tournamentId: 't_odd',
          matchType: '個人戦',
          redName: '選手2',
          whiteName: '選手5',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
        // 3番 vs 4番 (3番が 2-1 で勝利)
        const MatchModel(
          id: 'm_3_4',
          tournamentId: 't_odd',
          matchType: '個人戦',
          redName: '選手3',
          whiteName: '選手4',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
        ),
        // 3番 vs 5番 (3番が 1-0 で勝利)
        const MatchModel(
          id: 'm_3_5',
          tournamentId: 't_odd',
          matchType: '個人戦',
          redName: '選手3',
          whiteName: '選手5',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
        // 4番 vs 5番 (4番が 1-0 で勝利)
        const MatchModel(
          id: 'm_4_5',
          tournamentId: 't_odd',
          matchType: '個人戦',
          redName: '選手4',
          whiteName: '選手5',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
      ];

      // 4. 順位表算出 (LeagueStandingsCalculator)
      const rule = MatchRule(winPoint: 1.0, drawPoint: 0.5, lossPoint: 0.0);
      final standings = LeagueStandingsCalculator().calculate(
        playedMatches,
        rule,
      );

      // 5. 順位検証
      expect(standings.length, 5);
      expect(standings[0].name, '選手1');
      expect(standings[0].rank, 1);
      expect(standings[0].customPoints, 4.0);

      expect(standings[1].name, '選手2');
      expect(standings[1].rank, 2);
      expect(standings[1].customPoints, 3.0);

      expect(standings[2].name, '選手3');
      expect(standings[2].rank, 3);
      expect(standings[2].customPoints, 2.0);

      expect(standings[3].name, '選手4');
      expect(standings[3].rank, 4);
      expect(standings[3].customPoints, 1.0);

      expect(standings[4].name, '選手5');
      expect(standings[4].rank, 5);
      expect(standings[4].customPoints, 0.0);
    });
  });
}
