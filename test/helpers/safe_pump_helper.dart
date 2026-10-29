import 'package:flutter_test/flutter_test.dart';

/// 🥋 KendoOS - 安全待機ヘルパー拡張
/// 無制限待機（10分ハング）を完全に防止し、安全かつ高速なテスト実行を保証します。
extension SafePumpHelper on WidgetTester {
  /// 最大2秒のタイムアウト付きで画面の描画完了を待機します。
  /// アニメーションやタイマーによる無限ハングを水際で防止します。
  Future<int> safePumpAndSettle({
    Duration duration = const Duration(milliseconds: 100),
    EnginePhase phase = EnginePhase.sendSemanticsUpdate,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    return pumpAndSettle(duration, phase, timeout);
  }
}
