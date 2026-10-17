import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

void main() {
  group('[Unit] リーグ代表戦タイマー解像度およびカウント方向計算検証テスト', () {
    test('無制限代表戦はカウントアップし有限時間代表戦はカウントダウンされること', () {
      final now = DateTime(2026, 7, 1, 12, 0, 0);

      // A: 一本勝負代表戦 (無制限, matchTimeMinutes = 0.0) -> カウントアップ
      final unlimitedMatch = const MatchModel(
        id: 'daihyo_unlimited',
        matchType: '代表戦',
        matchTimeMinutes: 0.0,
        status: 'ready',
        redName: 'Red',
        whiteName: 'White',
        events: [],
      );
      final remainingUnlimited = unlimitedMatch
          .copyWith(timerStartedAt: now.subtract(const Duration(seconds: 45)))
          .calculateRemainingSeconds(now);
      expect(remainingUnlimited, 45); // 45秒経過（カウントアップ）

      // B: 三本勝負代表戦 (有限時間, matchTimeMinutes = 3.0) -> カウントダウン
      final limitedMatch = const MatchModel(
        id: 'daihyo_limited',
        matchType: '代表戦',
        matchTimeMinutes: 3.0,
        status: 'ready',
        redName: 'Red',
        whiteName: 'White',
        events: [],
      );
      final remainingLimited = limitedMatch
          .copyWith(timerStartedAt: now.subtract(const Duration(seconds: 45)))
          .calculateRemainingSeconds(now);
      expect(remainingLimited, 135); // 180 - 45 = 135秒残り（カウントダウン）
    });
  });
}
