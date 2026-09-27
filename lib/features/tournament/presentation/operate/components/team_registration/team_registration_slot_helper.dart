/// チーム登録画面における選手スロット（補欠・カスタム枠）の追加・削除操作ヘルパー
class TeamRegistrationSlotHelper {
  /// 補欠スロットを削除し、それ以降の選手選択位置を前詰めする
  static void removeSubstitute({
    required int index,
    required int playerCount,
    required Map<int, String> tempSelectedPlayers,
  }) {
    for (int i = index; i < playerCount - 1; i++) {
      if (tempSelectedPlayers.containsKey(i + 1)) {
        tempSelectedPlayers[i] = tempSelectedPlayers[i + 1]!;
      } else {
        tempSelectedPlayers.remove(i);
      }
    }
    tempSelectedPlayers.remove(playerCount - 1);
  }

  /// 7人以上戦での選手スロットを削除し、前詰めする
  static int removePlayerSlot({
    required int index,
    required int playerCount,
    required Map<int, String> tempSelectedPlayers,
    required int customSlotCount,
  }) {
    for (int i = index; i < playerCount - 1; i++) {
      if (tempSelectedPlayers.containsKey(i + 1)) {
        tempSelectedPlayers[i] = tempSelectedPlayers[i + 1]!;
      } else {
        tempSelectedPlayers.remove(i);
      }
    }
    tempSelectedPlayers.remove(playerCount - 1);
    if (customSlotCount > 3) {
      return customSlotCount - 1;
    }
    return customSlotCount;
  }
}
