import 'package:kendo_os/shared/domain/entities/player_model.dart';

/// 選手マスタ管理画面の学年・部門別グルーピングヘルパー
class MasterPlayerGroupingHelper {
  /// 学年から部門名を取得
  static String getCategoryName(int grade) {
    if (grade == -1) return '初心者の部';
    if (grade == 0) return '幼年の部';
    if (grade >= 1 && grade <= 4) return '小学生低学年の部';
    if (grade >= 5 && grade <= 6) return '小学生高学年の部';
    if (grade >= 7 && grade <= 9) return '中学生の部';
    if (grade >= 10 && grade <= 12) return '高校生の部';
    return '一般の部';
  }

  /// 選手リストをモード（0: 学年別, 1: 部門別）に応じてグループ化
  static Map<String, List<PlayerModel>> groupPlayers({
    required List<PlayerModel> players,
    required int groupingMode,
  }) {
    final Map<String, List<PlayerModel>> groupedPlayers = {};
    if (groupingMode == 0) {
      for (var p in players) {
        groupedPlayers.putIfAbsent(p.gradeName, () => []).add(p);
      }
    } else {
      for (var p in players) {
        final String cat = getCategoryName(p.grade);
        groupedPlayers.putIfAbsent(cat, () => []).add(p);
      }
    }
    return groupedPlayers;
  }
}
