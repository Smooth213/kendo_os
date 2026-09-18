import 'package:kendo_os/shared/domain/entities/player_model.dart';

/// 🥋 チーム登録 選手選択用 フィルタリング・カテゴリ判定ヘルパー
class TeamRegistrationPlayerFilterHelper {
  const TeamRegistrationPlayerFilterHelper._();

  /// 選手が選択されたカテゴリ（大カテゴリ・小カテゴリ）に適合しているか判定
  static bool isSameCategory({
    required PlayerModel player,
    required String majorCategory,
    required String minorCategory,
  }) {
    if (majorCategory == '初心者') {
      return player.isBeginner;
    } else if (majorCategory == '幼年') {
      return player.grade == 0;
    } else if (majorCategory == '小学生') {
      if (minorCategory == '低学年') {
        return player.grade >= 1 && player.grade <= 4;
      } else if (minorCategory == '高学年') {
        return player.grade >= 5 && player.grade <= 6;
      } else if (minorCategory.contains('年')) {
        final targetGrade =
            int.tryParse(minorCategory.replaceAll('年', '')) ?? 0;
        return player.grade == targetGrade;
      } else {
        return player.grade >= 1 && player.grade <= 6;
      }
    } else if (majorCategory == '中学生') {
      return player.grade >= 7 && player.grade <= 9;
    } else if (majorCategory == '高校生') {
      return player.grade >= 10 && player.grade <= 12;
    } else if (majorCategory == '大学・一般') {
      return player.grade >= 13;
    }
    return true;
  }

  /// 検索クエリとの合致判定（名前・ふりがな）
  static bool matchesQuery({
    required PlayerModel player,
    required String query,
  }) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return player.name.toLowerCase().contains(q) ||
        player.nameKana.toLowerCase().contains(q);
  }

  /// おすすめ選手（同カテゴリ）の一覧取得（50音順ソート済み）
  static List<PlayerModel> getRecommendedPlayers({
    required List<PlayerModel> players,
    required String majorCategory,
    required String minorCategory,
    required String query,
  }) {
    return players
        .where(
          (p) =>
              isSameCategory(
                player: p,
                majorCategory: majorCategory,
                minorCategory: minorCategory,
              ) &&
              matchesQuery(player: p, query: query),
        )
        .toList()
      ..sort((a, b) => a.nameKana.compareTo(b.nameKana));
  }

  /// その他の所属選手の一覧取得（50音順ソート済み）
  static List<PlayerModel> getOtherPlayers({
    required List<PlayerModel> players,
    required String majorCategory,
    required String minorCategory,
    required String query,
  }) {
    return players
        .where(
          (p) =>
              !isSameCategory(
                player: p,
                majorCategory: majorCategory,
                minorCategory: minorCategory,
              ) &&
              matchesQuery(player: p, query: query),
        )
        .toList()
      ..sort((a, b) => a.nameKana.compareTo(b.nameKana));
  }

  /// 現在チーム内にいる手入力選手の抽出
  static List<MapEntry<int, String>> getHelperEntries({
    required Map<int, String> tempSelectedPlayers,
    required List<PlayerModel> players,
    required String query,
  }) {
    return tempSelectedPlayers.entries
        .where((e) => e.value.isNotEmpty && e.value != '欠員')
        .where((e) => !players.any((p) => p.name == e.value))
        .where(
          (e) =>
              query.isEmpty ||
              e.value.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
