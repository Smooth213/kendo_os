import 'package:web/web.dart' as web;

/// Flutter Web / PWA本番環境用の物理永続化ストレージ実体
class PwaPlatformStorage {
  void setItem(String key, String value) => web.window.localStorage.setItem(key, value);
  String? getItem(String key) => web.window.localStorage.getItem(key);
  void removeItem(String key) => web.window.localStorage.removeItem(key);
}

PwaPlatformStorage get platformStorage => PwaPlatformStorage();