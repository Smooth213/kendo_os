/// ★ 新規ファイル
/// Stage2 β環境において、未公開機能へのコードアクセスをランタイムレベルで防衛するゲート
class FeatureGate {
  static void ensure(bool enabled) {
    if (!enabled) {
      throw UnsupportedError('🔒 Feature disabled in Stage2 beta');
    }
  }
}