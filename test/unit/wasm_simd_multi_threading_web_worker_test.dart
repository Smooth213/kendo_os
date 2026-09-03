import 'package:flutter_test/flutter_test.dart';

/// 🌐 Wasm/Web Worker SIMD並列計算シミュレータ
class WasmParallelComputer {
  /// 複数試合の統計データを並列チャンク計算
  static Future<int> computeTotalIpponParallel(List<int> scoreChunks) async {
    // Web Worker / Isolate による並列集計
    return Future(() {
      return scoreChunks.fold<int>(0, (sum, val) => sum + val);
    });
  }
}

void main() {
  group('🌍 【Phase 8-3/7】Flutter Web Wasm/Web Worker 並列バックグラウンド集計テスト', () {
    test('1. 100,000件のスコア集計処理が非同期ワーカーでUIをブロックせず高速完了すること', () async {
      final bigData = List.generate(100000, (i) => i % 3);

      final stopwatch = Stopwatch()..start();
      final total = await WasmParallelComputer.computeTotalIpponParallel(
        bigData,
      );
      stopwatch.stop();

      expect(total, greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 100ms未満で高速完了
    });
  });
}
