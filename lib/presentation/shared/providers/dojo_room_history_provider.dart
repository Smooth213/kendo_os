import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dojoRoomHistoryProvider = StateNotifierProvider<DojoRoomHistoryNotifier, List<String>>((ref) {
  return DojoRoomHistoryNotifier();
});

class DojoRoomHistoryNotifier extends StateNotifier<List<String>> {
  DojoRoomHistoryNotifier() : super([]) {
    _load();
  }

  static const _key = 'kendo_os_dojo_room_history';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getStringList(_key) ?? [];
    } catch (_) {}
  }

  Future<void> addHistory(String roomId) async {
    if (roomId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_key) ?? [];
      history.remove(roomId);
      history.insert(0, roomId);
      if (history.length > 10) history.removeLast(); // 最大10件まで保存
      await prefs.setStringList(_key, history);
      state = history;
    } catch (_) {}
  }

  Future<void> removeHistory(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_key) ?? [];
      history.remove(roomId);
      await prefs.setStringList(_key, history);
      state = history;
    } catch (_) {}
  }
}