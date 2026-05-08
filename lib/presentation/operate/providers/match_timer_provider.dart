import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'match_list_provider.dart';
import 'package:kendo_os/application/usecases/match_application_service.dart';
import 'package:kendo_os/domain/entities/match_state.dart'; // ★ Phase 1 & 3: FSM連携用

// ★ Step 3-3: 1秒ごとの「生の残り秒数」を配信するプロバイダ
// 画面全体ではなく、このプロバイダを watch している小さな Widget だけがリビルドされる
final liveRemainingSecondsProvider = StateProvider.family<int, String>((ref, matchId) {
  // Firestoreの値を初期値としてセット
  final initialSeconds = ref.watch(matchListProvider.select((list) {
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

  // ★ Phase 3-2: 派生状態（Derived Remaining）の計算
  int _calculateRemainingSeconds(MatchModel match) {
    if (match.timerStartedAt == null) return match.remainingSeconds;
    
    final now = DateTime.now();
    int elapsedMs = 0;
    
    if (match.timerIsRunning) {
      elapsedMs = now.difference(match.timerStartedAt!).inMilliseconds - match.accumulatedPauseDurationMs;
    } else if (match.timerPausedAt != null) {
      elapsedMs = match.timerPausedAt!.difference(match.timerStartedAt!).inMilliseconds - match.accumulatedPauseDurationMs;
    }
    
    bool isUnlimited = match.matchType == '代表戦' || (match.matchType == '延長戦' && match.remainingSeconds == 0);
    if (isUnlimited) {
      return (elapsedMs / 1000).floor(); // 無制限時はカウントアップ
    }
    
    final remainingMs = (match.remainingSeconds * 1000) - elapsedMs;
    return remainingMs > 0 ? (remainingMs / 1000).ceil() : 0;
  }

  // ★ Phase 3-3 & 3-4: Tick依存廃止（UI更新専用の超高頻度・軽量Tick）と AppLifecycle対応
  void startLocalTicker(String matchId) {
    _ticker?.cancel();
    // データ(DB)は一切更新せず、現在時刻からの差分だけを計算するため100ms周期でも超軽量
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final match = _getMatch(matchId);
      if (match == null || !match.timerIsRunning) {
        timer.cancel();
        return;
      }

      final currentDerived = _calculateRemainingSeconds(match);
      final currentUiState = ref.read(liveRemainingSecondsProvider(matchId));

      // 秒数が変わった瞬間だけUI(Provider)を更新
      if (currentDerived != currentUiState) {
        ref.read(liveRemainingSecondsProvider(matchId).notifier).state = currentDerived;
        
        // 0秒到達時の処理
        if (currentDerived == 0 && match.matchType != '代表戦' && match.matchType != '延長戦') {
           timer.cancel();
           updateRemainingSeconds(matchId, 0); // ここで初めてFirestoreへ保存
        }
      }
    });
  }

  // ★ Phase 3-1: Absolute Time化 (startedAt/pausedAt導入)
  Future<void> toggleTimer(String matchId) async {
    final match = _getMatch(matchId);
    if (match == null) return;
    if (!match.timerIsRunning && match.remainingSeconds <= 0 && match.matchType != '代表戦') return;

    final newIsRunning = !match.timerIsRunning;
    final now = DateTime.now();
    
    // ★ Phase 1 & 3: FSM連携による正しい状態遷移
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
      timerIsRunning: newIsRunning,
      status: currentState.toLegacyString(),
    );

    if (newIsRunning) {
      // START / RESUME
      if (match.timerStartedAt == null) {
        updatedMatch = updatedMatch.copyWith(timerStartedAt: now);
      } else if (match.timerPausedAt != null) {
        final pauseDuration = now.difference(match.timerPausedAt!).inMilliseconds;
        updatedMatch = updatedMatch.copyWith(
          accumulatedPauseDurationMs: match.accumulatedPauseDurationMs + pauseDuration,
          timerPausedAt: null,
        );
      }
      await ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch);
      startLocalTicker(matchId);
    } else {
      // PAUSE
      _ticker?.cancel();
      updatedMatch = updatedMatch.copyWith(timerPausedAt: now);
      final derivedRemaining = _calculateRemainingSeconds(updatedMatch);
      updatedMatch = updatedMatch.copyWith(remainingSeconds: derivedRemaining);
      
      ref.read(liveRemainingSecondsProvider(matchId).notifier).state = derivedRemaining;
      await ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch);
    }
  }

  // 残り秒数の手動同期（UIダイアログからの時間修正等）
  Future<void> updateRemainingSeconds(String matchId, int seconds) async {
    final match = _getMatch(matchId);
    if (match == null) return;
    
    ref.read(liveRemainingSecondsProvider(matchId).notifier).state = seconds;
    
    // UIからの手動時間修正か、タイマー0秒自動到達かを判別
    bool isTimeUp = (seconds == 0 && match.timerIsRunning); 
    
    MatchModel updatedMatch = match.copyWith(remainingSeconds: seconds < 0 ? 0 : seconds);
    
    if (!isTimeUp) { 
      // ★ 手動で時間が修正されたら、絶対時刻ベースの計算をリセットする
      updatedMatch = updatedMatch.copyWith(
        timerStartedAt: null, 
        timerPausedAt: null,
        accumulatedPauseDurationMs: 0,
      );
    }
    
    await ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch);
  }

  MatchModel? _getMatch(String id) {
    final matches = ref.read(matchListProvider);
    return matches.where((m) => m.id == id).firstOrNull;
  }
}