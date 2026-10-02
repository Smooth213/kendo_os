import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';

void main() {
  group('[Unit] 多人数団体戦不戦勝判定およびタイブレーク決定論テスト', () {
    MatchModel createFinishedMatch({
      required String id,
      required int redScore,
      required int whiteScore,
      String matchType = '団体戦',
      int? matchOrder,
      bool isFusen = false,
    }) {
      return MatchModel(
        id: id,
        matchType: matchType,
        matchOrder: matchOrder,
        redName: '赤選手',
        whiteName: '白選手',
        redScore: redScore,
        whiteScore: whiteScore,
        status: 'finished',
      );
    }

    test('7人制団体戦で不戦勝と引き分けが混在し勝者数および総本数同点から代表戦で決着すること', () {
      // 7人制:
      // ポジション1: 赤の不戦勝 (2-0)
      // ポジション2: 白の不戦勝 (0-2)
      // ポジション3: 赤の通常一本勝ち (1-0)
      // ポジション4: 白の通常一本勝ち (0-1)
      // ポジション5: 引き分け (0-0)
      // ポジション6: 引き分け (1-1)
      // ポジション7: 引き分け (0-0)
      // 合計: 勝者数 赤2 - 白2、取得本数 赤4 - 白4 ➔ 同点で代表戦突入
      final matches = [
        createFinishedMatch(
          id: 'm7_1',
          matchOrder: 1,
          redScore: 2,
          whiteScore: 0,
          isFusen: true,
        ),
        createFinishedMatch(
          id: 'm7_2',
          matchOrder: 2,
          redScore: 0,
          whiteScore: 2,
          isFusen: true,
        ),
        createFinishedMatch(
          id: 'm7_3',
          matchOrder: 3,
          redScore: 1,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm7_4',
          matchOrder: 4,
          redScore: 0,
          whiteScore: 1,
        ),
        createFinishedMatch(
          id: 'm7_5',
          matchOrder: 5,
          redScore: 0,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm7_6',
          matchOrder: 6,
          redScore: 1,
          whiteScore: 1,
        ),
        createFinishedMatch(
          id: 'm7_7',
          matchOrder: 7,
          redScore: 0,
          whiteScore: 0,
        ),
      ];

      final result = TeamMatchCalculator.calculate(matches);
      expect(result.allFinished, isTrue);
      expect(result.redWins, 2);
      expect(result.whiteWins, 2);
      expect(result.redPoints, 4);
      expect(result.whitePoints, 4);
      expect(result.isTie, isTrue);
      expect(result.hasDaihyo, isFalse);
      expect(result.teamWinner, 'draw');

      // 代表戦で赤が1本勝ち
      final matchesWithDaihyo = [
        ...matches,
        createFinishedMatch(
          id: 'm7_daihyo',
          matchType: '代表戦',
          redScore: 1,
          whiteScore: 0,
        ),
      ];
      final daihyoResult = TeamMatchCalculator.calculate(matchesWithDaihyo);
      expect(daihyoResult.hasDaihyo, isTrue);
      expect(daihyoResult.isTie, isFalse);
      expect(daihyoResult.teamWinner, 'red');
    });

    test('9人制および11人制団体戦で複数不戦勝が重なった場合に正確な勝者数と取得本数で勝敗が決定すること', () {
      // 9人制: 赤が不戦勝2回(2-0, 2-0)、白が通常勝ち3回(0-1, 0-1, 0-1)、残り引き分け
      // 赤: 勝者数2, 取得本数4
      // 白: 勝者数3, 取得本数3
      // 剣道公式ルール: 勝者数優先のため 白の勝ち（3勝対2勝）
      final matches9 = [
        createFinishedMatch(
          id: 'm9_1',
          matchOrder: 1,
          redScore: 2,
          whiteScore: 0,
          isFusen: true,
        ),
        createFinishedMatch(
          id: 'm9_2',
          matchOrder: 2,
          redScore: 2,
          whiteScore: 0,
          isFusen: true,
        ),
        createFinishedMatch(
          id: 'm9_3',
          matchOrder: 3,
          redScore: 0,
          whiteScore: 1,
        ),
        createFinishedMatch(
          id: 'm9_4',
          matchOrder: 4,
          redScore: 0,
          whiteScore: 1,
        ),
        createFinishedMatch(
          id: 'm9_5',
          matchOrder: 5,
          redScore: 0,
          whiteScore: 1,
        ),
        createFinishedMatch(
          id: 'm9_6',
          matchOrder: 6,
          redScore: 0,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm9_7',
          matchOrder: 7,
          redScore: 0,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm9_8',
          matchOrder: 8,
          redScore: 0,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm9_9',
          matchOrder: 9,
          redScore: 0,
          whiteScore: 0,
        ),
      ];

      final res9 = TeamMatchCalculator.calculate(matches9);
      expect(res9.redWins, 2);
      expect(res9.whiteWins, 3);
      expect(res9.redPoints, 4);
      expect(res9.whitePoints, 3);
      expect(res9.teamWinner, 'white');
      expect(res9.isTie, isFalse);

      // 11人制: 不戦勝と二本勝ちが並び勝者数同数で総本数差により赤が勝利すること
      final matches11 = [
        createFinishedMatch(
          id: 'm11_1',
          matchOrder: 1,
          redScore: 2,
          whiteScore: 0,
          isFusen: true,
        ),
        createFinishedMatch(
          id: 'm11_2',
          matchOrder: 2,
          redScore: 2,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm11_3',
          matchOrder: 3,
          redScore: 0,
          whiteScore: 2,
          isFusen: true,
        ),
        createFinishedMatch(
          id: 'm11_4',
          matchOrder: 4,
          redScore: 0,
          whiteScore: 1,
        ),
        createFinishedMatch(
          id: 'm11_5',
          matchOrder: 5,
          redScore: 1,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm11_6',
          matchOrder: 6,
          redScore: 0,
          whiteScore: 1,
        ),
        createFinishedMatch(
          id: 'm11_7',
          matchOrder: 7,
          redScore: 0,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm11_8',
          matchOrder: 8,
          redScore: 0,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm11_9',
          matchOrder: 9,
          redScore: 0,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm11_10',
          matchOrder: 10,
          redScore: 0,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm11_11',
          matchOrder: 11,
          redScore: 0,
          whiteScore: 0,
        ),
      ];
      // 赤: m11_1(勝,2点), m11_2(勝,2点), m11_5(勝,1点) => 3勝, 5本
      // 白: m11_3(勝,2点), m11_4(勝,1点), m11_6(勝,1点) => 3勝, 4本
      // 勝者数同数(3対3) ➔ 総本数差 (5対4) で赤の勝ち
      final res11 = TeamMatchCalculator.calculate(matches11);
      expect(res11.redWins, 3);
      expect(res11.whiteWins, 3);
      expect(res11.redPoints, 5);
      expect(res11.whitePoints, 4);
      expect(res11.teamWinner, 'red');
      expect(res11.isTie, isFalse);
    });
  });
}
