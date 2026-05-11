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

  // ★ 修正2: 二重引き算バグを解消し、常に「今のremainingSecondsから、startedAtからの経過時間を引く」という超シンプルな計算に統一
  int _calculateRemainingSeconds(MatchModel match) {
    if (match.timerStartedAt == null || !match.timerIsRunning) return match.remainingSeconds;
    
    final now = DateTime.now();
    final elapsedMs = now.difference(match.timerStartedAt!).inMilliseconds;
    
    bool isUnlimited = match.matchType == '代表戦' || (match.matchType == '延長戦' && match.remainingSeconds == 0);
    if (isUnlimited) {
      return match.remainingSeconds + (elapsedMs / 1000).floor(); // 無制限時はカウントアップ
    }
    
    final remainingMs = (match.remainingSeconds * 1000) - elapsedMs;
    return remainingMs > 0 ? (remainingMs / 1000).ceil() : 0;
  }

  // ★ 修正: DBのラグで古いデータを読んでしまい空回りするのを防ぐため、強制スタートフラグ(isImmediateStart)を導入
  void startLocalTicker(String matchId, {bool isImmediateStart = false}) {
    // 既にタイマーがアクティブに動いており、外部からの単なる同期イベント(listen等)の場合は
    // 無駄な再起動（と isImmediateStart の剥奪）を防ぐ。
    if (_ticker != null && _ticker!.isActive && !isImmediateStart) {
      return;
    }

    _ticker?.cancel();
    final fallbackStartedAt = DateTime.now(); // ★ 修正: ループの外で一度だけ「開始時間」を記録する
    // ★ 修正: ループ開始時の「現在の表示秒数」をキャッシュしておく（DBのラグによる巻き戻り防止）
    final cachedRemainingSeconds = ref.read(liveRemainingSecondsProvider(matchId));

    _ticker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final match = _getMatch(matchId);
      
      // DBの同期が遅れて false に見えていても、isImmediateStart が true なら強制的に計算を回す
      if (match == null || (!match.timerIsRunning && !isImmediateStart)) return;

      // ★ 究極の修正: isImmediateStartがtrueの間は、DBのラグを一切信用せず、
      // キャッシュした秒数とボタンを押した瞬間の時刻だけを使用して計算する
      final effectiveMatch = isImmediateStart
          ? match.copyWith(timerStartedAt: fallbackStartedAt, timerIsRunning: true, remainingSeconds: cachedRemainingSeconds)
          : match;

      final currentDerived = _calculateRemainingSeconds(effectiveMatch);
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
      timerIsRunning: newIsRunning,
      status: currentState.toLegacyString(),
    );

    if (newIsRunning) {
      // ★ 修正4: スタート時は常に「今」を基準にする。累積ポーズ時間などの複雑なロジックを廃止。
      updatedMatch = updatedMatch.copyWith(
        timerStartedAt: now,
        timerPausedAt: null,
      );
      // ★ 修正: await を外してUXのブロックを防ぎ、即座にタイマーを回し始める
      ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch); 
      startLocalTicker(matchId, isImmediateStart: true);
    } else {
      // PAUSE: 止めた瞬間の秒数を計算して remainingSeconds に上書き保存する
      _ticker?.cancel();
      // ★ 修正: DBのラグで計算が狂って初期値に巻き戻るのを防ぐため、画面に見えている正しい残り秒数をそのまま保存する
      final derivedRemaining = ref.read(liveRemainingSecondsProvider(matchId));
      updatedMatch = updatedMatch.copyWith(
        remainingSeconds: derivedRemaining,
        timerStartedAt: null,
        timerPausedAt: now,
      );
      
      ref.read(liveRemainingSecondsProvider(matchId).notifier).state = derivedRemaining;
      // ★ 修正: PAUSE時も await を外してレスポンスを劇的に向上させる
      ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch); 
    }
  }

  Future<void> updateRemainingSeconds(String matchId, int seconds) async {
    final match = _getMatch(matchId);
    if (match == null) return;
    
    ref.read(liveRemainingSecondsProvider(matchId).notifier).state = seconds;
    
    bool isTimeUp = (seconds == 0 && match.timerIsRunning); 
    MatchModel updatedMatch = match.copyWith(
      remainingSeconds: seconds < 0 ? 0 : seconds,
      timerIsRunning: isTimeUp ? false : match.timerIsRunning,
      // ★ 究極の修正: 稼働中に秒数を手動変更した場合、timerStartedAtがnullで上書きされタイマーが永遠にフリーズする致命的バグを解消
      timerStartedAt: isTimeUp ? null : (match.timerIsRunning ? DateTime.now() : null),
      timerPausedAt: isTimeUp ? DateTime.now() : match.timerPausedAt,
    );
    
    ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch);

    // ★ 修正: 稼働中に手動で秒数を変更した場合、古いキャッシュで計算され続けて一瞬で元に戻るのを防ぐためタイマーを再起動する
    if (match.timerIsRunning && !isTimeUp) {
      startLocalTicker(matchId, isImmediateStart: true);
    }
  }

  MatchModel? _getMatch(String id) {
    final matches = ref.read(matchListProvider);
    return matches.where((m) => m.id == id).firstOrNull;
  }
}