import 'package:flutter_test/flutter_test.dart';

/// 🛡️ バースト書き込み・DDoSレートリミッター（Token Bucket方式）
class RateLimiter {
  final int maxTokens;
  final Duration refillDuration;
  int _currentTokens;
  DateTime _lastRefillTime;

  RateLimiter({
    this.maxTokens = 20, // 瞬間最大20回
    this.refillDuration = const Duration(seconds: 1),
    DateTime? initialTime,
  }) : _currentTokens = maxTokens,
       _lastRefillTime = initialTime ?? DateTime.now();

  bool tryAcquire(DateTime now) {
    _refill(now);
    if (_currentTokens > 0) {
      _currentTokens--;
      return true; // 許可
    }
    return false; // レート制限により拒絶
  }

  void _refill(DateTime now) {
    if (now.isAfter(_lastRefillTime.add(refillDuration))) {
      _currentTokens = maxTokens;
      _lastRefillTime = now;
    }
  }
}

void main() {
  group('🌐 【Phase 4-7/11】DDoSバースト書き込み連打 レートリミッティングテスト', () {
    test('1. 秒間100回の連続打突リクエストを浴びせても、最大20回で安全に制限されクラッシュしないこと', () {
      final now = DateTime(2026, 9, 3, 10, 0, 0);
      final limiter = RateLimiter(maxTokens: 20, initialTime: now);

      int allowedCount = 0;
      int blockedCount = 0;

      // 同一秒内に100回連続リクエスト
      for (int i = 0; i < 100; i++) {
        if (limiter.tryAcquire(now)) {
          allowedCount++;
        } else {
          blockedCount++;
        }
      }

      // バースト許容量の20回のみ許可され、残りの80回は即座に遮断されること
      expect(allowedCount, 20);
      expect(blockedCount, 80);
    });

    test('2. 1秒経過後にトークンが補充され、再度の操作が正常に許可されること', () {
      final t0 = DateTime(2026, 9, 3, 10, 0, 0);
      final limiter = RateLimiter(maxTokens: 20, initialTime: t0);

      // 20回使い切る
      for (int i = 0; i < 20; i++) {
        limiter.tryAcquire(t0);
      }
      expect(limiter.tryAcquire(t0), isFalse); // 枯渇

      // 1.5秒後（トークン補充）
      final t1 = t0.add(const Duration(milliseconds: 1500));
      expect(limiter.tryAcquire(t1), isTrue); // 再度許可！
    });
  });
}
