import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🥋 選択されたカテゴリーフィルター（null の場合は「すべて」）
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// 🥋 アコーディオン一括開閉フラグ（true: 全開, false: 全閉）
final timelineAllExpandedProvider = StateProvider<bool>((ref) => false);

/// 🥋 一括開閉時のKey再構築用バージョンカウンター
final timelineExpansionVersionProvider = StateProvider<int>((ref) => 0);

/// 🥋 各グループごとの個別開閉状態マップ（グループID -> 開閉状態）
class TimelineGroupExpansionNotifier extends StateNotifier<Map<String, bool>> {
  TimelineGroupExpansionNotifier() : super({});

  void toggleGroup(String groupId, bool currentState) {
    state = {...state, groupId: !currentState};
  }

  void setGroup(String groupId, bool isExpanded) {
    state = {...state, groupId: isExpanded};
  }

  void setAll(List<String> groupIds, bool isExpanded) {
    final newMap = <String, bool>{};
    for (final id in groupIds) {
      newMap[id] = isExpanded;
    }
    state = newMap;
  }
}

final timelineGroupExpansionMapProvider =
    StateNotifierProvider<TimelineGroupExpansionNotifier, Map<String, bool>>(
      (ref) => TimelineGroupExpansionNotifier(),
    );
