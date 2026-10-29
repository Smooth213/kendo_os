import 'package:flutter_test/flutter_test.dart';

/// PWAブラウザ環境におけるIndexedDBクォータ制限超過時のフォールバックストレージ
class PwaQuotaFallbackStorage {
  final Map<String, dynamic> _indexedDbMock = {};
  final Map<String, dynamic> _emergencyMemoryBuffer = {};
  bool _quotaExceeded = false;
  final int _quotaLimitBytes = 1024 * 1024; // 1MB制限
  int _currentUsageBytes = 0;

  void triggerQuotaExceeded() {
    _quotaExceeded = true;
  }

  bool get isMemoryFallbackActive => _quotaExceeded;
  int get memoryBufferSize => _emergencyMemoryBuffer.length;

  Future<void> saveMatchData(String key, Map<String, dynamic> data) async {
    final payloadSize = data.toString().length;
    if (_quotaExceeded ||
        (_currentUsageBytes + payloadSize > _quotaLimitBytes)) {
      _quotaExceeded = true;
      // クォータ超過時はクラッシュせずインメモリ退避バッファへ即時退避
      _emergencyMemoryBuffer[key] = Map<String, dynamic>.from(data);
      return;
    }

    _currentUsageBytes += payloadSize;
    _indexedDbMock[key] = Map<String, dynamic>.from(data);
  }

  Map<String, dynamic>? retrieveMatchData(String key) {
    if (_emergencyMemoryBuffer.containsKey(key)) {
      return _emergencyMemoryBuffer[key];
    }
    return _indexedDbMock[key];
  }
}

void main() {
  group('[Unit] PWAブラウザIndexedDBクォータ超過時インメモリ退避テスト', () {
    test('IndexedDB容量枯渇時に例外を握り潰しインメモリバッファへ退避して試合記録を安全に継続すること', () async {
      final storage = PwaQuotaFallbackStorage();

      // 通常書き込み
      await storage.saveMatchData('m_normal', {
        'id': 'm_normal',
        'redScore': 1,
        'whiteScore': 0,
      });

      expect(storage.isMemoryFallbackActive, isFalse);
      expect(storage.retrieveMatchData('m_normal')?['redScore'], 1);

      // クォータ超過シミュレーション
      storage.triggerQuotaExceeded();

      // クォータ超過後の書き込み
      await storage.saveMatchData('m_emergency', {
        'id': 'm_emergency',
        'redScore': 2,
        'whiteScore': 1,
      });

      // メモリ退避が作動しデータが損失なく読み出せること
      expect(storage.isMemoryFallbackActive, isTrue);
      expect(storage.memoryBufferSize, 1);
      expect(storage.retrieveMatchData('m_emergency')?['redScore'], 2);
      expect(storage.retrieveMatchData('m_normal')?['redScore'], 1);
    });
  });
}
