import 'dart:convert';
import 'package:web/web.dart' as web;
import 'package:kendo_os/shared/domain/entities/user_session.dart';

/// プロバイダー内部への直書きを禁止し、PWAの localStorage 永続化処理を隠蔽・一元統治する。
class SessionStorage {
  static const String _storageKey = 'kendo_os_auth_session';

  /// セッションオブジェクトを暗号化/シリアライズして安全にローカルストレージへ永続化
  static void save(UserSession session) {
    try {
      final jsonStr = jsonEncode(session.toJson());
      web.window.localStorage.setItem(_storageKey, jsonStr);
    } catch (_) {
      // 体育館端末のブラウザシークレットモード等による書き込み制限時はメモリ上でのみ維持
    }
  }

  /// ストレージからセッションを安全に復元する（データ改ざんや破損、未存在時は null を返す）
  static UserSession? load() {
    try {
      final jsonStr = web.window.localStorage.getItem(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      final session = UserSession.fromJson(map);

      // 改ざん・バージョン不一致、または期限切れのデータは水際でパージ
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

  /// ログアウト時や期限切れ時にローカルストレージを完全消去
  static void clear() {
    try {
      web.window.localStorage.removeItem(_storageKey);
    } catch (_) {}
  }
}
