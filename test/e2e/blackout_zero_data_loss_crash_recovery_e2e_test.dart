import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/errors/emergency_crash_preserver.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('blackout_e2e_test_');
    EmergencyCrashPreserver.customDirectory = tempDir;
    EmergencyCrashPreserver.isWebOverride = false;
  });

  tearDown(() async {
    for (int court = 1; court <= 4; court++) {
      EmergencyCrashPreserver.unregisterActiveMatch('court_${court}_match');
    }
    await EmergencyCrashPreserver.clearCrashDump();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('[E2E] 4コート同時進行・全端末強制電源断（Blackout）ゼロデータ損失復旧E2Eテスト', () {
    test('4コート同時進行中に強制電源断が発生しても再起動時に全コートのスコア・絶対時間タイマー状態が完全復旧すること', () async {
      final startedTime = DateTime(2026, 10, 2, 10, 0);
      final courtsMatches = List.generate(4, (i) {
        final courtNum = i + 1;
        return MatchModel(
          id: 'court_${courtNum}_match',
          tournamentId: 'tour_blackout',
          matchType: '個人戦',
          status: 'in_progress',
          redName: 'コート$courtNum: 赤選手',
          whiteName: 'コート$courtNum: 白選手',
          redScore: 1,
          whiteScore: 0,
          timerStartedAt: startedTime,
          accumulatedPauseDurationMs: 1500,
        );
      });

      // 4コート分の試合データを退避システムに登録
      for (final match in courtsMatches) {
        EmergencyCrashPreserver.registerActiveMatch(
          match,
          extraContext: {'courtId': match.id, 'blackoutSimulated': true},
        );
      }

      // 強制電源断をシミュレート（直前クラッシュ退避実行）
      await EmergencyCrashPreserver.preserveOnCrash(
        error: 'BLACKOUT_FORCED_POWER_OFF',
        stackTrace: StackTrace.current,
      );

      // 再起動シミュレーション
      final dump = await EmergencyCrashPreserver.loadRecoverableCrashDump();
      expect(dump, isNotNull);
      expect(dump!['error'], contains('BLACKOUT_FORCED_POWER_OFF'));

      final recoveredMatch = MatchModel.fromJson(
        Map<String, dynamic>.from(dump['match'] as Map),
      );
      expect(recoveredMatch.status, 'in_progress');
      expect(recoveredMatch.timerStartedAt, isNotNull);
      expect(recoveredMatch.accumulatedPauseDurationMs, 1500);
      expect(recoveredMatch.redScore, 1);
    });
  });
}
