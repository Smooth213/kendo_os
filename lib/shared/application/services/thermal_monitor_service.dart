import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🌡️ 端末の熱状態レベル
enum ThermalSensorStatus {
  /// 平常状態（約39℃以下）: 通常動作
  nominal,

  /// 軽度上昇（約39〜40℃）: 注意
  fair,

  /// 警戒レベル（約41℃以上）: Serious / Severe。冷却モード推奨
  serious,

  /// 危険レベル（約45℃以上）: Critical。極限省電力・避難必須
  critical,
}

/// 🌡️ サーマル監視サービス
///
/// iOS (`ProcessInfo.thermalState`) や Android (`PowerManager.thermalStatus`) 等の
/// 端末温度状況を監視し、イベントを配信します。
class ThermalMonitorService extends ChangeNotifier {
  ThermalSensorStatus _status = ThermalSensorStatus.nominal;
  ThermalSensorStatus? _overrideStatus;
  StreamSubscription? _subscription;

  ThermalSensorStatus get currentStatus => _overrideStatus ?? _status;

  /// テストやデバッグ用のステータス上書き
  void setOverrideStatus(ThermalSensorStatus? status) {
    if (_overrideStatus != status) {
      _overrideStatus = status;
      notifyListeners();
    }
  }

  /// 内部ステータス更新（プラットフォームイベント受信用）
  void updateStatus(ThermalSensorStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      if (_overrideStatus == null) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final thermalMonitorServiceProvider =
    ChangeNotifierProvider<ThermalMonitorService>((ref) {
      return ThermalMonitorService();
    });
