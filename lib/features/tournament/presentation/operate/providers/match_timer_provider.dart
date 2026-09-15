import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'match_list_provider.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_state.dart'; // ★ Phase 1 & 3: FSM連携用
import 'package:kendo_os/shared/time/time_source.dart'; // ★ 追加
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';
export 'renseikai_master_timer_provider.dart';

// ★ 修正1: 監視(watch)ではなく、画面を開いた時の初期値の読み取り(read)に変更。
// これにより、通信のたびに秒数がリセットされるバグが消滅します。
final liveRemainingSecondsProvider = StateProvider.family<int, String>((
  ref,
  matchId,
) {
  final match = ref.read(
    matchListProvider.select((list) {
      return list.where((m) => m.id == matchId).firstOrNull;
    }),
  );
  final now = ref.read(timeSourceProvider).now();
  return match?.calculateRemainingSeconds(now) ?? 0;
});

final matchTimerProvider = Provider<MatchTimer>((ref) {
  final matchTimer = MatchTimer(ref);
  ref.onDispose(() {
    matchTimer.dispose();
  });
  return matchTimer;
});

class MatchTimer {
  final Ref ref;
  Timer? _ticker;
  bool _expectedIsRunning = false; // ★ 修正: DBのラグに依存しない「期待するタイマー状態」
  DateTime _lastToggledAt = DateTime.fromMillisecondsSinceEpoch(
    0,
  ); // ★ 修正: 手動操作直後のゴースト再起動を防ぐ
  String? _activeMatchId;
  AppLifecycleListener? _lifecycleListener;

  MatchTimer(this.ref) {
    // 🔋 【Plan 2-2】バックグラウンド待機時の完全コールドスリープ連携
    // アプリ非表示・待機時にタイマーの定期起床を停止し、復帰時に絶対時刻で一括補正
    try {
      _lifecycleListener = AppLifecycleListener(
        onStateChange: (state) {
          if (state == AppLifecycleState.paused ||
              state == AppLifecycleState.inactive ||
              state == AppLifecycleState.hidden) {
            enterColdSleep();
          } else if (state == AppLifecycleState.resumed) {
            resumeFromColdSleep();
          }
        },
      );
    } catch (_) {}
  }

  /// 🔋 【Plan 2-2】アプリがバックグラウンドに回った際の完全コールドスリープ
  /// Tickerを停止し、CPU起床を0にして待機バッテリー消費を完全抑制
  void enterColdSleep() {
    if (_ticker != null && _ticker!.isActive) {
      debugPrint('🌙 [MatchTimer] enterColdSleep: Tickerを一時停止（完全コールドスリープ）');
      _ticker?.cancel();
      _ticker = null;
    }
  }

  /// 🔋 【Plan 2-2】フォアグラウンド復帰時のコールドスリープ解除＆時刻同期補正
  void resumeFromColdSleep() {
    final currentId = _activeMatchId;
    if (currentId != null && _expectedIsRunning) {
      debugPrint(
        '☀️ [MatchTimer] resumeFromColdSleep: 絶対時刻同期補正＆Ticker再開 ($currentId)',
      );
      syncOnAppResume(currentId);
    }
  }

