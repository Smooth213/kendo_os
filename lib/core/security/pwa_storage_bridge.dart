import 'pwa_storage_stub.dart' if (dart.library.js_interop) 'pwa_storage_web.dart';

/// テスト空間（VM）と本番PWA（Web）のコンパイル境界を直列分離し、
/// 双方の環境で安全にストレージ操作を可能にする環境調停ゲートウェイ。
class PwaStorage {
  static void setItem(String key, String value) => platformStorage.setItem(key, value);
  static String? getItem(String key) => platformStorage.getItem(key);
  static void removeItem(String key) => platformStorage.removeItem(key);
}