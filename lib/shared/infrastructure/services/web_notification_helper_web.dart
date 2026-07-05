import 'dart:js' as js;

void triggerWebNotificationPermission() {
  try {
    js.context.callMethod('requestNotificationPermission');
  } catch (_) {
    // Suppress errors if JavaScript method is missing or fails
  }
}
