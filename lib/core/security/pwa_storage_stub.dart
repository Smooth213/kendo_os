/// Dart VM / テスト環境用スタブ実装（package:web を一切含まないためエラーが起きない）
class PwaPlatformStorage {
  static final Map<String, String> _memoryStorage = {};

  void setItem(String key, String value) => _memoryStorage[key] = value;
  String? getItem(String key) => _memoryStorage[key];
  void removeItem(String key) => _memoryStorage.remove(key);
}

PwaPlatformStorage get platformStorage => PwaPlatformStorage();
