import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kendo_os/main.dart' as legacy_main;
import 'package:kendo_os/bootstrap/app_startup.dart';
import 'package:kendo_os/shared/errors/global_error_handler.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';

/// ============================================================================
/// 📱 Viewer App Entry Point (Phase 5: 観客・保護者向け)
/// ============================================================================
/// 観客がQRコード等を読み取ってアクセスする際の軽量エントリポイントです。
/// 起動直後から「閲覧専用（Viewer）」として振る舞い、一切の書き込みを遮断します。
/// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GlobalErrorHandler.runWithZone(() async {
    try {
      final container = await AppStartup.initialize();

      // ★ アプリの起動時点から、全体を強制的に「Viewer(閲覧専用)」権限で固定する
      container
          .read(authSessionProvider.notifier)
          .establishSession(UserRole.viewer, 'default_org');

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
