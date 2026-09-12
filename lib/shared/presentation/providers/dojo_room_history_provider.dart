import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/auth/application/user_data_cloud_sync_manager.dart';

final dojoRoomHistoryProvider =
    StateNotifierProvider<DojoRoomHistoryNotifier, List<String>>((ref) {
      return DojoRoomHistoryNotifier(ref);
    });

class DojoRoomHistoryNotifier extends StateNotifier<List<String>> {
  DojoRoomHistoryNotifier([this._ref]) : super([]) {
    _load();
  }

  final Ref? _ref;
  static const _key = 'kendo_os_dojo_room_history';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getStringList(_key) ?? [];
    } catch (_) {}
  }

  /// クラウドからの履歴データをローカル履歴とスマートマージ
  Future<void> mergeCloudHistory(List<String> cloudList) async {
    if (cloudList.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final localHistory = prefs.getStringList(_key) ?? state;
      final merged = <String>[...localHistory];
      for (final item in cloudList) {
        if (!merged.contains(item) && item.trim().isNotEmpty) {
          merged.add(item);
        }
      }
      if (merged.length > 10) {
        merged.removeRange(10, merged.length);
      }
      await prefs.setStringList(_key, merged);
      state = merged;
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
      _ref
          ?.read(userDataCloudSyncManagerProvider)
          .pushDojoHistoryToCloud(state);
    } catch (_) {}
  }

  Future<void> removeHistory(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_key) ?? [];
      history.remove(roomId);
      await prefs.setStringList(_key, history);
      state = history;
      _ref
          ?.read(userDataCloudSyncManagerProvider)
          .pushDojoHistoryToCloud(state);
    } catch (_) {}
  }
}
