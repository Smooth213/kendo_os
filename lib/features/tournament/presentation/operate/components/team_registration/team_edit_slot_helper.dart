import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';

/// チーム編集ボトムシート用の選手スロット・ポジション計算ヘルパー
class TeamEditSlotHelper {
  /// 既定のカテゴリ候補
  static const List<String> defaultCandidateCategories = [
    '初心者',
    '幼年',
    '小学生低学年',
    '小学生高学年',
    '小学生',
    '中学生',
    '中学生男子',
    '中学生女子',
    '高校生',
    '一般',
    '混成',
    'その他',
  ];

  /// 試合形式に応じた基準選手数を計算
  static int getBasePlayerCount({
    required String matchType,
    int? slotLength,
    required int registeredPlayerLength,
  }) {
    if (matchType.contains('それ以上')) {
      if (slotLength != null && slotLength > 0) return slotLength;
      return registeredPlayerLength > 8 ? registeredPlayerLength : 8;
    }
    if (matchType.contains('3人制')) return 3;
    if (matchType.contains('個人戦')) return 1;
    if (matchType.contains('7人制')) return 7;
    return 5;
  }

  /// 試合形式と補欠数に応じたポジション名リストを生成
  static List<String> getPosNames({
    required String matchType,
    required int substituteCount,
    required int baseCount,
  }) {
    if (matchType.contains('それ以上')) {
      return MatchFormatSetupHelper.generatePositions(baseCount);
    }
    List<String> base;
    if (matchType.contains('3人制')) {
      base = ['先鋒', '中堅', '大将'];
    } else if (matchType.contains('個人戦')) {
      base = ['選手'];
    } else if (matchType.contains('7人制')) {
      base = ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'];
    } else {
      base = ['先鋒', '次鋒', '中堅', '副将', '大将'];
    }
    for (int i = 0; i < substituteCount; i++) {
      base.add('補欠');
    }
    return base;
  }
}
