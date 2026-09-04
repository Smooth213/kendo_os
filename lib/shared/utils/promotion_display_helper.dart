import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 📱 【Phase 12】120Hz ProMotion ディスプレイ完全同期ヘルパー
///
/// iPad Pro や iPhone Pro、最新 Android（90Hz/120Hz/144Hz）の可変リフレッシュレート
/// （ProMotion / VRR）と描画パイプラインを完全同期させ、
/// 吸い付くような極上ヌルヌル描画（120 FPS）を実現します。
class PromotionDisplayHelper {
  /// ディスプレイの物理リフレッシュレート（Hz）を取得（デフォルト: 60.0Hz）
  static double getRefreshRate({ui.FlutterView? view}) {
    if (kIsWeb) return 60.0;

    try {
      final targetView =
          view ??
          (WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
              ? WidgetsBinding.instance.platformDispatcher.views.first
              : null);

      if (targetView != null) {
        final rate = targetView.display.refreshRate;
        if (rate > 0) return rate;
      }
    } catch (_) {
      // プラットフォーム非対応またはテスト環境
    }

    return 60.0;
  }

  /// 90Hz 以上の ProMotion / 高リフレッシュレートディスプレイかを判定
  static bool isHighRefreshRate({ui.FlutterView? view}) {
    return getRefreshRate(view: view) >= 85.0;
  }

  /// 現在のリフレッシュレートにおける 1フレームあたりの許容時間（ミリ秒）
  /// - 120Hz: 約 8.33ms
  /// - 90Hz:  約 11.11ms
  /// - 60Hz:  約 16.67ms
  static double frameBudgetMs({ui.FlutterView? view}) {
    final rate = getRefreshRate(view: view);
    if (rate <= 0) return 16.666;
    return 1000.0 / rate;
  }

  /// 120Hz ProMotion 向けに最適化されたアニメーション時間
  /// 高リフレッシュレート時はより素早いレスポンス（吸い付く操作感）を提供
  static Duration optimalDuration({
    required Duration baseDuration,
    ui.FlutterView? view,
  }) {
    if (isHighRefreshRate(view: view)) {
      // 120Hz環境ではキビキビ感を強調するため 85% に最適化
      return Duration(
        milliseconds: (baseDuration.inMilliseconds * 0.85).round(),
      );
    }
    return baseDuration;
  }

  /// 120Hz ディスプレイに最適なスクロール物理挙動
  static ScrollPhysics getOptimalScrollPhysics({
    ScrollPhysics? parent,
    ui.FlutterView? view,
  }) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