  void startLocalTicker(String matchId, {bool isImmediateStart = false}) {
    _activeMatchId = matchId;
    debugPrint(
      '🕒 [MatchTimer] startLocalTicker requested. matchId=$matchId, immediate=$isImmediateStart',
    );
    // ★ 修正: 手動操作の直後（2秒以内）にクラウドの古いデータによる自動再開（ゴースト再起動）を完全に防ぐ
    final diff = ref
        .read(timeSourceProvider)
        .now()
        .difference(_lastToggledAt)
        .inSeconds;
    if (!isImmediateStart && diff < 2) {
      debugPrint(
        '🕒 [MatchTimer] startLocalTicker BLOCKED (ghost restart prevention). diff=$diff sec',
      );
      return;
    }

    _expectedIsRunning = true;

    // ★ 修正: 既にタイマーが動いている場合は再開を禁止
    if (_ticker != null && _ticker!.isActive) {
      debugPrint(
        '🕒 [MatchTimer] startLocalTicker: Ticker already active. Ignoring.',
      );
      return;
    }

    // 🔋 【Phase 10 & Plan 2】アダプティブ省電力・サーマル冷却:
    // 通常の「分:秒」表示時は1000ms周期（秒間1回）に抑えてCPU起床を90%削減。
    // 0.1秒精度が要求される代表戦・延長戦のみ、ガバナー推奨の高精度Tick（100ms）を動的適用。
    final governor = ref.read(thermalPowerGovernorProvider);
    governor.recordUserActivity();
    final match = _getMatch(matchId);
    final isHighPrecision =
        match?.matchType == '代表戦' || match?.matchType == '延長戦';
    final tickInterval = governor.getTickIntervalForMatch(
      isHighPrecision: isHighPrecision,
    );

    debugPrint(
      '🕒 [MatchTimer] startLocalTicker: Ticker STARTED (interval=${tickInterval.inMilliseconds}ms, highPrecision=$isHighPrecision).',
    );
    _ticker?.cancel();
    final fallbackStartedAt = ref.read(timeSourceProvider).now();

    _ticker = Timer.periodic(tickInterval, (timer) {
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

      final now = ref.read(timeSourceProvider).now();
      int currentDerived = effectiveMatch.calculateRemainingSeconds(now);

      final currentUiState = ref.read(liveRemainingSecondsProvider(matchId));

      if (currentDerived != currentUiState) {
        ref.read(liveRemainingSecondsProvider(matchId).notifier).state =
            currentDerived;

        if (currentDerived == 0 &&
            match.matchType != '代表戦' &&
            match.matchType != '延長戦') {
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
    if (ref
            .read(timeSourceProvider)
            .now()
            .difference(_lastToggledAt)
            .inSeconds <
        2) {
      debugPrint(
        '🕒 [MatchTimer] stopLocalTicker BLOCKED (ghost stop prevention).',
      );
      return;
    }
    _expectedIsRunning = false;
    _ticker?.cancel();
  }

  Future<void> toggleTimer(String matchId) async {
    final match = _getMatch(matchId);
    if (match == null) return;

    final newIsRunning = !_expectedIsRunning;
    final now = ref.read(timeSourceProvider).now();
    if (newIsRunning &&
        match.calculateRemainingSeconds(now) <= 0 &&
        match.matchType != '代表戦') {
      return;
    }

    debugPrint(
      '🕒 [MatchTimer] toggleTimer: Toggling timer to isRunning=$newIsRunning',
    );
    _lastToggledAt = now;
    _expectedIsRunning = newIsRunning;

    MatchLifecycleState currentState =
        MatchLifecycleStateLegacyExt.fromLegacyString(match.status);
    if (newIsRunning) {
      if (currentState == MatchLifecycleState.ready ||
          currentState == MatchLifecycleState.notStarted ||
          currentState == MatchLifecycleState.waitingForPlayers) {
        currentState = MatchStateMachine.transition(
          currentState,
          StateTransitionEvent.startMatch,
        );
      } else if (currentState == MatchLifecycleState.paused) {
        currentState = MatchStateMachine.transition(
          currentState,
          StateTransitionEvent.resume,
        );
      }
    } else {
      if (currentState == MatchLifecycleState.inProgress ||
          currentState == MatchLifecycleState.encho) {
        currentState = MatchStateMachine.transition(
          currentState,
          StateTransitionEvent.pause,
        );
      } else {
        // ★ 万が一状態が in_progress 以外なのにタイマーが回っていた場合でも強制的に止める
        currentState = MatchLifecycleState.paused;
      }
    }

    MatchModel updatedMatch = match.transition(currentState);

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
      // ★ 修正 (Plan 3-①): 天井秒からの逆算を撤廃し、ミリ秒端数の生差分を直接加算して100%の精度を維持
      int additionalMs = 0;
      if (match.timerStartedAt != null) {
        additionalMs = now.difference(match.timerStartedAt!).inMilliseconds;
        if (additionalMs < 0) additionalMs = 0;
      }
      final newAccMs = match.accumulatedPauseDurationMs + additionalMs;

      updatedMatch = match
          .transition(currentState)
          .copyWith(
            timerStartedAt: null,
            timerPausedAt: now,
            accumulatedPauseDurationMs: newAccMs,
          );

      final derivedSeconds = updatedMatch.calculateRemainingSeconds(now);
      debugPrint(
        '🕒 [MatchTimer] toggleTimer(STOP): newAccMs=$newAccMs (+${additionalMs}ms), derivedSeconds=$derivedSeconds',
      );

      ref.read(liveRemainingSecondsProvider(matchId).notifier).state =
          derivedSeconds;
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
      ref.read(timeSourceProvider).now(),
      isTimerStopping: isTimeUp,
    );

    if (isTimeUp) {
      // ★ 修正: タイムアップ時も確実にステータスを一時停止状態にし、裏で回り続けるのを防ぐ
      updatedMatch = updatedMatch
          .transition(MatchLifecycleState.paused)
          .copyWith(
            timerPausedAt: ref.read(timeSourceProvider).now(),
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

  /// ★ Step 3-2: バックグラウンド復帰・再開時対策プロトコル
  /// アプリがバックグラウンドから復帰した際、あるいは通信復旧時に古いUI状態（stale state）を破棄し、
  /// タイムソースの絶対真実に基づいて残り秒数を決定論的に再プロジェクション（再計算）します。
  void syncOnAppResume(String matchId) {
    debugPrint('🕒 [MatchTimer] syncOnAppResume triggered. matchId=$matchId');
    final match = _getMatch(matchId);
    if (match == null) return;

    final now = ref.read(timeSourceProvider).now();
    // 蓄積された遅延や不確定なUIキャッシュを完全破棄し、ドメインモデルから現在の残り時間を厳格に再計算
    final derivedSeconds = match.calculateRemainingSeconds(now);

    ref.read(liveRemainingSecondsProvider(matchId).notifier).state =
        derivedSeconds;

    // タイマーが本来稼働中であるべき（timerIsRunning == true）かつローカルの ticker が停止している場合は自動復旧
    if (match.timerIsRunning && (_ticker == null || !_ticker!.isActive)) {
      debugPrint(
        '🕒 [MatchTimer] syncOnAppResume: Auto-restarting local ticker for running match.',
      );
      startLocalTicker(matchId, isImmediateStart: true);
    }
  }

  void dispose() {
    _expectedIsRunning = false;
    _ticker?.cancel();
    _ticker = null;
    _activeMatchId = null;
    _lifecycleListener?.dispose();
  }

  MatchModel? _getMatch(String id) {
    final matches = ref.read(matchListProvider);
    return matches.where((m) => m.id == id).firstOrNull;
  }
}
