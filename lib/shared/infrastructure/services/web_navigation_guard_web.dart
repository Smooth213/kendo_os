import 'dart:js_interop';

@JS('setBeforeUnloadActive')
external void _jsSetBeforeUnloadActive(bool active);

void setWebBeforeUnloadActive(bool active) {
  try {
    _jsSetBeforeUnloadActive(active);
  } catch (_) {
    // Suppress if not supported
  }
}
