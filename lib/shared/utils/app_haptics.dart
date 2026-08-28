import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// kendo OS 全体で統一された触覚フィードバック (Taptic Engine) を提供するユーティリティ
class AppHaptics {
  AppHaptics._();

  /// 選択時・タップ時の微細なクリック触感（iOS セレクションフィードバック）
  static void selection() {
    if (kIsWeb) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// 軽微なインタラクション時の軽い触感（ボタン押下、ダイアログ表示等）
  static void light() {
    if (kIsWeb) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// 標準的な確定アクション時の触感
  static void medium() {
    if (kIsWeb) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// スコア確定・重要アクション時の強い触感
  static void heavy() {
    if (kIsWeb) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// 操作成功・完了時の心地よい触感
  static void success() {
    if (kIsWeb) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// 操作警告・注意時の触感
  static void warning() {
    if (kIsWeb) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// エラー発生時の明確な触感
  static void error() {
    if (kIsWeb) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
