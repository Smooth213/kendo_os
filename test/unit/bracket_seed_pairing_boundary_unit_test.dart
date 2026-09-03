import 'package:flutter_test/flutter_test.dart';

/// 剣道大会公式トーナメント シード配置＆同門初戦回避アルゴリズム
class TournamentDrawEngine {
  /// シード番号（1-based）に対する標準的なブラケットスロット番号（1-based, サイズ N）を計算
  /// N は 2の累乗（4, 8, 16, 32, 64, 128）
  static List<int> calculateSeedSlots(int bracketSize) {
    assert(bracketSize >= 2 && (bracketSize & (bracketSize - 1)) == 0);

    List<int> rounds = [1, 2];
    while (rounds.length < bracketSize) {
      final nextRound = <int>[];
      final sum = rounds.length * 2 + 1;
      for (final seed in rounds) {
        nextRound.add(seed);
        nextRound.add(sum - seed);
      }
      rounds = nextRound;
    }
    return rounds;
  }

  /// 選手リストと同門（所属）情報から、同門初戦激突を回避した配置スロットを割り振る
  static List<String> assignSlotsWithClubSeparation({
    required List<({String player, String club})> players,
    required int bracketSize,
  }) {
    final slots = List<String>.filled(bracketSize, '');

    // 所属ごとにグループ化
    final clubGroups = <String, List<String>>{};
    for (final p in players) {
      clubGroups.putIfAbsent(p.club, () => []).add(p.player);
    }

    // 上半分 (0 .. bracketSize ~/ 2 - 1) と 下半分 (bracketSize ~/ 2 .. bracketSize - 1) に分散
    int topIndex = 0;
    int bottomIndex = bracketSize - 1;

    for (final entry in clubGroups.entries) {
      final clubPlayers = entry.value;
      for (int i = 0; i < clubPlayers.length; i++) {
        if (i % 2 == 0) {
          while (topIndex < bracketSize ~/ 2 && slots[topIndex].isNotEmpty) {
            topIndex++;
          }
          if (topIndex < bracketSize ~/ 2) {
            slots[topIndex] = clubPlayers[i];
          } else {
            // 上半分が満杯なら下半分へフォールバック
            while (bottomIndex >= 0 && slots[bottomIndex].isNotEmpty) {
              bottomIndex--;
            }
            if (bottomIndex >= 0) slots[bottomIndex] = clubPlayers[i];
          }
        } else {
          while (bottomIndex >= bracketSize ~/ 2 &&
              slots[bottomIndex].isNotEmpty) {
            bottomIndex--;
          }
          if (bottomIndex >= bracketSize ~/ 2) {
            slots[bottomIndex] = clubPlayers[i];
          } else {
            // 下半分が満杯なら上半分へフォールバック
            while (topIndex < bracketSize && slots[topIndex].isNotEmpty) {
              topIndex++;
            }
            if (topIndex < bracketSize) slots[topIndex] = clubPlayers[i];
          }
        }
      }
    }
    return slots;
  }
}

void main() {
  group('🧪 【Unit 3/5】トーナメントシード配置＆同門初戦回避境界値テスト', () {
    test('1. 8名・16名・32名・128名規模での標準シードスロット配置計算の厳密性', () {
      // 8人トーナメント: 第1シードは前半山、第2シードは後半山
      final slots8 = TournamentDrawEngine.calculateSeedSlots(8);
      expect(slots8.length, 8);
      expect(slots8.first, 1); // 第1シードは最上部スロット
      expect(slots8.indexOf(1) < 4, isTrue);
      expect(slots8.indexOf(2) >= 4, isTrue);

      // 16人トーナメント
      final slots16 = TournamentDrawEngine.calculateSeedSlots(16);
      expect(slots16.length, 16);
      expect(slots16.first, 1);

      // 128人トーナメント（全国大会規模）
      final slots128 = TournamentDrawEngine.calculateSeedSlots(128);
      expect(slots128.length, 128);
      expect(slots128.first, 1);
      expect(slots128.toSet().length, 128, reason: 'スロット番号の重複は絶対にあってはならない');
    });

    test('2. 同門道場選手（同一所属2名〜4名）の初戦激突回避アルゴリズム検証', () {
      final participants = [
        (player: '神武館:佐藤', club: '神武館'),
        (player: '神武館:田中', club: '神武館'),
        (player: '修道館:高橋', club: '修道館'),
        (player: '修道館:伊藤', club: '修道館'),
      ];

      final assigned = TournamentDrawEngine.assignSlotsWithClubSeparation(
        players: participants,
        bracketSize: 4,
      );

      // 上半分 (スロット0, 1) と 下半分 (スロット2, 3)
      final topHalf = [assigned[0], assigned[1]];
      final bottomHalf = [assigned[2], assigned[3]];

      // 神武館の2名が上半分と下半分に完全に分離されていること
      final jinbukanTop = topHalf.where((p) => p.startsWith('神武館')).length;
      final jinbukanBottom = bottomHalf
          .where((p) => p.startsWith('神武館'))
          .length;
      expect(jinbukanTop, 1);
      expect(jinbukanBottom, 1);

      // 修道館の2名も上半分と下半分に分離されていること
      final shudokanTop = topHalf.where((p) => p.startsWith('修道館')).length;
      final shudokanBottom = bottomHalf
          .where((p) => p.startsWith('修道館'))
          .length;
      expect(shudokanTop, 1);
      expect(shudokanBottom, 1);
    });

    test('3. 奇数人数参加時の不戦勝（Bye）スロット配置整合性', () {
      // 3名参加で4枠トーナメント ➔ 1枠は空（Bye）
      final participants = [
        (player: '選手A', club: '道場1'),
        (player: '選手B', club: '道場2'),
        (player: '選手C', club: '道場3'),
      ];

      final assigned = TournamentDrawEngine.assignSlotsWithClubSeparation(
        players: participants,
        bracketSize: 4,
      );

      expect(assigned.length, 4);
      expect(
        assigned.where((s) => s.isEmpty).length,
        1,
        reason: '1枠は不戦勝Byeスロットになること',
      );
      expect(assigned.where((s) => s.isNotEmpty).length, 3);
    });
  });
}
