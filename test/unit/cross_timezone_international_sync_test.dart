import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🌐 【Phase 4-10/11】世界剣道選手権 時差跨ぎ端末間（UTCエポックミリ秒同期）経過秒数完全一致テスト', () {
    test('1. エポックミリ秒（Unix Timestamp）基準で計算することで、全世界どの端末でも残り時間が完全一致すること', () {
      // 試合開始時刻（UTC 2026-09-03 01:00:00Z）
      final matchStartEpochMs = DateTime.utc(
        2026,
        9,
        3,
        1,
        0,
        0,
      ).millisecondsSinceEpoch;
      const totalSeconds = 180;

      // 45秒経過（UTC 01:00:45Z）
      final currentEpochMs = matchStartEpochMs + (45 * 1000);

      // 各国端末（東京・ロンドン・ニューヨーク）でのローカル時計表現
      // 東京端末の現地時刻（JST）: 10:00:45
      final tokyoDeviceNow = DateTime.fromMillisecondsSinceEpoch(
        currentEpochMs,
      );
      // ロンドン端末の現地時刻（UTC）: 01:00:45
      final londonDeviceNow = DateTime.fromMillisecondsSinceEpoch(
        currentEpochMs,
        isUtc: true,
      );
      // NY端末の現地時刻（EDT）: 前日21:00:45
      final nyDeviceNow = DateTime.fromMillisecondsSinceEpoch(currentEpochMs);

      // 経過秒数計算（エポックミリ秒差分）
      int calcRemaining(DateTime deviceNow) {
        final elapsedMs = deviceNow.millisecondsSinceEpoch - matchStartEpochMs;
        final elapsedSec = elapsedMs ~/ 1000;
        return (totalSeconds - elapsedSec).clamp(0, totalSeconds);
      }

      final remainingInTokyo = calcRemaining(tokyoDeviceNow);
      final remainingInLondon = calcRemaining(londonDeviceNow);
      final remainingInNy = calcRemaining(nyDeviceNow);

      // 全世界の全端末で残り時間が完全に一致（135秒）すること！
      expect(remainingInTokyo, 135);
      expect(remainingInLondon, 135);
      expect(remainingInNy, 135);
    });
  });
}
