import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kendo_os/main.dart' as legacy_main;
import 'package:kendo_os/bootstrap/app_startup.dart';
import 'package:kendo_os/shared/errors/global_error_handler.dart';

/// ============================================================================
/// 🌐 PWA App Entry Point (Phase 5: Webブラウザ・PWA専用)
/// ============================================================================
/// インストール不要のWebアプリ版（PWA）として動作する際のエントリポイントです。
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
