import 'package:flutter_test/flutter_test.dart';

/// OS低電力モード、CPUサーマルスロットリング、バックグラウンドサスペンド時における
/// タイマーの絶対時刻ベース（TimeSource / DateTime差分）の計算精度検証テスト。
void main() {
  group('[Unit] 現場物理極限 - 低電力モード・CPUスロットリング環境下でのタイマー精度検証テスト', () {
    test('UIスレッドが5秒間フリーズまたは間引かれても、絶対時間差分により経過時間が正確に復元されること', () {
      final startTime = DateTime(2026, 10, 2, 10, 0, 0);
      const totalMatchDurationSeconds = 240; // 4分

      // 試合開始
      DateTime currentTime = startTime;

      int calculateRemainingSeconds(
        DateTime start,
        DateTime now,
        int accumulatedPauseMs,
      ) {
        final elapsedMs =
            now.difference(start).inMilliseconds - accumulatedPauseMs;
        final remainingMs = (totalMatchDurationSeconds * 1000) - elapsedMs;
        if (remainingMs <= 0) return 0;
        return (remainingMs / 1000).ceil();
      }

      // 10秒経過（正常）
      currentTime = startTime.add(const Duration(seconds: 10));
      expect(calculateRemainingSeconds(startTime, currentTime, 0), equals(230));

      // 低電力モードによりタイマーのコールバックが5秒間完全に停止・間引きされた状況を模擬
      // （次回ティックが 10秒後 ではなく 15秒後 に飛んできた場合）
      currentTime = startTime.add(const Duration(seconds: 15));
      expect(calculateRemainingSeconds(startTime, currentTime, 0), equals(225));

      // さらにCPUスロットリングで60秒間画面更新が極端に遅延した場合
      currentTime = startTime.add(const Duration(seconds: 75));
      expect(calculateRemainingSeconds(startTime, currentTime, 0), equals(165));

      // 試合時間満了（240秒経過時）
      currentTime = startTime.add(const Duration(seconds: 240));
      expect(calculateRemainingSeconds(startTime, currentTime, 0), equals(0));

      // 時間超過（245秒経過時）でも負にならず0を維持すること
      currentTime = startTime.add(const Duration(seconds: 245));
      expect(calculateRemainingSeconds(startTime, currentTime, 0), equals(0));
    });

    test('途中で複数回の一時停止（合議など）が挟まりスロットリングが発生しても、累積停止時間が厳密に控除されること', () {
      final startTime = DateTime(2026, 10, 2, 10, 0, 0);
      const matchSeconds = 180; // 3分

      int calculateRemainingSeconds(
        DateTime start,
        DateTime now,
        int accumulatedPauseMs,
      ) {
        final elapsedMs =
            now.difference(start).inMilliseconds - accumulatedPauseMs;
        final remainingMs = (matchSeconds * 1000) - elapsedMs;
        if (remainingMs <= 0) return 0;
        return (remainingMs / 1000).ceil();
      }

      // 30秒経過後に一時停止し、合議で45秒間停止
      // 停止中にデバイスがスリープ・低電力化
      final pause1DurationMs = 45 * 1000;
      final current1 = startTime.add(const Duration(seconds: 75)); // 実時間75秒経過
      expect(
        calculateRemainingSeconds(startTime, current1, pause1DurationMs),
        equals(150),
      );

      // さらに再開後40秒経過した時点で再停止、20秒間停止
      final totalPauseMs = pause1DurationMs + (20 * 1000);
      final current2 = startTime.add(
        const Duration(seconds: 135),
      ); // 実時間135秒経過、停止65秒
      // 実稼働時間 = 135 - 65 = 70秒。残り = 180 - 70 = 110秒
      expect(
        calculateRemainingSeconds(startTime, current2, totalPauseMs),
        equals(110),
      );
    });
  });
}
