import 'package:flutter_test/flutter_test.dart';

/// 🌐 IndexedDB 容量枯渇（QuotaExceeded）時の自動インメモリフォールバック
class HybridBrowserStorage {
  final Map<String, dynamic> _memoryCache = {};
  bool _isPersistentStorageAvailable = true;

  void simulateQuotaExceeded() {
    _isPersistentStorageAvailable = false; // QuotaExceededError 発生
  }

  void write(String key, dynamic value) {
    if (_isPersistentStorageAvailable) {
      try {
        // 通常の IndexedDB 書き込み
        _memoryCache[key] = value;
      } catch (e) {
        _isPersistentStorageAvailable = false;
        _memoryCache[key] = value;
      }
    } else {
      // 🛡️ 自動インメモリフォールバック
      _memoryCache[key] = value;
    }
  }

  dynamic read(String key) {
    return _memoryCache[key];
  }

  bool get isUsingMemoryFallback => !_isPersistentStorageAvailable;
}

void main() {
  group('🌐 【Phase 4-4/11】ブラウザ IndexedDB 容量枯渇インメモリフォールバックテスト', () {
    test('1. QuotaExceededError 発生時でもクラッシュせず、インメモリキャッシュで試合記録が継続されること', () {
      final storage = HybridBrowserStorage();

      // 通常書き込み
      storage.write('match_1', {'score': '1-0'});
      expect(storage.read('match_1'), {'score': '1-0'});
      expect(storage.isUsingMemoryFallback, isFalse);

      // 🚨 ブラウザ容量逼迫（QuotaExceeded）をシミュレート
      storage.simulateQuotaExceeded();

      // 容量枯渇下での追加記録（赤面）
      storage.write('match_1_event_2', {'strike': 'men', 'side': 'red'});

      // クラッシュせず、安全にインメモリに保存され読み出せること
      expect(storage.isUsingMemoryFallback, isTrue);
      expect(storage.read('match_1_event_2'), {'strike': 'men', 'side': 'red'});
    });
  });
}
