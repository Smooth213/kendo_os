import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔋 【Phase 10】端末動作モード（サーマル冷却・省電力段階）
enum ThermalPowerMode {
  /// 通常モード: 100ms の超高精度・最高レスポンス動作
  normal,

  /// エコ冷却モード: 500ms 間隔でCPU負荷を半減させ、端末発熱を防止
  ecoCooling,

  /// 極限省電力モード: 1000ms (1秒) 間隔でCPUウェイクアップを最小化し、バッテリーを最長化
  ultraSave,
}

/// 🔋 【Phase 10】アダプティブ省電力・サーマル冷却ガバナー
///
/// 猛暑の体育館（40℃超環境）での終日稼働時、端末の発熱（熱暴走・画面暗転）と
/// バッテリー枯渇を防ぐため、端末ステータスや稼働状況に応じて
/// タイマー tick 間隔とポーリング負荷を動的かつ最適に適応制御します。
class ThermalPowerGovernor {
  ThermalPowerMode _mode = ThermalPowerMode.normal;
  DateTime _lastUserActivity = DateTime.now();

  ThermalPowerMode get mode => _mode;

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

  /// ユーザー操作（タップ等）を記録し、アクティブ状態へ復元
  void recordUserActivity() {
    _lastUserActivity = DateTime.now();
    if (_mode == ThermalPowerMode.ultraSave) {
      setMode(ThermalPowerMode.normal);
    }
  }

  /// 動作モードの手動または自動切り替え
  void setMode(ThermalPowerMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      debugPrint(
        '🔋 [Thermal Governor] モード移行: $newMode (Tick間隔: ${recommendedTickInterval.inMilliseconds}ms)',
      );
    }
  }

  /// バッテリー残量（0.0 〜 1.0）と充電状態から最適な省電力モードを判定
  void evaluateBatteryState({
    required double batteryLevel,
    required bool isCharging,
  }) {
    if (isCharging) {
      // 給電中は発熱抑制のため、超低バッテリー時以外は通常動作
      if (batteryLevel <= 0.10) {
        setMode(ThermalPowerMode.ecoCooling);
      } else {
        setMode(ThermalPowerMode.normal);
      }
      return;
    }

    // バッテリー駆動時
    if (batteryLevel <= 0.15) {
      setMode(ThermalPowerMode.ultraSave);
    } else if (batteryLevel <= 0.30) {
      setMode(ThermalPowerMode.ecoCooling);
    } else {
      // アイドル時間チェック（無操作が10分以上継続時はエコ冷却へ移行）
      final idleMinutes = DateTime.now()
          .difference(_lastUserActivity)
          .inMinutes;
      if (idleMinutes >= 10) {
        setMode(ThermalPowerMode.ecoCooling);
      } else {
        setMode(ThermalPowerMode.normal);
      }
    }
  }
}

/// グローバルな省電力サーマルガバナープロバイダー
final thermalPowerGovernorProvider = Provider<ThermalPowerGovernor>((ref) {
  return ThermalPowerGovernor();
});
