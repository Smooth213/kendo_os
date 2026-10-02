import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

void main() {
  group('[E2E] 団体戦リーグ不戦勝および両者失格混在集計複合テスト', () {
    test('不戦勝と両者失格引き分けが混在する団体リーグ戦において勝敗勝点本数が正確に集計されること', () {
      // 3チーム（A道場, B道場, C道場）の団体戦リーグ（各対戦3人制: 先鋒・中堅・大将）
      // 対戦1: A道場 vs B道場
      //   先鋒: A道場勝利 (2-0, 不戦勝: 相手不在)
      //   中堅: 引き分け (1-1)
      //   大将: A道場勝利 (1-0)
      //   -> A道場の勝ち (2勝0敗1分, 取得本数4-1)
      //
      // 対戦2: B道場 vs C道場
      //   先鋒: 両者失格 (0-0, 双方不在または反則失格)
      //   中堅: 引き分け (0-0)
      //   大将: C道場勝利 (0-1)
      //   -> C道場の勝ち (1勝0敗2分, 取得本数1-0)
      //
      // 対戦3: A道場 vs C道場
      //   先鋒: 引き分け (1-1)
      //   中堅: A道場勝利 (1-0)
      //   大将: C道場勝利 (0-2)
      //   -> 勝者数タイ(1勝1敗1分)、本数でC道場勝利 (取得本数 A:2 vs C:3)

      const rule = MatchRule(winPoint: 3.0, drawPoint: 1.0, lossPoint: 0.0);

      final matches = <MatchModel>[
        // --- 対戦1: A道場 vs B道場 ---
        MatchModel(
          id: 'm1_senpo',
          matchType: 'team',
          redName: 'A道場:先鋒',
          whiteName: 'B道場:先鋒',
          redScore: 2,
          whiteScore: 0,
          status: 'completed',
          events: [
            ScoreEvent(
              id: 'ev_fusen_1',
              side: Side.red,
              isFusen: true,
              timestamp: DateTime.now(),
            ),
          ],
        ),
        MatchModel(
          id: 'm1_chuken',
          matchType: 'team',
          redName: 'A道場:中堅',
          whiteName: 'B道場:中堅',
          redScore: 1,
          whiteScore: 1,
          status: 'completed',
        ),
        MatchModel(
          id: 'm1_taisho',
          matchType: 'team',
          redName: 'A道場:大将',
          whiteName: 'B道場:大将',
          redScore: 1,
          whiteScore: 0,
          status: 'completed',
        ),

        // --- 対戦2: B道場 vs C道場 ---
        MatchModel(
          id: 'm2_senpo',
          matchType: 'team',
          redName: 'B道場:先鋒',
          whiteName: 'C道場:先鋒',
          redScore: 0,
          whiteScore: 0, // 両者失格（本数ゼロ）
          status: 'completed',
        ),
        MatchModel(
          id: 'm2_chuken',
          matchType: 'team',
          redName: 'B道場:中堅',
          whiteName: 'C道場:中堅',
          redScore: 0,
          whiteScore: 0,
          status: 'completed',
        ),
        MatchModel(
          id: 'm2_taisho',
          matchType: 'team',
          redName: 'B道場:大将',
          whiteName: 'C道場:大将',
          redScore: 0,
          whiteScore: 1,
          status: 'completed',
        ),

        // --- 対戦3: A道場 vs C道場 ---
        MatchModel(
          id: 'm3_senpo',
          matchType: 'team',
          redName: 'A道場:先鋒',
          whiteName: 'C道場:先鋒',
          redScore: 1,
          whiteScore: 1,
          status: 'completed',
        ),
        MatchModel(
          id: 'm3_chuken',
          matchType: 'team',
          redName: 'A道場:中堅',
          whiteName: 'C道場:中堅',
          redScore: 1,
          whiteScore: 0,
          status: 'completed',
        ),
        MatchModel(
          id: 'm3_taisho',
          matchType: 'team',
          redName: 'A道場:大将',
          whiteName: 'C道場:大将',
          redScore: 0,
          whiteScore: 2,
          status: 'completed',
        ),
      ];

      final standings = KendoRuleEngine.calculateLeagueStandings(matches, rule);

      // 全3チーム存在すること
      expect(standings.length, 3);

      final statC = standings.firstWhere((s) => s.name == 'C道場');
      final statA = standings.firstWhere((s) => s.name == 'A道場');
      final statB = standings.firstWhere((s) => s.name == 'B道場');

      // C道場: 2勝0敗 (対B道場勝利, 対A道場勝利) -> 勝ち点6.0
      expect(statC.matchWins, 2);
      expect(statC.matchLosses, 0);
      expect(statC.customPoints, 6.0);
      expect(statC.rank, 1);

      // A道場: 1勝1敗 (対B道場勝利, 対C道場敗戦) -> 勝ち点3.0
      expect(statA.matchWins, 1);
      expect(statA.matchLosses, 1);
      expect(statA.customPoints, 3.0);
      expect(statA.rank, 2);

      // B道場: 0勝2敗 -> 勝ち点0.0
      expect(statB.matchWins, 0);
      expect(statB.matchLosses, 2);
      expect(statB.customPoints, 0.0);
      expect(statB.rank, 3);
    });
  });
}
