import 'dart:ui';
import 'web_theme_syncer_stub.dart'
    if (dart.library.js_interop) 'web_theme_syncer_web.dart';

void applyWebThemeSync(bool isDark) {
  syncWebTheme(isDark);
}

void applyWebThemeColor(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  final hex = '#$r$g$b';
  syncWebThemeColor(hex);
}
