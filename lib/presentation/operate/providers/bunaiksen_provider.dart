import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';

// 1. ゲスト選手メモリ（手入力された出稽古・ゲスト等の名前を一時記憶）
final bunaiksenGuestProvider = StateProvider<List<String>>((ref) => []);

// 部内戦の基本ルール設定
final bunaiksenRuleProvider = StateProvider<MatchRule>((ref) {
  return const MatchRule(
    matchTimeMinutes: 3,
    enchoTimeMinutes: 0, // 基本延長なし
    isEnchoUnlimited: false,
  );
});

// 3. 無限勝ち抜きキュー（待機列の管理）
class BunaiksenInfiniteQueueNotifier extends StateNotifier<List<String>> {
  BunaiksenInfiniteQueueNotifier() : super([]);

  void setPlayers(List<String> players) {
    state = players; // ★ 追加：待機列を一括で更新する
  }

  void addPlayer(String name) {
    if (!state.contains(name)) {
      state = [...state, name];
    }
  }

  void removePlayer(String name) {
    state = state.where((p) => p != name).toList();
  }

  void moveToLast(String name) {
    final newState = state.where((p) => p != name).toList();
    newState.add(name);
    state = newState;
  }

  void shuffle() {
    final newState = List<String>.from(state)..shuffle();
    state = newState;
  }

  void reorder(int oldIndex, int newIndex) {
    final newState = List<String>.from(state);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = newState.removeAt(oldIndex);
    newState.insert(newIndex, item);
    state = newState;
  }

  String? popFirst() {
    if (state.isEmpty) return null;
    final first = state.first;
    state = state.sublist(1);
    return first;
  }
}

final bunaiksenInfiniteQueueProvider = StateNotifierProvider<BunaiksenInfiniteQueueNotifier, List<String>>((ref) {
  return BunaiksenInfiniteQueueNotifier();
});

// 4. 無限勝ち抜き連勝カウンター（誰が何連勝しているか）
class BunaiksenInfiniteStreakNotifier extends StateNotifier<Map<String, int>> {
  BunaiksenInfiniteStreakNotifier() : super({});

  void incrementStreak(String name) => state = {...state, name: (state[name] ?? 0) + 1};
  void resetStreak(String name) => state = {...state, name: 0};
  void clearAll() => state = {};
}

final bunaiksenInfiniteStreakProvider = StateNotifierProvider<BunaiksenInfiniteStreakNotifier, Map<String, int>>((ref) {
  return BunaiksenInfiniteStreakNotifier();
});

// 5. 部内戦ホームで「表示している日付」を管理するProvider
final bunaiksenViewDateProvider = StateProvider<DateTime>((ref) => DateTime.now());