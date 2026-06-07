import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ★ Phase 3で構築したブートストラップ（初期化）処理や既存のルートをインポート
// ※ 実際のルートウィジェット（MyAppなど）が定義されているファイルパスに合わせて調整してください
import 'package:kendo_os/main.dart' as legacy_main;
import 'package:kendo_os/bootstrap/app_startup.dart';
import 'package:kendo_os/shared/errors/global_error_handler.dart';

/// ============================================================================
/// 📱 Operator App Entry Point (Phase 5: 運営・審判・本部向け フル機能版)
/// ============================================================================
/// 大会本部や各コートの審判・記録員が使用する、すべての機能が解放された
/// メインのエントリポイントです。ローカルDB（Isar）や双方向同期をフル活用します。
/// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GlobalErrorHandler.runWithZone(() async {
    try {
      final container = await AppStartup.initialize();
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const legacy_main.KendoOSApp(),
        ),
      );
    } catch (e, stackTrace) {
      AppStartup.handleFatalInitError(e, stackTrace);
    }
  });
}
