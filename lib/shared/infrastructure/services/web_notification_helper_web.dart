import 'dart:js_interop';

@JS('Notification.requestPermission')
external JSAny? _jsRequestPermission();

void triggerWebNotificationPermission() {
  try {
    _jsRequestPermission();
  } catch (_) {
    // Suppress errors if Notification API is not supported in browser
  }
}
