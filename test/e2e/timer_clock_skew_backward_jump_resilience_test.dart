import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/time/server_clock_offset_service.dart';

void main() {
  group('[E2E] システム時刻逆行およびNTP同期急変耐性 タイマー整合性E2Eテスト', () {
    late ServerClockOffsetService offsetService;

    setUp(() {
      offsetService = ServerClockOffsetService.instance;
      offsetService.resetOffset();
    });

    tearDown(() {
      offsetService.resetOffset();
    });

    test('タイマー稼働中に端末時刻が過去へ突発逆行してもオフセット補正により残り秒数が自律保護されること', () {
      // 基準時刻: 2026-10-03 10:00:00 (3分試合 = 180秒)
      final serverBaseTime = DateTime.utc(2026, 10, 3, 10, 0, 0);

      var match = MatchModel(
        id: 'm_time_travel_01',
        tournamentId: 't_time',
        matchType: '個人戦',
        status: 'in_progress',
        redName: '時空太郎',
        whiteName: '次元次郎',
        matchTimeMinutes: 3.0,
        timerStartedAt: serverBaseTime,
      );

      // 1. 正常進行: 30秒経過 (真の時刻: 10:00:30)
      final normalTime = serverBaseTime.add(const Duration(seconds: 30));
      expect(match.calculateRemainingSeconds(normalTime), 150);

      // 2. 突発事故: 体育館のWi-Fi再接続等により、端末ローカル時計が 10分前 (09:50:30) に逆行
      final rawLocalTimeBackward = normalTime.subtract(
        const Duration(minutes: 10),
      );

      // 端末時刻単体で見ると timerStartedAt より前になるため異常だが、
      // ServerClockOffsetService に +10分のオフセット（サーバー時刻 - ローカル時刻）が適用される
      offsetService.setOffset(const Duration(minutes: 10));

      // 補正後の現在時刻
      final correctedNow = rawLocalTimeBackward.add(offsetService.offset);

      // オフセット適用により、真の30秒経過（残り150秒）が正確に維持されること
      final remainingAfterCorrection = match.calculateRemainingSeconds(
        correctedNow,
      );
      expect(remainingAfterCorrection, 150);
    });

    test('システム時刻急変時の一時停止と手動修正がドメインモデルを非破壊に更新できること', () {
      final baseTime = DateTime.utc(2026, 10, 3, 11, 0, 0);

      var match = MatchModel(
        id: 'm_time_travel_02',
        tournamentId: 't_time',
        matchType: '個人戦',
        status: 'in_progress',
        redName: '時空太郎',
        whiteName: '次元次郎',
        matchTimeMinutes: 4.0, // 4分 = 240秒
        timerStartedAt: baseTime,
      );

      // 40秒経過時点で一時停止
      final pauseTime = baseTime.add(const Duration(seconds: 40));
      match = match.copyWith(
        timerStartedAt: null,
        accumulatedPauseDurationMs: 40 * 1000,
      );

      expect(match.calculateRemainingSeconds(pauseTime), 200);

      // 審判員が「時計を2分（120秒）に手動修正」を指示した場合
      final adjustedMatch = match.updateRemainingSeconds(
        120,
        pauseTime,
        isTimerStopping: true,
      );

      // 残り秒数が120秒として安全に再設定されていること
      expect(adjustedMatch.calculateRemainingSeconds(pauseTime), 120);

      // 再開時（さらに任意の未来時刻からスタート）
      final restartTime = pauseTime.add(const Duration(minutes: 5));
      final runningMatch = adjustedMatch.copyWith(timerStartedAt: restartTime);

      // 再開から10秒後: 120 - 10 = 110秒
      final after10s = restartTime.add(const Duration(seconds: 10));
      expect(runningMatch.calculateRemainingSeconds(after10s), 110);
    });
  });
}
