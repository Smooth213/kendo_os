import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GlobalErrorHandler {
  static void runWithZone(FutureOr<void> Function() body) {
    runZonedGuarded(() async {
      // 🛡️ ガバナンス防衛：runAppと完全に同一のZone内部の、絶対前線で初期化しZone mismatchを根絶
      WidgetsFlutterBinding.ensureInitialized();
      
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Platform Error: $error');
        return true;
      };

      // 完全に初期化された安全なゾーン内で、メイン処理（runApp）を執行
      await body();
    }, (error, stack) {
      debugPrint('Zone Error: $error');
    });
  }
}