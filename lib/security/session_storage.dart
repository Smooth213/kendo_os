import 'dart:convert';
import 'pwa_storage_bridge.dart';
import '../../domain/entities/user_session.dart';

/// 認証セッションをPWA環境へ安全に永続化・復元するインフラストレージ。
class SessionStorage {
  static const String _storageKey = 'kendo_os_auth_session';

  static void save(UserSession session) {
    try {
      final jsonStr = jsonEncode(session.toJson());
      PwaStorage.setItem(_storageKey, jsonStr);
    } catch (_) {}
  }

  static UserSession? load() {
    try {
      final jsonStr = PwaStorage.getItem(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      final session = UserSession.fromJson(map);

      if (session.sessionVersion != 1 || session.isExpired) {
        clear();
        return null;
      }
      return session;
    } catch (_) {
      clear();
      return null;
    }
  }

  static void clear() {
    try {
      PwaStorage.removeItem(_storageKey);
    } catch (_) {}
  }
}
