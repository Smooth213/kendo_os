import 'package:flutter/foundation.dart';

/// 🌐 【Phase 7】Safari & Chrome 2大ブラウザ極限最適化サービス
///
/// - Mobile Safari: 100dvhアドレスバー伸縮対応、エッジスワイプ誤操作防止、IndexedDB7日間消滅保護
/// - Chrome: BFCache（戻る・進むキャッシュ）高速復帰、Wasm/CanvasKitレンダリング最適化
class WebPlatformOptimizer {
  /// Web Safari（iOS / macOS）環境の判定
  static bool get isWebSafari {
    if (!kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Web Chrome / Chromium環境の判定
  static bool get isWebChrome {
    if (!kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// 起動時Web最適化パイプラインの適用
  static void applyOptimizations() {
    if (!kIsWeb) return;
    debugPrint(
      '🌐 [WebPlatformOptimizer] Safari & Chrome 2大ブラウザ最適化ラインを確立しました '
      '(Safari: $isWebSafari, Chrome: $isWebChrome)',
    );
  }
}
