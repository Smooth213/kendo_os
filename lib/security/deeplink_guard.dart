import 'package:kendo_os/shared/config/runtime_mode.dart';

class DeepLinkGuard {
  static bool canAccess(String targetUri) {
    const mode = RuntimeMode.beta;
    if (mode == RuntimeMode.beta) {
      if (targetUri.contains('observability') ||
          targetUri.contains('audit') ||
          targetUri.contains('rule-config') ||
          targetUri.contains('master')) {
        return false;
      }
    }
    return true;
  }
}
