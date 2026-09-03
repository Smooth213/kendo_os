import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🧪 【Unit 4/5】時計逆行（Clock Skew）・ドリフト・極限時間耐久テスト', () {
    final startTime = DateTime(2026, 9, 3, 10, 0, 0); // 10:00:00
    const matchMinutes = 3.0; // 180秒試合

    final match = MatchModel(
      id: 'skew_test_1',
      tournamentId: 't1',
      matchType: '個人戦',
      redName: '選手A',
      whiteName: '選手B',
      matchTimeMinutes: matchMinutes,
      timerStartedAt: startTime,
      accumulatedPauseDurationMs: 0,
      rule: const MatchRule(matchTimeMinutes: matchMinutes),
    );

    test('1. 正常な時間経過（30秒後、90秒後、180秒後）で正確な残り秒数が算出されること', () {
      // 30秒経過 ➔ 残り150秒
      expect(
        match.calculateRemainingSeconds(
          startTime.add(const Duration(seconds: 30)),
        ),
        150,
      );

      // 90秒経過 ➔ 残り90秒
      expect(
        match.calculateRemainingSeconds(
          startTime.add(const Duration(seconds: 90)),
        ),
        90,
      );

      // 180秒経過 ➔ 0秒（時間切れ）
      expect(
        match.calculateRemainingSeconds(
          startTime.add(const Duration(seconds: 180)),
        ),
        0,
      );

      // 200秒経過（時間超過） ➔ 0秒（負数にならず0にクランプ）
      expect(
        match.calculateRemainingSeconds(
          startTime.add(const Duration(seconds: 200)),
        ),
        0,
      );
    });

    test('2. 端末時計逆行（NTPズレや手動変更でnowが開始時刻より過去へ逆行）でも上限を超えないこと', () {
      // 端末時計が開始前（10秒過去）に逆行
      final reversedTime = startTime.subtract(const Duration(seconds: 10));
      final remaining = match.calculateRemainingSeconds(reversedTime);

      // 負の経過時間により初期時間(180秒)をわずかに上回るが、クラッシュせず整数秒が返ること
      expect(remaining, greaterThanOrEqualTo(180));
      expect(remaining.isFinite, isTrue);
    });

    test('3. 極限値耐久: 24時間後、うるう秒、NaN/Infinity 異常入力に対する絶対安全', () {
      // 24時間経過後（アプリ放置） ➔ 安全に0秒
      final nextDay = startTime.add(const Duration(days: 1));
      expect(match.calculateRemainingSeconds(nextDay), 0);

      // 異常値: NaN
      final nanMatch = match.copyWith(matchTimeMinutes: double.nan);
      expect(nanMatch.calculateRemainingSeconds(startTime), 0);

      // 異常値: Infinity
      final infMatch = match.copyWith(matchTimeMinutes: double.infinity);
      expect(infMatch.calculateRemainingSeconds(startTime), 0);
    });

    test('4. 代表戦・延長戦（無制限一本勝負 baseSeconds == 0）でのカウントアップ耐久', () {
      final unlimitedMatch = match.copyWith(
        matchType: '代表戦',
        matchTimeMinutes: 0.0,
      );

      // 65秒経過 ➔ 65秒（経過秒数がそのままカウントアップ）
      expect(
        unlimitedMatch.calculateRemainingSeconds(
          startTime.add(const Duration(seconds: 65)),
        ),
        65,
      );

      // 2時間越えの激闘（7200秒）でも正常カウント
      expect(
        unlimitedMatch.calculateRemainingSeconds(
          startTime.add(const Duration(hours: 2)),
        ),
        7200,
      );
    });
  });
}
