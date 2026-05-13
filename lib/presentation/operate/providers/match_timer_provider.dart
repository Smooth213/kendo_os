import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'match_list_provider.dart';
import 'package:kendo_os/application/usecases/match_application_service.dart';
import 'package:kendo_os/domain/entities/match_state.dart'; // ★ Phase 1 & 3: FSM連携用

// ★ 修正1: 監視(watch)ではなく、画面を開いた時の初期値の読み取り(read)に変更。
// これにより、通信のたびに秒数がリセットされるバグが消滅します。
final liveRemainingSecondsProvider = StateProvider.family<int, String>((ref, matchId) {
  final initialSeconds = ref.read(matchListProvider.select((list) {
    final match = list.where((m) => m.id == matchId).firstOrNull;
    return match?.remainingSeconds ?? 0;
  }));
  return initialSeconds;
});

final renseikaiMasterTimerProvider = StateProvider.family<int, String>((ref, groupName) => -1);
final isMasterTimerRunningProvider = StateProvider.family<bool, String>((ref, groupName) => false);

final matchTimerProvider = Provider<MatchTimer>((ref) {
  return MatchTimer(ref);
});

class MatchTimer {
  final Ref ref;
  Timer? _ticker;
  MatchTimer(this.ref);

  void startLocalTicker(String matchId, {bool isImmediateStart = false}) {
    if (_ticker != null && _ticker!.isActive && !isImmediateStart) return;

    _ticker?.cancel();
    final fallbackStartedAt = DateTime.now(); 

    _ticker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final match = _getMatch(matchId);
      if (match == null || (!match.timerIsRunning && !isImmediateStart)) return;

      // ★ 修正: _calculateRemainingSeconds を廃止し、MatchModelに組み込んだスマートな計算ゲッターを直接呼ぶ
      final effectiveMatch = isImmediateStart
          ? match.copyWith(timerStartedAt: fallbackStartedAt)
          : match;

      final currentDerived = effectiveMatch.remainingSeconds;
      final currentUiState = ref.read(liveRemainingSecondsProvider(matchId));

      if (currentDerived != currentUiState) {
        ref.read(liveRemainingSecondsProvider(matchId).notifier).state = currentDerived;
        
        if (currentDerived == 0 && match.matchType != '代表戦' && match.matchType != '延長戦') {
           timer.cancel();
           updateRemainingSeconds(matchId, 0); 
        }
      }
    });
  }

  void stopLocalTicker(String matchId) {
    _ticker?.cancel();
  }

  Future<void> toggleTimer(String matchId) async {
    final match = _getMatch(matchId);
    if (match == null) return;
    if (!match.timerIsRunning && match.remainingSeconds <= 0 && match.matchType != '代表戦') return;

    final newIsRunning = !match.timerIsRunning;
    final now = DateTime.now();
    
    MatchLifecycleState currentState = MatchLifecycleStateLegacyExt.fromLegacyString(match.status);
    if (newIsRunning) {
      if (currentState == MatchLifecycleState.ready || currentState == MatchLifecycleState.notStarted || currentState == MatchLifecycleState.waitingForPlayers) {
        currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.startMatch);
      } else if (currentState == MatchLifecycleState.paused) {
        currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.resume);
      }
    } else {
      if (currentState == MatchLifecycleState.inProgress || currentState == MatchLifecycleState.encho) {
        currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.pause);
      }
    }
    
    MatchModel updatedMatch = match.copyWith(
      status: currentState.toLegacyString(),
    );

    if (newIsRunning) {
      // ★ 修正: スタート時は時刻を記録するだけ
      updatedMatch = updatedMatch.copyWith(timerStartedAt: now, timerPausedAt: null);
      ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch); 
      startLocalTicker(matchId, isImmediateStart: true);
    } else {
      // ★ 修正: ストップ時は経過時間を算出して蓄積（accumulated）する
      _ticker?.cancel();
      final elapsed = now.difference(match.timerStartedAt!).inMilliseconds;
      updatedMatch = updatedMatch.copyWith(
        timerStartedAt: null,
        timerPausedAt: now,
        accumulatedPauseDurationMs: match.accumulatedPauseDurationMs + elapsed,
      );
      ref.read(liveRemainingSecondsProvider(matchId).notifier).state = updatedMatch.remainingSeconds;
      ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch); 
    }
  }

  Future<void> updateRemainingSeconds(String matchId, int seconds) async {
    final match = _getMatch(matchId);
    if (match == null) return;
    
    ref.read(liveRemainingSecondsProvider(matchId).notifier).state = seconds;
    bool isTimeUp = (seconds <= 0 && match.timerIsRunning); 
    
    // ★ 修正: 先ほどMatchModelに作成したヘルパーを使って絶対時間を逆算する
    MatchModel updatedMatch = match.updateRemainingSeconds(seconds < 0 ? 0 : seconds);
    if (isTimeUp) {
      updatedMatch = updatedMatch.copyWith(timerStartedAt: null, timerPausedAt: DateTime.now());
    }
    
    ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch);

    if (match.timerIsRunning && !isTimeUp) {
      startLocalTicker(matchId, isImmediateStart: true);
    }
  }

  MatchModel? _getMatch(String id) {
    final matches = ref.read(matchListProvider);
    return matches.where((m) => m.id == id).firstOrNull;
  }
}