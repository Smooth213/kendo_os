import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/errors/emergency_crash_preserver.dart';

class GlobalErrorHandler {
  static void runWithZone(FutureOr<void> Function() body) {
    runZonedGuarded(
      () async {
        // 🛡️ ガバナンス防衛：runAppと完全に同一のZone内部の、絶対前線で初期化しZone mismatchを根絶
        WidgetsFlutterBinding.ensureInitialized();

        FlutterError.onError = (details) {
          FlutterError.dumpErrorToConsole(details);
          // 🛡️ 【Plan 3-3】Fatal Crash Trap: 直前状態の緊急退避
          EmergencyCrashPreserver.preserveOnCrash(
            error: details.exception,
            stackTrace: details.stack,
          );
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          debugPrint('Platform Error: $error');
          // 🛡️ 【Plan 3-3】Fatal Crash Trap: 直前状態の緊急退避
          EmergencyCrashPreserver.preserveOnCrash(
            error: error,
            stackTrace: stack,
          );
          return true;
        };

        // 完全に初期化された安全なゾーン内で、メイン処理（runApp）を執行
        await body();
      },
      (error, stack) {
        debugPrint('Zone Error: $error');
        // 🛡️ 【Plan 3-3】Fatal Crash Trap: 直前状態の緊急退避
        EmergencyCrashPreserver.preserveOnCrash(
          error: error,
          stackTrace: stack,
        );
      },
    );
  }
}
