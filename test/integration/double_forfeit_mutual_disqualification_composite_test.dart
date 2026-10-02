import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';

void main() {
  group('[Unit] 団体戦・リーグ戦 両者不戦敗＆両者同時反則退場 複合整合性テスト', () {
    final now = DateTime(2026, 10, 2, 10, 0);

    test('先鋒両者不戦敗・中堅両者反則退場時において、チーム勝者数・取得本数および代表戦判定が完全整合すること', () {
      // 1. 先鋒: 両者不戦敗（スコア 0-0、勝者なし、引き分け扱い）
      final senpo = MatchModel(
        id: 'senpo_match',
        matchType: '先鋒',
        matchOrder: 1,
        redName: '赤: 先鋒',
        whiteName: '白: 先鋒',
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
        events: [
          ScoreEvent(
            id: 'fusen_r',
            side: Side.red,
            isFusen: true,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'fusen_w',
            side: Side.white,
            isFusen: true,
            timestamp: now,
          ),
        ],
      );

      // 2. 次鋒: 赤が面・小手を決めて2本勝ち (2-0)
      final jiho = MatchModel(
        id: 'jiho_match',
        matchType: '次鋒',
        matchOrder: 2,
        redName: '赤: 次鋒',
        whiteName: '白: 次鋒',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
      );

      // 3. 中堅: 両者反則累積（2-2 引き分け）
      final chuken = MatchModel(
        id: 'chuken_match',
        matchType: '中堅',
        matchOrder: 3,
        redName: '赤: 中堅',
        whiteName: '白: 中堅',
        redScore: 2,
        whiteScore: 2,
        status: 'finished',
      );

      // 4. 副将: 白が面を決めて1本勝ち (0-1)
      final fukusho = MatchModel(
        id: 'fukusho_match',
        matchType: '副将',
        matchOrder: 4,
        redName: '赤: 副将',
        whiteName: '白: 副将',
        redScore: 0,
        whiteScore: 1,
        status: 'finished',
      );

      // 5. 大将: 0-0 引き分け
      final taisho = MatchModel(
        id: 'taisho_match',
        matchType: '大将',
        matchOrder: 5,
        redName: '赤: 大将',
        whiteName: '白: 大将',
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
      );

      final teamMatches = [senpo, jiho, chuken, fukusho, taisho];
      final teamResult = TeamMatchCalculator.calculate(teamMatches);

      // 検証:
      // 赤チーム勝者数: 次鋒のみ (1勝)
      // 白チーム勝者数: 副将のみ (1勝)
      // 赤チーム総本数: 0 + 2 + 2 + 0 + 0 = 4本
      // 白チーム総本数: 0 + 0 + 2 + 1 + 0 = 3本
      // 結果: 勝者数同数（1-1）だが、総本数差（4本 vs 3本）により赤チーム勝利
      expect(teamResult.redWins, 1);
      expect(teamResult.whiteWins, 1);
      expect(teamResult.redPoints, 4);
      expect(teamResult.whitePoints, 3);
      expect(teamResult.allFinished, isTrue);
      expect(teamResult.isTie, isFalse);
      expect(teamResult.teamWinner, 'red');
    });
  });
}
