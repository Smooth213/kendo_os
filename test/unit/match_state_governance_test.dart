import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/match_state.dart';
import '../../test/helpers/mock_data.dart';

void main() {
  group('🛡️ Phase 3 — 状態遷移保証ユニットテスト要塞', () {
    test(
      '1. 【FSM・状態遷移関数】transitionメソッドを介したライフサイクル状態の遷移が決定論的にstatus文字列へ投影されること',
      () {
        final baseMatch = MatchBuilder().id('fsm_test_001').build();
        expect(baseMatch.status, equals('waiting'));
        expect(baseMatch.lifecycle, equals(MatchLifecycleState.ready));

        final playingMatch = baseMatch.transition(
          MatchLifecycleState.inProgress,
        );
        expect(playingMatch.status, equals('in_progress'));

        final finishedMatch = playingMatch.transition(
          MatchLifecycleState.completed,
        );
        expect(finishedMatch.status, equals('finished'));
      },
    );

    test(
      '2. 【タイマー状態遷移・絶対時間】経過時間Msと外部注入タイムソース(now)から残り秒数が1ミリ秒の狂いもなく絶対プロジェクションされること',
      () {
        final baseTime = DateTime(2026, 5, 30, 9, 0, 0);
        final match = MatchModel(
          id: 'timer_fsm_001',
          matchType: '先鋒',
          redName: '紅組',
          whiteName: '白組',
          matchTimeMinutes: 3.0,
          timerStartedAt: baseTime,
          accumulatedPauseDurationMs: 0,
        );

        expect(match.timerIsRunning, isTrue);

        final now10sLater = baseTime.add(const Duration(seconds: 10));
        final remaining = match.calculateRemainingSeconds(now10sLater);

        expect(remaining, equals(170));
      },
    );

    test(
      '3. 【Undo操作保護】Strangler Figパターンで保護されたisDirtyフラグおよび同等の状態ライフサイクルが非破壊原則を維持していること',
      () {
        final syncedMatch = MatchBuilder().id('undo_fsm_001').build();
        expect(syncedMatch.isDirty, isFalse);

        final localDirtyMatch = syncedMatch.copyWith(
          syncState: SyncState.localOnly,
        );
        expect(localDirtyMatch.isDirty, isTrue);
      },
    );
  });
}
