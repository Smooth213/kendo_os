import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'match_list_provider.dart';
import 'package:kendo_os/application/usecases/match_application_service.dart';
import 'package:kendo_os/domain/entities/match_state.dart'; // ★ Phase 1 & 3: FSM連携用
import 'package:flutter/foundation.dart'; // ★ 追加: debugPrint用

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
  bool _expectedIsRunning = false; // ★ 修正: DBのラグに依存しない「期待するタイマー状態」
  DateTime _lastToggledAt = DateTime.fromMillisecondsSinceEpoch(0); // ★ 修正: 手動操作直後のゴースト再起動を防ぐ

  MatchTimer(this.ref);

  void startLocalTicker(String matchId, {bool isImmediateStart = false}) {
    debugPrint('🕒 [MatchTimer] startLocalTicker requested. matchId=$matchId, immediate=$isImmediateStart');
    // ★ 修正: 手動操作の直後（2秒以内）にクラウドの古いデータによる自動再開（ゴースト再起動）を完全に防ぐ
    final diff = DateTime.now().difference(_lastToggledAt).inSeconds;
    if (!isImmediateStart && diff < 2) {
      debugPrint('🕒 [MatchTimer] startLocalTicker BLOCKED (ghost restart prevention). diff=$diff sec');
      return;
    }

    _expectedIsRunning = true;

    // ★ 修正: 既にタイマーが動いている場合は再開を禁止
    if (_ticker != null && _ticker!.isActive) {
      debugPrint('🕒 [MatchTimer] startLocalTicker: Ticker already active. Ignoring.');
      return;
    }

    debugPrint('🕒 [MatchTimer] startLocalTicker: Ticker STARTED.');
    _ticker?.cancel();
    final fallbackStartedAt = DateTime.now(); 

    _ticker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_expectedIsRunning) {
        timer.cancel();
        return;
      }

      final match = _getMatch(matchId);
      if (match == null) {
        timer.cancel();
        return;
      }

      // ★ 修正: タイマー再開直後、DBの timerIsRunning がまだ false (同期ラグ) の場合でも
      // フォールバックの開始時刻を使って時間を滑らかに減らし続ける
      final effectiveMatch = !match.timerIsRunning 
          ? match.copyWith(timerStartedAt: fallbackStartedAt)
          : match;

      int currentDerived = effectiveMatch.remainingSeconds;
      
      final currentUiState = ref.read(liveRemainingSecondsProvider(matchId));

      if (currentDerived != currentUiState) {
        ref.read(liveRemainingSecondsProvider(matchId).notifier).state = currentDerived;
        
        if (currentDerived == 0 && match.matchType != '代表戦' && match.matchType != '延長戦') {
           timer.cancel();
           _expectedIsRunning = false;
           updateRemainingSeconds(matchId, 0); 
        }
      }
    });
  }

  void stopLocalTicker(String matchId) {
    debugPrint('🕒 [MatchTimer] stopLocalTicker requested. matchId=$matchId');
    // ★ 修正: 手動操作直後に、クラウドの古いデータで強制停止されるのを防ぐ
    if (DateTime.now().difference(_lastToggledAt).inSeconds < 2) {
      debugPrint('🕒 [MatchTimer] stopLocalTicker BLOCKED (ghost stop prevention).');
      return;
    }
    _expectedIsRunning = false;
    _ticker?.cancel();
  }

  Future<void> toggleTimer(String matchId) async {
    final match = _getMatch(matchId);
    if (match == null) return;

    final newIsRunning = !_expectedIsRunning;
    if (newIsRunning && match.remainingSeconds <= 0 && match.matchType != '代表戦') return;

    debugPrint('🕒 [MatchTimer] toggleTimer: Toggling timer to isRunning=$newIsRunning');
    final now = DateTime.now();
    _lastToggledAt = now;
    _expectedIsRunning = newIsRunning;
    
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
      } else {
        // ★ 万が一状態が in_progress 以外なのにタイマーが回っていた場合でも強制的に止める
        currentState = MatchLifecycleState.paused;
      }
    }
    
    MatchModel updatedMatch = match.copyWith(
      status: currentState.toLegacyString(),
    );

    if (newIsRunning) {
      // ★ 修正: スタート時は時刻を記録するだけ
      // ★ 重要: 再開時は accumulatedPauseDurationMs を **保持** する！
      // 一時停止中に蓄積された経過時間をリセットすると、
      // 再開時に「時間が初期化される」問題が発生する
      updatedMatch = updatedMatch.copyWith(
        timerStartedAt: now, 
        timerPausedAt: null,
        // accumulatedPauseDurationMs は保持（リセットしない）
      );
      ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch); 
      startLocalTicker(matchId, isImmediateStart: true);
    } else {
      _ticker?.cancel();
      // ★ 修正: 見かけ上一時停止でも裏で動き続けるバグの真の原因は、
      // 停止時に timerStartedAt が null にならない（古い時間が残る）ことによる時間の再計算です。
      // UIの現在の残り秒数を絶対値として取得し、それをベースに時間を完全に固定します。
      final currentSeconds = ref.read(liveRemainingSecondsProvider(matchId));
      debugPrint('🕒 [MatchTimer] toggleTimer(STOP): currentSeconds=$currentSeconds, match.timerStartedAt=${match.timerStartedAt}');
      
      // ★ 修正: copyWith と updateRemainingSeconds の順序を逆転させます。
      // 先に状態(status等)を変更し、最後に isTimerStopping=true を呼んで「JSON経由での再生成」で確実に timerStartedAt を消去します。
      updatedMatch = match.copyWith(
        status: currentState.toLegacyString(),
        timerPausedAt: now,
      ).updateRemainingSeconds(currentSeconds, isTimerStopping: true);

      debugPrint('🕒 [MatchTimer] toggleTimer(STOP): regenerated match.timerStartedAt=${updatedMatch.timerStartedAt}, isRunning=${updatedMatch.timerIsRunning}');

      ref.read(liveRemainingSecondsProvider(matchId).notifier).state = currentSeconds;
      ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch);
    }
  }

  Future<void> updateRemainingSeconds(String matchId, int seconds) async {
    final match = _getMatch(matchId);
    if (match == null) return;
    
    ref.read(liveRemainingSecondsProvider(matchId).notifier).state = seconds;
    bool isTimeUp = (seconds <= 0 && _expectedIsRunning); 
    
    // ★ 修正: タイムアップ時は isTimerStopping=true を指定
    MatchModel updatedMatch = match.updateRemainingSeconds(
      seconds < 0 ? 0 : seconds,
      isTimerStopping: isTimeUp,
    );
    
    if (isTimeUp) {
      // ★ 修正: タイムアップ時も確実にステータスを一時停止状態にし、裏で回り続けるのを防ぐ
      updatedMatch = updatedMatch.copyWith(
        status: MatchLifecycleState.paused.toLegacyString(),
        timerPausedAt: DateTime.now(),
        timerStartedAt: null, // ★ タイムアップ時も確実に null にする
      );
      _expectedIsRunning = false;
    }
    
    ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch);

    // ★ 修正: タイムアップ時はローカルタイマーを確実に止める
    if (isTimeUp) {
      _ticker?.cancel();
    } else if (_expectedIsRunning) {
      startLocalTicker(matchId, isImmediateStart: true);
    }
  }

  MatchModel? _getMatch(String id) {
    final matches = ref.read(matchListProvider);
    return matches.where((m) => m.id == id).firstOrNull;
  }
}