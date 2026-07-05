import 'dart:js' as js;

void triggerWebNotificationPermission() {
  try {
    final notification = js.context['Notification'];
    if (notification != null) {
      notification.callMethod('requestPermission');
    }
  } catch (_) {
    // Suppress errors if browser does not support Notification API
  }
}
