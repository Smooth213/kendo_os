import 'package:kendo_os/shared/domain/entities/player_model.dart';

/// 選手複数選択シート向けのフィルタリング・ソート・検索判定ヘルパー
class MultiPlayerFilterHelper {
  const MultiPlayerFilterHelper._();

  static const List<String> filterCategories = [
    'すべて',
    '初心者',
    '幼年',
    '低学年',
    '高学年',
    '中学生',
    '高校生',
    '一般',
    'ゲスト',
  ];

  /// カテゴリフィルターおよび検索文字列に基づいてマスタ選手リストを絞り込み、ソートして返す
  static List<PlayerModel> filterAndSortMaster({
    required List<PlayerModel> masterPlayers,
    required String searchText,
    required String selectedFilter,
    required bool isAscending,
  }) {
    List<PlayerModel> list = masterPlayers
        .where((p) => p.name.contains(searchText))
        .toList();

    if (selectedFilter != 'すべて') {
      if (selectedFilter == 'ゲスト') {
        list = [];
      } else if (selectedFilter == '初心者') {
        list = list.where((p) => p.isBeginner).toList();
      } else if (selectedFilter == '幼年') {
        list = list.where((p) => p.grade == 0 && !p.isBeginner).toList();
      } else if (selectedFilter == '低学年') {
        list = list
            .where((p) => p.grade >= 1 && p.grade <= 4 && !p.isBeginner)
            .toList();
      } else if (selectedFilter == '高学年') {
        list = list
            .where((p) => p.grade >= 5 && p.grade <= 6 && !p.isBeginner)
            .toList();
      } else if (selectedFilter == '中学生') {
        list = list
            .where((p) => p.grade >= 7 && p.grade <= 9 && !p.isBeginner)
            .toList();
      } else if (selectedFilter == '高校生') {
        list = list
            .where((p) => p.grade >= 10 && p.grade <= 12 && !p.isBeginner)
            .toList();
      } else if (selectedFilter == '一般') {
        list = list.where((p) => p.grade >= 13 && !p.isBeginner).toList();
      } else {
        list = [];
      }
    }

    // 学年順（同一年齢内はよみがな順）でソート（昇順 / 降順）
    list.sort((a, b) {
      final gradeCompare = isAscending
          ? a.grade.compareTo(b.grade)
          : b.grade.compareTo(a.grade);
      if (gradeCompare != 0) return gradeCompare;
      return isAscending
          ? a.nameKana.compareTo(b.nameKana)
          : b.nameKana.compareTo(a.nameKana);
    });

    return list;
  }

  /// ゲスト選手の絞り込み
  static List<String> filterGuests({
    required List<String> guestPlayers,
    required String searchText,
    required String selectedFilter,
  }) {
    if (selectedFilter == 'すべて' || selectedFilter == 'ゲスト') {
      return guestPlayers.where((name) => name.contains(searchText)).toList();
    }
    return <String>[];
  }

  /// 入力された名前がマスタにもゲストにも存在しない新規名前であるかを判定
  static bool isNewName({
    required String searchText,
    required List<PlayerModel> masterPlayers,
    required List<String> guestPlayers,
  }) {
    final trimmed = searchText.trim();
    if (trimmed.isEmpty) return false;
    return !masterPlayers.any((p) => p.name == trimmed) &&
        !guestPlayers.any((name) => name == trimmed);
  }
}
