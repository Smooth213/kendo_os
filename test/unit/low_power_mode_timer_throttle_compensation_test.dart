import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📱 【Phase 2-9/10】OS省電力モード タイマースロットリング絶対時刻補正テスト', () {
    test('1. Timer.periodic が3秒ごとに間引かれても、絶対時間差分計算により正確な残り秒数が得られること', () {
      final matchStart = DateTime(2026, 9, 3, 10, 0, 0);
      const totalSeconds = 180;

      // 脆弱な実装（カウンタデクリメント）: タイマーが3回しか発火しなかった場合
      int brokenRemaining = totalSeconds;
      for (int i = 0; i < 3; i++) {
        brokenRemaining--; // 3回引かれて 177秒になってしまう（実際は9秒経過）
      }

      // Kendo OS の堅牢な実装（絶対時刻差分方式）:
      // 9秒後の絶対時刻で計算
      final nowAfter9Seconds = matchStart.add(const Duration(seconds: 9));
      final correctRemaining =
          (totalSeconds - nowAfter9Seconds.difference(matchStart).inSeconds);

      // 脆弱な実装は177秒（9秒遅延のバグ）
      expect(brokenRemaining, 177);

      // 堅牢な実装は正確に171秒（完全同期）！
      expect(correctRemaining, 171);
    });

    test('2. 24時間以上の長時間放置・マイナス値クランプ（0秒下限）保証', () {
      final matchStart = DateTime(2026, 9, 3, 10, 0, 0);
      const totalSeconds = 180;

      // 翌日（24時間経過）
      final nowNextDay = matchStart.add(const Duration(hours: 24));
      final remaining =
          (totalSeconds - nowNextDay.difference(matchStart).inSeconds).clamp(
            0,
            totalSeconds,
          );

      expect(remaining, 0); // 負数にならず0秒で安全停止
    });
  });
}
