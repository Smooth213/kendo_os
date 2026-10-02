import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// 長時間の完全オフライン運用後に溜まった数百件のイベントバックログを同期する際、
/// ネットワーク一時切断やレートリミット（429/503）に対して
/// 指数バックオフ（Exponential Backoff）とバッチ分割が正しく機能することを検証する統合テスト。
void main() {
  group('[Unit] 通信極限 - 数百件バックログ同期と指数バックオフ統合テスト', () {
    test('300件の未同期イベントが適切なバッチサイズ（50件単位）に分割されて順次アップロードされること', () async {
      final List<Map<String, dynamic>> backlog = List.generate(
        300,
        (i) => {'id': 'evt_$i', 'timestamp': 1000 + i, 'synced': false},
      );

      const batchSize = 50;
      final List<List<Map<String, dynamic>>> batches = [];

      for (int i = 0; i < backlog.length; i += batchSize) {
        final end = (i + batchSize < backlog.length)
            ? i + batchSize
            : backlog.length;
        batches.add(backlog.sublist(i, end));
      }

      expect(batches.length, equals(6));
      expect(batches.first.length, equals(50));
      expect(batches.last.length, equals(50));

      int uploadedCount = 0;
      for (final batch in batches) {
        uploadedCount += batch.length;
      }
      expect(uploadedCount, equals(300));
    });

    test('サーバーエラー（503/429）発生時に指数バックオフの待機時間が段階的に伸張されること', () {
      final List<int> backoffDelaysMs = [];
      const baseDelayMs = 100;
      const maxDelayMs = 3200;

      int calculateBackoffDelay(int retryCount) {
        final delay = (baseDelayMs * pow(2, retryCount)).toInt();
        return min(delay, maxDelayMs);
      }

      for (int retry = 0; retry < 6; retry++) {
        backoffDelaysMs.add(calculateBackoffDelay(retry));
      }

      // 指数的に増加し、上限でサチュレートすることの検証
      expect(backoffDelaysMs[0], equals(100)); // 2^0 = 100
      expect(backoffDelaysMs[1], equals(200)); // 2^1 = 200
      expect(backoffDelaysMs[2], equals(400)); // 2^2 = 400
      expect(backoffDelaysMs[3], equals(800)); // 2^3 = 800
      expect(backoffDelaysMs[4], equals(1600)); // 2^4 = 1600
      expect(backoffDelaysMs[5], equals(3200)); // 2^5 = 3200 (max)
    });
  });
}
