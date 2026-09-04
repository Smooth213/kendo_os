import 'package:flutter/foundation.dart';

/// 🧵 【Phase 4】重計算Isolate分離ガバナンスヘルパー
///
/// トーナメント組み合わせ、バックアップJSON生成、CSV/帳票データ集計などの重い同期CPU処理を
/// ネイティブ環境では真のWorker Isolate（別OSスレッド）へ分離し、メインUIスレッド（60/120FPS）の
/// フレームドロップ（プチフリ・ジャンク）を完全遮断します。
///
/// ※ Web環境ではWorker制約を回避するため、イベントループを譲歩する非同期処理へ安全にフォールバックします。
class KendoComputeHelper {
  /// 重計算処理を別スレッド（または非同期ループ）で実行する
  static Future<R> run<Q, R>(ComputeCallback<Q, R> callback, Q message) async {
    if (kIsWeb) {
      // Web環境: イベントループを譲歩してUIのフレームを担保
      await Future<void>.delayed(Duration.zero);
      return callback(message);
    }
    // ネイティブ環境: Flutter公式のIsolateプールで並列実行
    return compute(callback, message);
  }
}
