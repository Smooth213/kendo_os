import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'safe_pump_helper.dart';

/// 🥋 KendoOS - 標準Widgetテストラッパー
/// 各テストでのProviderScopeやTheme、Scaffold初期化の冗長なボイラープレートを排除します。
extension TestWidgetWrapperExtension on WidgetTester {
  /// テスト対象Widgetを標準のProviderScope / MaterialApp / Theme環境で描画します。
  Future<void> pumpTestWidget(
    Widget child, {
    List<Override> overrides = const [],
    bool isDark = false,
    Size? surfaceSize,
    bool autoSettle = true,
    bool wrapScaffold = true,
  }) async {
    if (surfaceSize != null) {
      view.physicalSize = surfaceSize;
      view.devicePixelRatio = 1.0;
      addTearDown(() {
        view.resetPhysicalSize();
        view.resetDevicePixelRatio();
      });
    }

    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final theme = (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
      extensions: [themeColors],
    );

    final content = wrapScaffold ? Scaffold(body: child) : child;

    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(theme: theme, home: content),
      ),
    );

    if (autoSettle) {
      await safePumpAndSettle();
    }
  }
}
