import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_bottom_bar.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CategoryRuleEditorBottomBar renders buttons and triggers tap', (
    tester,
  ) async {
    bool saved = false;
    bool cancelled = false;
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: CategoryRuleEditorBottomBar(
              enableLiquidGlass: false,
              onCancel: () => cancelled = true,
              onSave: () => saved = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('キャンセル'), findsOneWidget);
    expect(find.text('設定を保存'), findsOneWidget);

    await tester.tap(find.text('キャンセル'));
    await tester.pump();
    expect(cancelled, isTrue);

    await tester.tap(find.text('設定を保存'));
    await tester.pump();
    expect(saved, isTrue);
  });
}
