import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';

/// チーム登録画面における選手スロット（補欠・カスタム枠）の追加・削除操作ヘルパー
class TeamRegistrationSlotHelper {
  /// 試合形式に応じた基準人数とポジション名リストを決定
  static (int, List<String>) resolveBasePlayerCountAndPositions({
    required String matchType,
    required Map<int, String> tempSelectedPlayers,
    required int customSlotCount,
    String kataRoleOption = 'none',
  }) {
    if (matchType.contains('3人制')) {
      return (3, ['先鋒', '中堅', '大将']);
    }
    if (matchType.contains('個人戦')) {
      return (1, ['選手']);
    }
    if (matchType.contains('7人制')) {
      return (7, ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将']);
    }
    if (matchType.contains('形') || matchType.contains('稽古法')) {
      switch (kataRoleOption) {
        case 'uchidachi_shidachi':
          return (2, ['打太刀', '仕太刀']);
        case 'shidachi_uchidachi':
          return (2, ['仕太刀', '打太刀']);
        case 'motodachi_kakarite':
          return (2, ['元立ち', '掛かり手']);
        case 'kakarite_motodachi':
          return (2, ['掛かり手', '元立ち']);
        case 'none':
        default:
          return (2, ['選手', '選手']);
      }
    }
    if (matchType.contains('それ以上')) {
      int maxIndex = -1;
      for (final k in tempSelectedPlayers.keys) {
        if (k > maxIndex) maxIndex = k;
      }
      final count = (maxIndex + 1 > customSlotCount)
          ? (maxIndex + 1)
          : customSlotCount;
      return (count, MatchFormatSetupHelper.generatePositions(count));
    }
    return (5, ['先鋒', '次鋒', '中堅', '副将', '大将']);
  }

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
