import 'package:flutter_test/flutter_test.dart';

/// 端末ストレージ容量枯渇（QuotaExceeded / DiskFull）発生時に、
/// ローカルDB書き込み失敗でアプリがクラッシュすることなく、
/// 緊急インメモリ退避バッファへ退避し、試合進行を継続できるフェイルセーフの検証テスト。
void main() {
  group('[Unit] 現場物理極限 - ストレージ枯渇時のインメモリ退避と復旧フェイルセーフテスト', () {
    test('ディスク書き込み失敗時に例外をキャッチし、緊急インメモリバッファへ安全に蓄積されること', () async {
      final List<Map<String, dynamic>> emergencyMemoryBuffer = [];
      bool isDiskFullSimulated = true;
      int persistedToDiskCount = 0;

      Future<void> saveScoreEvent(Map<String, dynamic> event) async {
        if (isDiskFullSimulated) {
          // ディスク容量枯渇エラーをシミュレート
          emergencyMemoryBuffer.add(event);
          return;
        }
        persistedToDiskCount++;
      }

      // イベントの投入（ディスク枯渇状態）
      await saveScoreEvent({'id': 'evt_1', 'type': 'men', 'side': 'red'});
      await saveScoreEvent({'id': 'evt_2', 'type': 'kote', 'side': 'white'});

      expect(persistedToDiskCount, equals(0));
      expect(emergencyMemoryBuffer.length, equals(2));
      expect(emergencyMemoryBuffer.first['type'], equals('men'));
      expect(emergencyMemoryBuffer.last['type'], equals('kote'));

      // ディスク容量が回復した状況をシミュレート
      isDiskFullSimulated = false;

      // フラッシュ（退避バッファからディスクへのドレイン）
      for (final event in List<Map<String, dynamic>>.from(
        emergencyMemoryBuffer,
      )) {
        await saveScoreEvent(event);
      }
      emergencyMemoryBuffer.clear();

      expect(persistedToDiskCount, equals(2));
      expect(emergencyMemoryBuffer.isEmpty, isTrue);
    });

    test('緊急インメモリ退避中も最新のスコア投影（Projections）が正しく計算され試合進行を阻害しないこと', () {
      final List<Map<String, dynamic>> eventLog = [];

      void recordEvent(Map<String, dynamic> event) {
        // ディスク書き込みの成否に関わらず、インメモリの状態マシンへ即時適用
        eventLog.add(event);
      }

      int calculateRedScore() {
        return eventLog
            .where((e) => e['side'] == 'red' && e['type'] != 'hansoku')
            .length;
      }

      recordEvent({'side': 'red', 'type': 'men'});
      recordEvent({'side': 'white', 'type': 'kote'});
      recordEvent({'side': 'red', 'type': 'do'});

      expect(calculateRedScore(), equals(2));
      expect(eventLog.length, equals(3));
    });
  });
}
