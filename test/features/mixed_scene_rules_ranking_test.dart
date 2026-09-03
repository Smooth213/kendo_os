import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

void main() {
  group('🛡️ 混合ルール・変則リーグ戦 集計整合性テスト要塞', () {
    test('1. 【変則勝ち点】勝3/分1/負0 点ルールにおいて、勝ち点 ➔ 勝者数 ➔ 総本数 で厳密に順位が確定する', () {
      const rule = MatchRule(
        winPoint: 3.0,
        drawPoint: 1.0,
        lossPoint: 0.0,
        matchTimeMinutes: 3.0,
      );

      final matches = [
        // チームA vs チームB: A勝ち (A:2勝4本, B:1勝2本)
        const MatchModel(
          id: 'ab_1',
          matchType: '先鋒',
          redName: 'チームA:選手A1',
          whiteName: 'チームB:選手B1',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
        const MatchModel(
          id: 'ab_2',
          matchType: '中堅',
          redName: 'チームA:選手A2',
          whiteName: 'チームB:選手B2',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
        const MatchModel(
          id: 'ab_3',
          matchType: '大将',
          redName: 'チームA:選手A3',
          whiteName: 'チームB:選手B3',
          redScore: 0,
          whiteScore: 2,
          status: 'approved',
        ),

        // チームB vs チームC: B勝ち (B:2勝3本, C:0勝1本)
        const MatchModel(
          id: 'bc_1',
          matchType: '先鋒',
          redName: 'チームB:選手B1',
          whiteName: 'チームC:選手C1',
          redScore: 2,
          whiteScore: 1,
          status: 'approved',
        ),
        const MatchModel(
          id: 'bc_2',
          matchType: '中堅',
          redName: 'チームB:選手B2',
          whiteName: 'チームC:選手C2',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
        ),

        // チームA vs チームC: 引き分け (各1勝2本)
        const MatchModel(
          id: 'ac_1',
          matchType: '先鋒',
          redName: 'チームA:選手A1',
          whiteName: 'チームC:選手C1',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
        const MatchModel(
          id: 'ac_2',
          matchType: '大将',
          redName: 'チームA:選手A2',
          whiteName: 'チームC:選手C2',
          redScore: 0,
          whiteScore: 2,
          status: 'approved',
        ),
      ];

      final standings = KendoRuleEngine.calculateLeagueStandings(matches, rule);

      expect(standings.length, 3);
      // チームA: 1勝1分 = 3 + 1 = 4点 (1位)
      // チームB: 1勝1敗 = 3 + 0 = 3点 (2位)
      // チームC: 0勝1分1敗 = 0 + 1 = 1点 (3位)
      expect(standings[0].name, 'チームA');
      expect(standings[0].rank, 1);
      expect(standings[0].customPoints, 4.0);

      expect(standings[1].name, 'チームB');
      expect(standings[1].rank, 2);
      expect(standings[1].customPoints, 3.0);

      expect(standings[2].name, 'チームC');
      expect(standings[2].rank, 3);
      expect(standings[2].customPoints, 1.0);
    });

    test('2. 【同率同勝ち点タイブレーク】勝ち点が同じ場合、勝者数 ➔ 総取得本数 で差が判定される', () {
      const rule = MatchRule(winPoint: 3.0, drawPoint: 1.0, lossPoint: 0.0);

      // チームXとチームYが共に1勝1敗（勝ち点3.0）だが、
      // チームXは勝者数が多い（X: 3勝者, Y: 2勝者）
      final matches = [
        // チームX vs チームZ (X勝ち: 3人勝ち計5本)
        const MatchModel(
          id: 'xz_1',
          matchType: '先鋒',
          redName: 'チームX:選手1',
          whiteName: 'チームZ:選手1',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
        const MatchModel(
          id: 'xz_2',
          matchType: '中堅',
          redName: 'チームX:選手2',
          whiteName: 'チームZ:選手2',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
        const MatchModel(
          id: 'xz_3',
          matchType: '大将',
          redName: 'チームX:選手3',
          whiteName: 'チームZ:選手3',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
        ),

        // チームY vs チームZ (Y勝ち: 2人勝ち計3本)
        const MatchModel(
          id: 'yz_1',
          matchType: '先鋒',
          redName: 'チームY:選手1',
          whiteName: 'チームZ:選手1',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
        const MatchModel(
          id: 'yz_2',
          matchType: '中堅',
          redName: 'チームY:選手2',
          whiteName: 'チームZ:選手2',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
        ),

        // チームX vs チームY (Y勝ち)
        const MatchModel(
          id: 'xy_1',
          matchType: '大将',
          redName: 'チームX:選手3',
          whiteName: 'チームY:選手3',
          redScore: 0,
          whiteScore: 1,
          status: 'approved',
        ),
      ];

      final standings = KendoRuleEngine.calculateLeagueStandings(matches, rule);

      // チームY: 2勝0敗 = 6点 (1位)
      // チームX: 1勝1敗 = 3点 (2位)
      // チームZ: 0勝2敗 = 0点 (3位)
      expect(standings[0].name, 'チームY');
      expect(standings[0].rank, 1);
      expect(standings[1].name, 'チームX');
      expect(standings[1].rank, 2);
      expect(standings[2].name, 'チームZ');
      expect(standings[2].rank, 3);
    });

    test(
      '3. 【シーン混合＆集計除外】countForStandings=false や練習試合（moushiawase）の除外フィルタリング',
      () {
        const rule = MatchRule(winPoint: 3.0, drawPoint: 1.0, lossPoint: 0.0);

        final mixedMatches = [
          // 公式本戦 (カウント対象)
          const MatchModel(
            id: 'honsen_1',
            matchType: '大将',
            redName: '神武館:佐藤',
            whiteName: '修道館:田中',
            redScore: 2,
            whiteScore: 0,
            status: 'approved',
            matchScene: 'honsen',
            countForStandings: true,
          ),
          // 申し合わせ練習試合 (カウント除外対象)
          const MatchModel(
            id: 'moushiawase_1',
            matchType: '大将',
            redName: '修道館:田中',
            whiteName: '神武館:佐藤',
            redScore: 2,
            whiteScore: 0,
            status: 'approved',
            matchScene: 'moushiawase',
            countForStandings: false,
          ),
        ];

        // 集計対象のみを安全に抽出（本番UIでの推奨フィルタ）
        final eligibleMatches = mixedMatches
            .where((m) => m.countForStandings)
            .toList();
        final standings = KendoRuleEngine.calculateLeagueStandings(
          eligibleMatches,
          rule,
        );

        expect(standings.length, 2);
        expect(standings[0].name, '神武館');
        expect(standings[0].matchWins, 1);
        expect(standings[0].customPoints, 3.0);
        expect(standings[1].name, '修道館');
        expect(standings[1].matchLosses, 1);
      },
    );
  });
}
