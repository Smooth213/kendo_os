import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

// 1. ゲスト選手メモリ（Firestore上の対象日時の出稽古・ゲスト等の名前をリアルタイム同期）
class BunaiksenGuestNotifier extends StateNotifier<List<String>> {
  final Ref _ref;
  StreamSubscription? _sub;

  BunaiksenGuestNotifier(this._ref) : super([]) {
    _listenToGuests();
  }

  void _listenToGuests() {
    _sub?.cancel();
    final dojoId = _ref.watch(currentDojoIdProvider);
    final viewDate = _ref.watch(bunaiksenViewDateProvider);

    final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
    final dateStr = DateFormat('yyyyMMdd').format(viewDate);
    final targetTournamentId = 'bunaiksen_$dateStr';

    _sub = _ref
        .watch(firestoreProvider)
        .collection('organizations')
        .doc(safeDojoId)
        .collection('tournaments')
        .doc(targetTournamentId)
        .collection('bunaiksen_guests')
        .snapshots()
        .listen((snap) {
          state = snap.docs.map((doc) => doc.data()['name'] as String).toList();
        });
  }

  Future<void> addGuest(String name) async {
    final dojoId = _ref.read(currentDojoIdProvider);
    final viewDate = _ref.read(bunaiksenViewDateProvider);

    final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
    final dateStr = DateFormat('yyyyMMdd').format(viewDate);
    final targetTournamentId = 'bunaiksen_$dateStr';
    final docId = name.trim();
    if (docId.isEmpty) return;

    if (!state.contains(docId)) {
      state = [...state, docId];
    }

    await _ref
        .read(firestoreProvider)
        .collection('organizations')
        .doc(safeDojoId)
        .collection('tournaments')
        .doc(targetTournamentId)
        .collection('bunaiksen_guests')
        .doc(docId)
        .set({'name': name.trim(), 'createdAt': FieldValue.serverTimestamp()});
  }

  void update(List<String> Function(List<String>) fn) {
    final newItems = fn(state);
    for (var name in newItems) {
      if (!state.contains(name)) {
        addGuest(name);
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final bunaiksenGuestProvider =
    StateNotifierProvider<BunaiksenGuestNotifier, List<String>>((ref) {
      return BunaiksenGuestNotifier(ref);
    });

// 部内戦の基本ルール設定
final bunaiksenRuleProvider = StateProvider<MatchRule>((ref) {
  ref.watch(currentDojoIdProvider);
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

final bunaiksenInfiniteQueueProvider =
    StateNotifierProvider<BunaiksenInfiniteQueueNotifier, List<String>>((ref) {
      ref.watch(currentDojoIdProvider);
      return BunaiksenInfiniteQueueNotifier();
    });

// 4. 無限勝ち抜き連勝カウンター（誰が何連勝しているか）
class BunaiksenInfiniteStreakNotifier extends StateNotifier<Map<String, int>> {
  BunaiksenInfiniteStreakNotifier() : super({});

  void incrementStreak(String name) =>
      state = {...state, name: (state[name] ?? 0) + 1};
  void resetStreak(String name) => state = {...state, name: 0};
  void clearAll() => state = {};
}

final bunaiksenInfiniteStreakProvider =
    StateNotifierProvider<BunaiksenInfiniteStreakNotifier, Map<String, int>>((
      ref,
    ) {
      ref.watch(currentDojoIdProvider);
      return BunaiksenInfiniteStreakNotifier();
    });

// 5. 部内戦ホームで「表示している日付」を管理するProvider
final bunaiksenViewDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);
