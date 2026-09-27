import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_slot_helper.dart';

void main() {
  group('🥋 【Unit】TeamRegistrationSlotHelper 選手・補欠スロット操作テスト', () {
    test('1. removeSubstitute: 補欠スロット削除時に後続が正しく前詰めシフトされ、末尾が削除されること', () {
      final selectedPlayers = <int, String>{5: '補欠1', 6: '補欠2', 7: '補欠3'};

      // 補欠1 (index 5) を削除（playerCount = 8）
      TeamRegistrationSlotHelper.removeSubstitute(
        index: 5,
        playerCount: 8,
        tempSelectedPlayers: selectedPlayers,
      );

      // index 5 に元の index 6 ('補欠2') が入り、index 6 に元の index 7 ('補欠3') が入る
      expect(selectedPlayers[5], '補欠2');
      expect(selectedPlayers[6], '補欠3');
      expect(selectedPlayers.containsKey(7), isFalse);
    });

    test('2. removeSubstitute: 末尾スロット削除時の整合性', () {
      final selectedPlayers = <int, String>{5: '補欠1', 6: '補欠2'};

      TeamRegistrationSlotHelper.removeSubstitute(
        index: 6,
        playerCount: 7,
        tempSelectedPlayers: selectedPlayers,
      );

      expect(selectedPlayers[5], '補欠1');
      expect(selectedPlayers.containsKey(6), isFalse);
    });

    test('3. removeSubstitute: 歯抜けスロット（未選択）存在時も安全に削除・シフトできること', () {
      final selectedPlayers = <int, String>{
        5: '補欠1',
        // index 6 は空欄
        7: '補欠3',
      };

      TeamRegistrationSlotHelper.removeSubstitute(
        index: 5,
        playerCount: 8,
        tempSelectedPlayers: selectedPlayers,
      );

      // index 5 は空欄になり、index 6 に '補欠3' がシフトされる
      expect(selectedPlayers.containsKey(5), isFalse);
      expect(selectedPlayers[6], '補欠3');
      expect(selectedPlayers.containsKey(7), isFalse);
    });

    test(
      '4. removePlayerSlot: 先頭スロット (index 0) 削除時に後続が正しくシフトされ、customSlotCountが減算されること',
      () {
        final selectedPlayers = <int, String>{
          0: '先鋒選手',
          1: '次鋒選手',
          2: '中堅選手',
          3: '副将選手',
          4: '大将選手',
        };

        final newCount = TeamRegistrationSlotHelper.removePlayerSlot(
          index: 0,
          playerCount: 5,
          tempSelectedPlayers: selectedPlayers,
          customSlotCount: 5,
        );

        expect(newCount, 4);
        expect(selectedPlayers[0], '次鋒選手');
        expect(selectedPlayers[1], '中堅選手');
        expect(selectedPlayers[2], '副将選手');
        expect(selectedPlayers[3], '大将選手');
        expect(selectedPlayers.containsKey(4), isFalse);
      },
    );

    test('5. removePlayerSlot: 3枠（下限値）ガード機能が働き、3枠未満には減算されないこと', () {
      final selectedPlayers = <int, String>{0: '先鋒', 1: '中堅', 2: '大将'};

      final newCount = TeamRegistrationSlotHelper.removePlayerSlot(
        index: 1,
        playerCount: 3,
        tempSelectedPlayers: selectedPlayers,
        customSlotCount: 3,
      );

      // 3枠以下の場合は減算されず 3 のまま
      expect(newCount, 3);
      expect(selectedPlayers[0], '先鋒');
      expect(selectedPlayers[1], '大将');
      expect(selectedPlayers.containsKey(2), isFalse);
    });
  });
}
