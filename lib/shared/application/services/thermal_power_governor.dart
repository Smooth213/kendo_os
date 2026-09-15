import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/application/services/thermal_monitor_service.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

/// 🔋 【Phase 10】端末動作モード（サーマル冷却・省電力段階）
enum ThermalPowerMode {
  /// 通常モード: 100ms の超高精度・最高レスポンス動作
  normal,

  /// エコ冷却モード: 500ms 間隔でCPU負荷を半減させ、端末発熱を防止
  ecoCooling,

  /// 極限省電力モード: 1000ms (1秒) 間隔でCPUウェイクアップを最小化し、バッテリーを最長化
  ultraSave,
}

/// 🔔 【Phase 10】サーマル・省電力トースト通知イベント
class ThermalToastEvent {
  final String message;
  final IconData icon;
  final Color color;
  final DateTime timestamp;

  ThermalToastEvent({
    required this.message,
    required this.icon,
    required this.color,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// 🔋 【Phase 10】アダプティブ省電力・サーマル冷却ガバナー
///
/// 猛暑の体育館（40℃超環境）での終日稼働時、端末の発熱（熱暴走・画面暗転）と
/// バッテリー枯渇を防ぐため、端末ステータスや稼働状況に応じて
/// タイマー tick 間隔とポーリング負荷を動的かつ最適に適応制御します。
class ThermalPowerGovernor extends ChangeNotifier {
  ThermalPowerMode _mode = ThermalPowerMode.normal;
  String _preference = 'auto'; // 'auto', 'normal', 'ecoCooling', 'ultraSave'
  bool _isOsLowPowerMode = false;
  ThermalSensorStatus _thermalStatus = ThermalSensorStatus.nominal;
  double _batteryLevel = 1.0;
  bool _isCharging = false;
  DateTime _lastUserActivity = DateTime.now();

  // トースト通知ストリーム
  final StreamController<ThermalToastEvent> _toastController =
      StreamController<ThermalToastEvent>.broadcast();

  // クールダウン用ステート追跡
  String? _lastToastKey;
  DateTime? _lastToastTime;

  ThermalPowerMode get mode => _mode;
  String get preference => _preference;
  bool get isOsLowPowerMode => _isOsLowPowerMode;
  ThermalSensorStatus get thermalStatus => _thermalStatus;
  double get batteryLevel => _batteryLevel;
  bool get isCharging => _isCharging;
  Stream<ThermalToastEvent> get toastStream => _toastController.stream;

  /// 現在のモードに応じたタイマー推奨更新間隔
  Duration get recommendedTickInterval {
    switch (_mode) {
      case ThermalPowerMode.normal:
        return const Duration(milliseconds: 100);
      case ThermalPowerMode.ecoCooling:
        return const Duration(milliseconds: 500);
      case ThermalPowerMode.ultraSave:
        return const Duration(milliseconds: 1000);
    }
  }

  /// 🔋 【Plan 2-1】適応型可変リフレッシュレート（VRR）推奨FPS
  /// 静止時（操作後3秒経過）または発熱・省電力モード時にフレームレートを動的引き下げ
  int get targetFps {
    if (_thermalStatus == ThermalSensorStatus.critical ||
        _mode == ThermalPowerMode.ultraSave) {
      return 15;
    }
    if (_thermalStatus == ThermalSensorStatus.serious ||
        _mode == ThermalPowerMode.ecoCooling) {
      return 30;
    }
    // 通常モード時：操作後3秒以上経過した静止状態は30fps、10秒以上は15fpsへ動的降下
    final idleSeconds = DateTime.now().difference(_lastUserActivity).inSeconds;
    if (idleSeconds >= 10) {
      return 15;
    } else if (idleSeconds >= 3) {
      return 30;
    }
    return 60;
  }

  /// 🔋 【Plan 2-1】VRRによるフレームレート制限中かどうかの判定
  bool get isVrrThrottled => targetFps < 60;

  /// 🔋 【Plan 2-1】VRR推奨フレーム間隔
  Duration get animationFrameDuration =>
      Duration(milliseconds: (1000 / targetFps).round());

  /// 🔋 【Plan 2】試合タイマー用のアダプティブ更新間隔
  /// 通常の「分:秒」表示では1000ms（毎秒1回）に抑えてCPU起床を90%削減し、
  /// 代表戦・延長戦などの0.1秒精度要求時のみ高精度Tick（100ms）を動的適用する
  Duration getTickIntervalForMatch({bool isHighPrecision = false}) {
    if (isHighPrecision) {
      return recommendedTickInterval;
    }
    if (_mode == ThermalPowerMode.normal) {
      return const Duration(milliseconds: 1000);
    }
    return recommendedTickInterval;
  }

  /// ユーザー設定ポリシー（preference）の更新
  void updatePreference(String preference) {
    if (_preference != preference) {
      _preference = preference;
      _recalculateMode();
    }
  }

  /// 端末サーマルステータスの更新
  void updateThermalStatus(ThermalSensorStatus status) {
    if (_thermalStatus != status) {
      final oldStatus = _thermalStatus;
      _thermalStatus = status;
      _recalculateMode(thermalTransitionFrom: oldStatus);
    }
  }

  /// OS低電力モードおよびバッテリー状態の更新
  void updateBatteryInfo({
    required double batteryLevel,
    required bool isCharging,
    required bool isOsLowPowerMode,
  }) {
    final oldLowPower = _isOsLowPowerMode;
    _batteryLevel = batteryLevel;
    _isCharging = isCharging;
    _isOsLowPowerMode = isOsLowPowerMode;

    final lowPowerChanged = oldLowPower != isOsLowPowerMode;
    _recalculateMode(lowPowerStateChanged: lowPowerChanged);
  }

  /// ユーザー操作（タップ等）を記録し、アクティブ状態へ復元
  void recordUserActivity() {
    _lastUserActivity = DateTime.now();
    // 自動モードかつ極限省電力時、温度がCriticalでなければ復帰を試みる
    if (_preference == 'auto' &&
        _mode == ThermalPowerMode.ultraSave &&
        _thermalStatus != ThermalSensorStatus.critical &&
        _batteryLevel > 0.15) {
      _recalculateMode(triggeredByUserActivity: true);
    } else if (_preference == 'normal' &&
        _mode != ThermalPowerMode.normal &&
        _thermalStatus != ThermalSensorStatus.critical) {
      _recalculateMode(triggeredByUserActivity: true);
    }
  }

  /// 手動または直接的なモード切り替え（テスト・UI直接操作用）
  void setMode(ThermalPowerMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      enforceMemoryLimits();
      debugPrint(
        '🔋 [Thermal Governor] モード移行: $newMode (Tick間隔: ${recommendedTickInterval.inMilliseconds}ms)',
      );
      notifyListeners();
    }
  }

  /// バッテリー残量と充電状態からの旧API互換メソッド
  void evaluateBatteryState({
    required double batteryLevel,
    required bool isCharging,
  }) {
    updateBatteryInfo(
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      isOsLowPowerMode: _isOsLowPowerMode,
    );
  }

  /// モードの再計算とトースト判定
  void _recalculateMode({
    ThermalSensorStatus? thermalTransitionFrom,
    bool lowPowerStateChanged = false,
    bool triggeredByUserActivity = false,
  }) {
    ThermalPowerMode targetMode;

    // =========================================================================
    // 🥇 優先度 1: 【温度（端末保護・最優先）】
    // 猛暑環境で端末が熱暴走・強制終了すると試合記録が消滅・中断するため、
    // 危険温度（41℃/45℃）ではユーザーの手動設定に関わらず強制で冷却・避難します。
    // =========================================================================
    if (_thermalStatus == ThermalSensorStatus.critical) {
      targetMode = ThermalPowerMode.ultraSave;
      _emitToastIfNeeded(
        key: 'critical',
        message: '🔥 端末の高温警戒（約45℃）：極限省電力を作動しました。直射日光を避けてください',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEF4444),
      );
    } else if (_thermalStatus == ThermalSensorStatus.serious) {
      // 41℃警戒時：手動が通常高速(normal)であっても熱暴走防止のためエコ冷却へ強制移行
      if (_preference == 'ultraSave') {
        targetMode = ThermalPowerMode.ultraSave;
      } else {
        targetMode = ThermalPowerMode.ecoCooling;
        _emitToastIfNeeded(
          key: 'serious',
          message: '🌡️ 端末の発熱を検知（約41℃）：エコ冷却モードを作動しました',
          icon: Icons.thermostat_rounded,
          color: const Color(0xFFF59E0B),
        );
      }
    } else {
      // 温度が平常（Nominal / Fair）に復帰した場合の通知
      if (thermalTransitionFrom == ThermalSensorStatus.serious ||
          thermalTransitionFrom == ThermalSensorStatus.critical) {
        _emitToastIfNeeded(
          key: 'nominal_recovery',
          message: '❄️ 端末の冷却完了：通常高速モードに復帰しました',
          icon: Icons.ac_unit_rounded,
          color: const Color(0xFF10B981),
        );
      }

      // =========================================================================
      // 🥈 優先度 2: 【手動設定（ユーザーの意志固定）】
      // 温度が安全な平常範囲内であれば、ユーザーの固定設定を100%遵守します。
      // （OS低電力モードやバッテリー残量による自動変更をブロック）
      // =========================================================================
      if (_preference != 'auto') {
        switch (_preference) {
          case 'normal':
            targetMode = ThermalPowerMode.normal;
            break;
          case 'ecoCooling':
            targetMode = ThermalPowerMode.ecoCooling;
            break;
          case 'ultraSave':
            targetMode = ThermalPowerMode.ultraSave;
            break;
          default:
            targetMode = ThermalPowerMode.normal;
        }
      } else {
        // =========================================================================
        // 🥉 優先度 3: 【自動適応（OS低電力モード & バッテリー残量）】
        // 手動が「自動適応(auto)」の時のみ、OS低電力モードや電池残量に賢く追従します。
        // =========================================================================
        if (_isOsLowPowerMode) {
          // 低電力モードON時：残量に応じて「エコ冷却 (500ms)」と「極限省電力 (1000ms)」を自動切り替え
          if (_batteryLevel <= 0.15) {
            targetMode = ThermalPowerMode.ultraSave;
            if (_mode != ThermalPowerMode.ultraSave || lowPowerStateChanged) {
              _emitToastIfNeeded(
                key: 'os_low_power_ultra',
                message: '🔋 低電力モード＆バッテリー低下（15%以下）：極限省電力を作動しました',
                icon: Icons.energy_savings_leaf_rounded,
                color: const Color(0xFFF59E0B),
              );
            }
          } else {
            targetMode = ThermalPowerMode.ecoCooling;
            if (lowPowerStateChanged || _mode == ThermalPowerMode.ultraSave) {
              _emitToastIfNeeded(
                key: 'os_low_power_eco',
                message: '🔋 OSの低電力モードを検知：エコ冷却モードを作動しました',
                icon: Icons.battery_charging_full_rounded,
                color: const Color(0xFF10B981),
              );
            }
          }
        } else {
          // バッテリー残量 & アイドル
          if (_isCharging) {
            if (_batteryLevel <= 0.10) {
              targetMode = ThermalPowerMode.ecoCooling;
            } else {
              targetMode = ThermalPowerMode.normal;
            }
          } else {
            if (_batteryLevel <= 0.15) {
              targetMode = ThermalPowerMode.ultraSave;
            } else if (_batteryLevel <= 0.30) {
              targetMode = ThermalPowerMode.ecoCooling;
            } else {
              final idleMinutes = DateTime.now()
                  .difference(_lastUserActivity)
                  .inMinutes;
              if (idleMinutes >= 10 && !triggeredByUserActivity) {
                targetMode = ThermalPowerMode.ecoCooling;
              } else {
                targetMode = ThermalPowerMode.normal;
              }
            }
          }
        }
      }
    }

    if (_mode != targetMode) {
      _mode = targetMode;
      enforceMemoryLimits();
      debugPrint(
        '🔋 [Thermal Governor] モード移行: $targetMode (設定: $_preference, 温度: $_thermalStatus, 低電力: $_isOsLowPowerMode, Tick: ${recommendedTickInterval.inMilliseconds}ms)',
      );
      notifyListeners();
    }
  }

  /// 🔋 【Plan 2-4】サーマル状態に応じた画像キャッシュの動的適正化＆LRUメモリ保護
  void enforceMemoryLimits() {
    try {
      if (_thermalStatus == ThermalSensorStatus.critical ||
          _mode == ThermalPowerMode.ultraSave) {
        PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024;
        PaintingBinding.instance.imageCache.maximumSize = 40;
        PaintingBinding.instance.imageCache.clearLiveImages();
      } else if (_thermalStatus == ThermalSensorStatus.serious ||
          _mode == ThermalPowerMode.ecoCooling) {
        PaintingBinding.instance.imageCache.maximumSizeBytes = 35 * 1024 * 1024;
        PaintingBinding.instance.imageCache.maximumSize = 60;
      } else {
        PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;
        PaintingBinding.instance.imageCache.maximumSize = 100;
      }
    } catch (_) {}
  }

  /// クールダウン機能付きトースト発行
  void _emitToastIfNeeded({
    required String key,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    final now = DateTime.now();
    // 直前と同じキーの場合、最低30秒間は抑制する
    if (_lastToastKey == key && _lastToastTime != null) {
      final diff = now.difference(_lastToastTime!).inSeconds;
      if (diff < 30) {
        return;
      }
    }

    _lastToastKey = key;
    _lastToastTime = now;

    final event = ThermalToastEvent(
      message: message,
      icon: icon,
      color: color,
      timestamp: now,
    );
    _toastController.add(event);
  }

  @override
  void dispose() {
    _toastController.close();
    super.dispose();
  }
}

/// グローバルな省電力サーマルガバナープロバイダー
final thermalPowerGovernorProvider =
    ChangeNotifierProvider<ThermalPowerGovernor>((ref) {
      final governor = ThermalPowerGovernor();

      // 1. ユーザー設定の thermalPowerPreference を監視・同期
      final pref = ref.watch(
        settingsProvider.select((s) => s.thermalPowerPreference),
      );
      governor.updatePreference(pref);

      // 2. サーマルセンサーサービスを監視・同期
      final thermalService = ref.watch(thermalMonitorServiceProvider);
      governor.updateThermalStatus(thermalService.currentStatus);

      // 3. バッテリー状態（低電力モード・残量）を監視・同期
      final batteryState = ref.watch(batteryStateProvider);
      batteryState.whenData((data) {
        governor.updateBatteryInfo(
          batteryLevel: data.batteryLevel / 100.0,
          isCharging: false, // battery_plus の充電状態、または低電力判定
          isOsLowPowerMode: data.isInPowerSaveMode,
        );
      });

      return governor;
    });
