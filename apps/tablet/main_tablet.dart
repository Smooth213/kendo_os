import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kendo_os/main.dart' as legacy_main;
import 'package:kendo_os/bootstrap/app_startup.dart';
import 'package:kendo_os/shared/errors/global_error_handler.dart';

/// ============================================================================
/// 📱 Tablet App Entry Point (Phase 5: 大会本部・掲示板特化)
/// ============================================================================
/// 大会本部での全体進行管理や、電子掲示板（星取表など）としての利用に特化した
/// エントリポイントです。タブレットの広い画面領域を確実に活用するため、
/// 起動直後から画面の向きを横(Landscape)に固定します。
/// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 大会本部・掲示板用として横画面(Landscape)に固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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
