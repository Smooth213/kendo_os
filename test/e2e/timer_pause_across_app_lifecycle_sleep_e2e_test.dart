import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

void main() {
  group('[E2E] タイマー一時停止中アプリスリープ復帰時間整合性E2Eテスト', () {
    test('タイマー一時停止中に10分間の端末スリープおよびアプリ復帰を経ても残り秒数が維持されること', () {
      final baseTime = DateTime(2026, 10, 2, 11, 0, 0);

      // 3分（180秒）試合で、1分経過した時点で「やめ」がかかり一時停止
      var match = MatchModel(
        id: 'match_sleep_e2e',
        tournamentId: 't_sleep',
        matchType: '個人戦',
        status: 'in_progress',
        redName: '選手赤',
        whiteName: '選手白',
        matchTimeMinutes: 3.0,
        timerStartedAt: baseTime,
      );

      // 60秒経過時点
      final pauseTime = baseTime.add(const Duration(seconds: 60));
      final remainingAtPause = match.calculateRemainingSeconds(pauseTime);
      expect(remainingAtPause, 120);

      // 一時停止実行（経過時間60000msを累積し、timerStartedAtをnull化）
      match = match.copyWith(
        timerStartedAt: null,
        accumulatedPauseDurationMs: 60 * 1000,
      );

      // アプリがバックグラウンドに移行し、端末が10分間スリープ
      final resumeTime = pauseTime.add(const Duration(minutes: 10));

      // アプリ復帰（AppLifecycleState.resumed）時
      final remainingAfterWake = match.calculateRemainingSeconds(resumeTime);

      // 停止中であったため、10分経過しても残り秒数は120秒のまま完全凍結されていること
      expect(remainingAfterWake, 120);

      // 審判の「はじめ」で再開（resumeTime からタイマー開始）
      final resumedMatch = match.copyWith(timerStartedAt: resumeTime);

      // 再開後さらに10秒経過
      final checkTime = resumeTime.add(const Duration(seconds: 10));
      final currentRemaining = resumedMatch.calculateRemainingSeconds(
        checkTime,
      );
      expect(currentRemaining, 110);
    });
  });
}
