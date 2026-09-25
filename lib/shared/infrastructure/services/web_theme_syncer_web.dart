import 'dart:js_interop';

@JS('setThemeColor')
external void _jsSetThemeColor(JSString colorHex);

@JS('setThemeMode')
external void _jsSetThemeMode(bool isDark);

void syncWebTheme(bool isDark) {
  try {
    _jsSetThemeMode(isDark);
  } catch (_) {
    // Suppress if not supported or during early initialization
  }
}

void syncWebThemeColor(String colorHex) {
  try {
    _jsSetThemeColor(colorHex.toJS);
  } catch (_) {
    // Suppress if not supported
  }
}
