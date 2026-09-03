import 'package:flutter_test/flutter_test.dart';

/// ⏱️ 単調増加防衛タイマー（Monotonic Clock Guard）
class MonotonicTimerGuard {
  final int totalDurationSeconds;
  int _lastKnownElapsedSeconds = 0;
  DateTime _lastSampledSystemTime;

  MonotonicTimerGuard({
    required this.totalDurationSeconds,
    required DateTime initialSystemTime,
  }) : _lastSampledSystemTime = initialSystemTime;

  /// 新たなOSシステム時刻を受け取って残り時間を計算
  int calculateRemaining(DateTime newSystemTime) {
    if (newSystemTime.isBefore(_lastSampledSystemTime)) {
      // 🚨 タイムトラベル（時計の過去巻き戻し）検知！
      // システム時計の逆流を完全に無視し、前回の経過時間を維持
      return (totalDurationSeconds - _lastKnownElapsedSeconds).clamp(
        0,
        totalDurationSeconds,
      );
    }

    final diff = newSystemTime.difference(_lastSampledSystemTime).inSeconds;
    _lastKnownElapsedSeconds += diff;
    _lastSampledSystemTime = newSystemTime;

    return (totalDurationSeconds - _lastKnownElapsedSeconds).clamp(
      0,
      totalDurationSeconds,
    );
  }

  int get elapsedSeconds => _lastKnownElapsedSeconds;
}

void main() {
  group('☁️ 【Phase 7-3/8】端末時刻巻き戻しタイムトラベル攻撃 単調増加タイマー死守テスト', () {
    test('1. システム時計が過去に巻き戻されても、残り時間が巻き戻らず時間を死守すること', () {
      final t0 = DateTime(2026, 9, 3, 10, 0, 0);
      final timer = MonotonicTimerGuard(
        totalDurationSeconds: 180,
        initialSystemTime: t0,
      );

      // 30秒正常経過
      final t1 = t0.add(const Duration(seconds: 30));
      final rem1 = timer.calculateRemaining(t1);
      expect(rem1, 150); // 残り150秒
      expect(timer.elapsedSeconds, 30);

      // 🚨 ユーザーが手動でOS時計を 1時間前（09:00:00）に巻き戻した！
      final tPast = DateTime(2026, 9, 3, 9, 0, 0);
      final rem2 = timer.calculateRemaining(tPast);

      // 巻き戻しを遮断し、経過30秒（残り150秒）が死守されること！
      expect(rem2, 150);
      expect(timer.elapsedSeconds, 30);
    });
  });
}
