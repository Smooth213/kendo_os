import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 ドック独立型タイマーの動作モード
enum DockTimerMode { countdown, stopwatch }

/// 🥋 ドック独立型タイマーの状態
class DockTimerState {
  final DockTimerMode mode;
  final int initialSeconds;
  final int remainingSeconds;
  final int elapsedSeconds;
  final bool isRunning;
  final bool isFinished;

  const DockTimerState({
    this.mode = DockTimerMode.countdown,
    this.initialSeconds = 180, // デフォルト 3分
    this.remainingSeconds = 180,
    this.elapsedSeconds = 0,
    this.isRunning = false,
    this.isFinished = false,
  });

  DockTimerState copyWith({
    DockTimerMode? mode,
    int? initialSeconds,
    int? remainingSeconds,
    int? elapsedSeconds,
    bool? isRunning,
    bool? isFinished,
  }) {
    return DockTimerState(
      mode: mode ?? this.mode,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  /// 残り時間または経過時間の整形表示 (例: "02:45")
  String get formattedDisplay {
    final target = mode == DockTimerMode.countdown
        ? remainingSeconds
        : elapsedSeconds;
    final m = (target ~/ 60).toString().padLeft(2, '0');
    final s = (target % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// プログレス率 (0.0 〜 1.0)
  double get progress {
    if (mode == DockTimerMode.stopwatch || initialSeconds <= 0) return 1.0;
    return (remainingSeconds / initialSeconds).clamp(0.0, 1.0);
  }
}

/// 🥋 ドック独立型タイマーの操作・状態管理Notifier
class DockTimerNotifier extends StateNotifier<DockTimerState> {
  final Ref _ref;
  Timer? _timer;

  DockTimerNotifier(this._ref) : super(const DockTimerState());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// プリセット時間（秒）をセット
  void setPreset(int seconds) {
    _timer?.cancel();
    state = state.copyWith(
      mode: DockTimerMode.countdown,
      initialSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: false,
      isFinished: false,
    );
    AppHaptics.selection();
  }

  /// 任意カスタム時間（分・秒）を手入力・ダイヤルでセット
  void setCustomTime(int minutes, int seconds) {
    final total = (minutes * 60 + seconds).clamp(1, 3599);
    setPreset(total);
  }

  /// モード切替（カウントダウン ⇄ ストップウォッチ）
  void toggleMode() {
    _timer?.cancel();
    final newMode = state.mode == DockTimerMode.countdown
        ? DockTimerMode.stopwatch
        : DockTimerMode.countdown;
    state = state.copyWith(
      mode: newMode,
      isRunning: false,
      isFinished: false,
      remainingSeconds: state.initialSeconds,
      elapsedSeconds: 0,
    );
    AppHaptics.selection();
  }

  /// タイマーの開始 / 一時停止トグル
  void toggleStartPause() {
    if (state.isRunning) {
      pause();
    } else {
      start();
    }
  }

  /// 計時開始
  void start() {
    if (state.isRunning) return;
    _timer?.cancel();

    // 終了状態からの再開ならリセット
    if (state.mode == DockTimerMode.countdown && state.remainingSeconds <= 0) {
      state = state.copyWith(
        remainingSeconds: state.initialSeconds,
        isFinished: false,
      );
    }

    state = state.copyWith(isRunning: true, isFinished: false);
    AppHaptics.medium();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.mode == DockTimerMode.countdown) {
        if (state.remainingSeconds > 1) {
          state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        } else {
          _onCountdownFinished();
        }
      } else {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  /// 一時停止
  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    AppHaptics.light();
  }

  /// リセット
  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: state.initialSeconds,
      elapsedSeconds: 0,
      isRunning: false,
      isFinished: false,
    );
    AppHaptics.selection();
  }

  /// 時間を追加（+30秒、+60秒など）
  void addSeconds(int extraSeconds) {
    if (state.mode == DockTimerMode.countdown) {
      final newRemaining = state.remainingSeconds + extraSeconds;
      final newInitial = state.initialSeconds + extraSeconds;
      state = state.copyWith(
        initialSeconds: newInitial,
        remainingSeconds: newRemaining,
        isFinished: false,
      );
      AppHaptics.selection();
    }
  }

  /// カウントダウン終了処理
  void _onCountdownFinished() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: 0,
      isRunning: false,
      isFinished: true,
    );

    // 体育館の喧騒でも気付くハプティクス＆サウンド通知
    AppHaptics.heavy();
    try {
      final soundService = _ref.read(soundServiceProvider);
      soundService.playFinishFanfare();
    } catch (e) {
      debugPrint('⚠️ [DockTimer] Finish sound error: $e');
    }
  }
}

/// 🥋 ドック独立型タイマーのグローバルプロバイダー
final dockTimerProvider =
    StateNotifierProvider<DockTimerNotifier, DockTimerState>((ref) {
      return DockTimerNotifier(ref);
    });
