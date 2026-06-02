import 'package:flutter/foundation.dart';

class PlatformBoundary {
  static bool get isWeb => kIsWeb;
  
  static void safePlatformCall(Function() ioCall, Function() webCall) {
    if (kIsWeb) {
      webCall();
    } else {
      ioCall();
    }
  }
}