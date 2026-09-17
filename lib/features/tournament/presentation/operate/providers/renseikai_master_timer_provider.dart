import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

final renseikaiMasterTimerProvider =
    NotifierProvider.family<RenseikaiMasterTimerNotifier, int, String>(() {
      return RenseikaiMasterTimerNotifier();
    });

class RenseikaiMasterTimerNotifier extends FamilyNotifier<int, String> {
  Timer? _timer;
  AppLifecycleListener? _lifecycleListener;

  @override
  int build(String arg) {
    _initLifecycleListener();
    ref.onDispose(() {
      _lifecycleListener?.dispose();
      _saveState();
      _timer?.cancel();
    });

    final prefs = ref.watch(sharedPreferencesProvider);
    final isRunning = prefs.getBool('master_timer_running_$arg') ?? false;
    final savedSeconds = prefs.getInt('master_timer_seconds_$arg') ?? -1;

    if (savedSeconds != -1) {
      if (isRunning) {
        final lastTickStr = prefs.getString('master_timer_last_tick_$arg');
        if (lastTickStr != null) {
          final lastTick = DateTime.tryParse(lastTickStr);
          if (lastTick != null) {
            final elapsed = DateTime.now().difference(lastTick).inSeconds;
            final remaining = savedSeconds - elapsed;
            if (remaining > 0) {
              state = remaining;
              Future.microtask(() => start());
              return remaining;
            } else {
              state = 0;
              return 0;
            }
          }
        }
      }
      state = savedSeconds;
      return savedSeconds;
    }

    return -1;
  }

  void initialize(int initialSeconds) {
    if (state == -1) {
      state = initialSeconds;
      _saveState();
    }
  }

  void _saveState({bool? isRunningOverride}) {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setInt('master_timer_seconds_$arg', state);
      final isRunning =
          isRunningOverride ?? (_timer != null && _timer!.isActive);
      prefs.setBool('master_timer_running_$arg', isRunning);
      if (isRunning) {
        prefs.setString(
          'master_timer_last_tick_$arg',
          DateTime.now().toIso8601String(),
        );
      }
    } catch (_) {}
  }

  void _initLifecycleListener() {
    try {
      _lifecycleListener = AppLifecycleListener(
        onStateChange: (lifecycleState) {
          if (lifecycleState == AppLifecycleState.paused ||
              lifecycleState == AppLifecycleState.inactive ||
              lifecycleState == AppLifecycleState.hidden) {
            _enterColdSleep();
          } else if (lifecycleState == AppLifecycleState.resumed) {
            _resumeFromColdSleep();
          }
        },
      );
    } catch (_) {}
  }

  /// 🔋 【待機時CPU起床ゼロ】バックグラウンド待機時の完全コールドスリープ
  void _enterColdSleep() {
    if (_timer != null && _timer!.isActive) {
      _timer?.cancel();
      _saveState(isRunningOverride: true);
    }
  }

  /// 🔋 【絶対時刻同期補正】フォアグラウンド復帰時の実時間差分補正＆タイマー再開
  void _resumeFromColdSleep() {
    final isRunning = ref.read(isMasterTimerRunningProvider(arg));
    if (!isRunning) return;

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final lastTickStr = prefs.getString('master_timer_last_tick_$arg');
      if (lastTickStr != null) {
        final lastTick = DateTime.tryParse(lastTickStr);
        if (lastTick != null) {
          final elapsed = DateTime.now().difference(lastTick).inSeconds;
          final remaining = state - elapsed;
          if (remaining > 0) {
            state = remaining;
            start();
          } else {
            state = 0;
            _timer?.cancel();
            ref.read(isMasterTimerRunningProvider(arg).notifier).state = false;
            _saveState(isRunningOverride: false);
          }
        }
      }
    } catch (_) {}
  }

  void toggleTimer() {
    if (_timer != null && _timer!.isActive) {
      pause();
    } else {
      start();
    }
  }

  void start() {
    _timer?.cancel();
    if (state <= 0) return;

    ref.read(isMasterTimerRunningProvider(arg).notifier).state = true;
    _saveState(isRunningOverride: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state > 0) {
        state--;
      } else {
        state = 0;
        t.cancel();
        ref.read(isMasterTimerRunningProvider(arg).notifier).state = false;
        _saveState();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    ref.read(isMasterTimerRunningProvider(arg).notifier).state = false;
    _saveState();
  }

  void setSeconds(int seconds) {
    state = seconds;
    _saveState();
  }
}

final isMasterTimerRunningProvider = StateProvider.family<bool, String>(
  (ref, groupName) => false,
);
