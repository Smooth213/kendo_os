import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';

void main() {
  group('🥋 【Unit】多人数団体戦 極限境界値・タイブレーク・不戦勝混在テスト', () {
    MatchModel createFinishedMatch({
      required String id,
      required int redScore,
      required int whiteScore,
      String matchType = '団体戦',
      int? matchOrder,
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

    test('1. 7人制・9人制・11人制・21人制: 全ポジション引き分け(0-0)時の完全同点判定と代表戦フラグ判定', () {
      final playerCounts = [7, 9, 11, 21];

      for (final count in playerCounts) {
        final matches = List.generate(
          count,
          (i) => createFinishedMatch(
            id: 'm_${count}_$i',
            matchOrder: i + 1,
            redScore: 0,
            whiteScore: 0,
          ),
        );

        final result = TeamMatchCalculator.calculate(matches);

        expect(result.allFinished, isTrue, reason: '$count人制: 全試合終了判定');
        expect(result.redWins, 0, reason: '$count人制: 赤勝者数ゼロ');
        expect(result.whiteWins, 0, reason: '$count人制: 白勝者数ゼロ');
        expect(result.redPoints, 0, reason: '$count人制: 赤本数ゼロ');
        expect(result.whitePoints, 0, reason: '$count人制: 白本数ゼロ');
        expect(result.isTie, isTrue, reason: '$count人制: 代表戦前の完全同点判定');
        expect(result.hasDaihyo, isFalse);
        expect(result.teamWinner, 'draw');

        // 代表戦を追加した場合の決着判定
        final matchesWithDaihyo = [
          ...matches,
          createFinishedMatch(
            id: 'm_${count}_daihyo',
            redScore: 1,
            whiteScore: 0,
            matchType: '代表戦',
          ),
        ];

        final resultDaihyo = TeamMatchCalculator.calculate(matchesWithDaihyo);
        expect(resultDaihyo.hasDaihyo, isTrue);
        expect(resultDaihyo.isTie, isFalse);
        expect(resultDaihyo.teamWinner, 'red', reason: '代表戦で赤が1本取得し勝利');
      }
    });

    test('2. 偶数制（6人制・8人制・10人制）: 勝者数同数・総本数同点時のタイブレークアルゴリズム', () {
      final sixMatches = [
        createFinishedMatch(id: 's1', redScore: 2, whiteScore: 0),
        createFinishedMatch(id: 's2', redScore: 0, whiteScore: 2),
        createFinishedMatch(id: 's3', redScore: 1, whiteScore: 0),
        createFinishedMatch(id: 's4', redScore: 0, whiteScore: 1),
        createFinishedMatch(id: 's5', redScore: 0, whiteScore: 0),
        createFinishedMatch(id: 's6', redScore: 0, whiteScore: 0),
      ];

      final sixResult = TeamMatchCalculator.calculate(sixMatches);
      expect(sixResult.redWins, 2);
      expect(sixResult.whiteWins, 2);
      expect(sixResult.redPoints, 3);
      expect(sixResult.whitePoints, 3);
      expect(sixResult.isTie, isTrue);
      expect(sixResult.teamWinner, 'draw');

      // 8人制: 勝者数同数だが総本数差で決着
      // 赤 3勝 (4本), 白 3勝 (3本), 2分
      final eightMatches = [
        createFinishedMatch(id: 'e1', redScore: 2, whiteScore: 0),
        createFinishedMatch(id: 'e2', redScore: 1, whiteScore: 0),
        createFinishedMatch(id: 'e3', redScore: 1, whiteScore: 0),
        createFinishedMatch(id: 'e4', redScore: 0, whiteScore: 1),
        createFinishedMatch(id: 'e5', redScore: 0, whiteScore: 1),
        createFinishedMatch(id: 'e6', redScore: 0, whiteScore: 1),
        createFinishedMatch(id: 'e7', redScore: 0, whiteScore: 0),
        createFinishedMatch(id: 'e8', redScore: 0, whiteScore: 0),
      ];

      final eightResult = TeamMatchCalculator.calculate(eightMatches);
      expect(eightResult.redWins, 3);
      expect(eightResult.whiteWins, 3);
      expect(eightResult.redPoints, 4);
      expect(eightResult.whitePoints, 3);
      expect(eightResult.isTie, isFalse);
      expect(eightResult.teamWinner, 'red', reason: '勝者数同数、本数差(4>3)で赤勝利');

      // 10人制: 勝者数差で決着
      // 赤 4勝 (4本), 白 3勝 (5本) -> 勝者数優先原則により赤勝利
      final tenMatches = [
        createFinishedMatch(id: 't1', redScore: 1, whiteScore: 0),
        createFinishedMatch(id: 't2', redScore: 1, whiteScore: 0),
        createFinishedMatch(id: 't3', redScore: 1, whiteScore: 0),
        createFinishedMatch(id: 't4', redScore: 1, whiteScore: 0),
        createFinishedMatch(id: 't5', redScore: 0, whiteScore: 2),
        createFinishedMatch(id: 't6', redScore: 0, whiteScore: 2),
        createFinishedMatch(id: 't7', redScore: 0, whiteScore: 1),
        createFinishedMatch(id: 't8', redScore: 0, whiteScore: 0),
        createFinishedMatch(id: 't9', redScore: 0, whiteScore: 0),
        createFinishedMatch(id: 't10', redScore: 0, whiteScore: 0),
      ];

      final tenResult = TeamMatchCalculator.calculate(tenMatches);
      expect(tenResult.redWins, 4);
      expect(tenResult.whiteWins, 3);
      expect(tenResult.redPoints, 4);
      expect(tenResult.whitePoints, 5);
      expect(tenResult.isTie, isFalse);
      expect(tenResult.teamWinner, 'red', reason: '勝者数(4>3)が本数(4<5)より優先される');
    });

    test('3. 不戦勝(2-0)と不戦敗(0-2)が複数ポジションで交錯した場合の総本数・勝者数計算', () {
      final matches = [
        createFinishedMatch(id: 'f1', redScore: 2, whiteScore: 0),
        createFinishedMatch(id: 'f2', redScore: 0, whiteScore: 2),
        createFinishedMatch(id: 'f3', redScore: 2, whiteScore: 0),
        createFinishedMatch(id: 'f4', redScore: 1, whiteScore: 2),
        createFinishedMatch(id: 'f5', redScore: 0, whiteScore: 0),
        createFinishedMatch(id: 'f6', redScore: 0, whiteScore: 2),
        createFinishedMatch(id: 'f7', redScore: 2, whiteScore: 0),
      ];

      final result = TeamMatchCalculator.calculate(matches);

      expect(result.redWins, 3);
      expect(result.whiteWins, 3);
      expect(result.redPoints, 7);
      expect(result.whitePoints, 6);
      expect(result.isTie, isFalse);
      expect(result.teamWinner, 'red', reason: '勝者数同数(3=3)だが総本数(7>6)で赤チーム勝利');
    });

    test('4. 試合途中のステータス混在時: in_progress と allFinished=false の正確性', () {
      final matches = [
        createFinishedMatch(id: 'p1', redScore: 2, whiteScore: 0),
        const MatchModel(
          id: 'p2',
          matchType: '団体戦',
          redName: '赤選手',
          whiteName: '白選手',
          status: 'in_progress',
        ),
      ];

      final result = TeamMatchCalculator.calculate(matches);
      expect(result.allFinished, isFalse);
      expect(result.teamWinner, 'in_progress');
      expect(result.isTie, isFalse);
    });
  });
}
