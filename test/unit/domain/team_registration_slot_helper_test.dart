import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_slot_helper.dart';

void main() {
  group('[Unit] TeamRegistrationSlotHelper 選手・補欠スロット操作テスト', () {
    test('removeSubstitute: 補欠スロット削除時に後続が正しく前詰めシフトされ、末尾が削除されること', () {
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

    test('removeSubstitute: 末尾スロット削除時の整合性こと', () {
      final selectedPlayers = <int, String>{5: '補欠1', 6: '補欠2'};

      TeamRegistrationSlotHelper.removeSubstitute(
        index: 6,
        playerCount: 7,
        tempSelectedPlayers: selectedPlayers,
      );

      expect(selectedPlayers[5], '補欠1');
      expect(selectedPlayers.containsKey(6), isFalse);
    });

    test('removeSubstitute: 歯抜けスロット（未選択）存在時も安全に削除・シフトできること', () {
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
      'removePlayerSlot: 先頭スロット (index 0) 削除時に後続が正しくシフトされ、customSlotCountが減算されること',
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

    test('removePlayerSlot: 3枠（下限値）ガード機能が働き、3枠未満には減算されないこと', () {
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

    test(
      'resolveBasePlayerCountAndPositions: 剣道形および基本技稽古法でデフォルト役職なし（選手）および選択・入れ替えが正しく返ること',
      () {
        // 日本剣道形（デフォルト: 役職なし）
        final (
          kataCount,
          kataPosDefault,
        ) = TeamRegistrationSlotHelper.resolveBasePlayerCountAndPositions(
          matchType: '日本剣道形（太刀の形3本）',
          tempSelectedPlayers: {},
          customSlotCount: 8,
        );
        expect(kataCount, 2);
        expect(kataPosDefault, ['選手', '選手']);

        // 日本剣道形（選択時: 打太刀・仕太刀）
        final (
          _,
          kataPosSelected,
        ) = TeamRegistrationSlotHelper.resolveBasePlayerCountAndPositions(
          matchType: '日本剣道形（太刀の形3本）',
          tempSelectedPlayers: {},
          customSlotCount: 8,
          kataRoleOption: 'uchidachi_shidachi',
        );
        expect(kataPosSelected, ['打太刀', '仕太刀']);

        // 日本剣道形（入れ替え時: 仕太刀・打太刀）
        final (
          _,
          kataPosReversed,
        ) = TeamRegistrationSlotHelper.resolveBasePlayerCountAndPositions(
          matchType: '日本剣道形（太刀の形3本）',
          tempSelectedPlayers: {},
          customSlotCount: 8,
          kataRoleOption: 'shidachi_uchidachi',
        );
        expect(kataPosReversed, ['仕太刀', '打太刀']);

        // 木刀による剣道基本技稽古法（デフォルト: 役職なし）
        final (
          kihonCount,
          kihonPosDefault,
        ) = TeamRegistrationSlotHelper.resolveBasePlayerCountAndPositions(
          matchType: '木刀による剣道基本技稽古法（5本）',
          tempSelectedPlayers: {},
          customSlotCount: 8,
        );
        expect(kihonCount, 2);
        expect(kihonPosDefault, ['選手', '選手']);

        // 木刀による剣道基本技稽古法（選択時: 元立ち・掛かり手）
        final (
          _,
          kihonPosSelected,
        ) = TeamRegistrationSlotHelper.resolveBasePlayerCountAndPositions(
          matchType: '木刀による剣道基本技稽古法（5本）',
          tempSelectedPlayers: {},
          customSlotCount: 8,
          kataRoleOption: 'motodachi_kakarite',
        );
        expect(kihonPosSelected, ['元立ち', '掛かり手']);

        // 木刀による剣道基本技稽古法（入れ替え時: 掛かり手・元立ち）
        final (
          _,
          kihonPosReversed,
        ) = TeamRegistrationSlotHelper.resolveBasePlayerCountAndPositions(
          matchType: '木刀による剣道基本技稽古法（5本）',
          tempSelectedPlayers: {},
          customSlotCount: 8,
          kataRoleOption: 'kakarite_motodachi',
        );
        expect(kihonPosReversed, ['掛かり手', '元立ち']);

        // 個人戦
        final (
          indivCount,
          indivPos,
        ) = TeamRegistrationSlotHelper.resolveBasePlayerCountAndPositions(
          matchType: '個人戦',
          tempSelectedPlayers: {},
          customSlotCount: 8,
        );
        expect(indivCount, 1);
        expect(indivPos, ['選手']);

        // 団体戦（5人制）
        final (
          dantaiCount,
          dantaiPos,
        ) = TeamRegistrationSlotHelper.resolveBasePlayerCountAndPositions(
          matchType: '団体戦（5人制）',
          tempSelectedPlayers: {},
          customSlotCount: 8,
        );
        expect(dantaiCount, 5);
        expect(dantaiPos, ['先鋒', '次鋒', '中堅', '副将', '大将']);
      },
    );
  });
}
