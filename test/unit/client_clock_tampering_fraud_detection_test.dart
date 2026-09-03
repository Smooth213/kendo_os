import 'package:flutter_test/flutter_test.dart';

/// 🛡️ クライアント時刻改ざん・時間切れ不正検知エンジン
class ClockTamperDetector {
  static const int maxAllowedDriftSeconds = 15;

  /// クライアント申告時刻と信頼できるサーバー時刻の比較検証
  static ({bool isTampered, String? reason, int correctedRemainingSeconds})
  validateMatchTime({
    required DateTime clientCurrentTime,
    required DateTime serverCurrentTime,
    required DateTime matchStartedAt,
    required int matchTotalSeconds,
  }) {
    final driftSeconds =
        (clientCurrentTime.difference(serverCurrentTime).inSeconds).abs();

    // サーバー時刻を唯一の真実（SSOT）として残り時間を計算
    final actualElapsedSeconds = serverCurrentTime
        .difference(matchStartedAt)
        .inSeconds;
    final realRemaining = (matchTotalSeconds - actualElapsedSeconds).clamp(
      0,
      matchTotalSeconds,
    );

    if (driftSeconds > maxAllowedDriftSeconds) {
      return (
        isTampered: true,
        reason: '端末時刻がサーバー時刻と$driftSeconds秒乖離しています（時刻改ざん検知）',
        correctedRemainingSeconds: realRemaining,
      );
    }

    return (
      isTampered: false,
      reason: null,
      correctedRemainingSeconds: realRemaining,
    );
  }
}

void main() {
  group('🌐 【Phase 4-5/11】端末時刻意図的改ざん（時間切れ不正工作）検知＆矯正テスト', () {
    final serverNow = DateTime(2026, 9, 3, 10, 1, 0); // 試合開始1分後（残り120秒のはず）
    final matchStart = DateTime(2026, 9, 3, 10, 0, 0);
    const totalSeconds = 180;

    test('1. 悪意ある端末が時計を5分未来に進めて「時間切れ勝ち」を偽装した場合、改ざんを検知して矯正すること', () {
      // 端末時刻を勝手に 10:05:00（5分進めた）に偽装
      final tamperedClientTime = serverNow.add(const Duration(minutes: 5));

      final validation = ClockTamperDetector.validateMatchTime(
        clientCurrentTime: tamperedClientTime,
        serverCurrentTime: serverNow,
        matchStartedAt: matchStart,
        matchTotalSeconds: totalSeconds,
      );

      // 改ざんが検知されること
      expect(validation.isTampered, isTrue);
      expect(validation.reason, contains('時刻改ざん検知'));

      // 残り時間は端末の0秒ではなく、サーバー基準の正確な120秒に矯正されること！
      expect(validation.correctedRemainingSeconds, 120);
    });

    test('2. 正常なミリ秒のネットワーク揺らぎ（1〜2秒以内）は改ざんと誤認せず承認すること', () {
      final normalClientTime = serverNow.add(const Duration(seconds: 2));

      final validation = ClockTamperDetector.validateMatchTime(
        clientCurrentTime: normalClientTime,
        serverCurrentTime: serverNow,
        matchStartedAt: matchStart,
        matchTotalSeconds: totalSeconds,
      );

      expect(validation.isTampered, isFalse);
      expect(validation.reason, isNull);
      expect(validation.correctedRemainingSeconds, 120);
    });
  });
}
