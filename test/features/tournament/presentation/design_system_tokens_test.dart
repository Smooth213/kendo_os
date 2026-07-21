import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

void main() {
  group('🛡️ Design System & Color Tokens Verification Tests', () {
    test('1. AppThemeColors - モード別カラーパレット検証', () {
      // Light Mode
      final normalLight = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      expect(normalLight.primaryAccent, Colors.indigo.shade700);
      expect(normalLight.rosePink, const Color(0xFFE06287));

      final bunaiksenLight = AppThemeColors.ofMode(
        isDark: false,
        mode: 'bunaiksen',
      );
      expect(bunaiksenLight.primaryAccent, Colors.deepPurple.shade700);
      expect(bunaiksenLight.rosePink, const Color(0xFFE06287));

      final normalViewerLight = AppThemeColors.ofMode(
        isDark: false,
        mode: 'normal_viewer',
      );
      expect(normalViewerLight.primaryAccent, Colors.blueGrey.shade700);

      final bunaiksenViewerLight = AppThemeColors.ofMode(
        isDark: false,
        mode: 'bunaiksen_viewer',
      );
      expect(bunaiksenViewerLight.primaryAccent, Colors.purple.shade700);

      // Dark Mode
      final normalDark = AppThemeColors.ofMode(isDark: true, mode: 'normal');
      expect(normalDark.primaryAccent, Colors.indigo.shade400);

      final bunaiksenDark = AppThemeColors.ofMode(
        isDark: true,
        mode: 'bunaiksen',
      );
      expect(bunaiksenDark.primaryAccent, Colors.deepPurple.shade300);

      final normalViewerDark = AppThemeColors.ofMode(
        isDark: true,
        mode: 'normal_viewer',
      );
      expect(normalViewerDark.primaryAccent, Colors.blueGrey.shade400);

      final bunaiksenViewerDark = AppThemeColors.ofMode(
        isDark: true,
        mode: 'bunaiksen_viewer',
      );
      expect(bunaiksenViewerDark.primaryAccent, Colors.purple.shade300);
    });

    testWidgets('2. SettingsScreen カード角丸（16dp）検証', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      // Find Containers in SettingsScreen
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      bool foundAtLeastOneSettingsBlock = false;
      for (final element in tester.widgetList<Container>(containerFinder)) {
        final decoration = element.decoration;
        if (decoration is BoxDecoration) {
          final borderRadius = decoration.borderRadius;
          if (borderRadius is BorderRadius) {
            if (borderRadius == BorderRadius.circular(16)) {
              foundAtLeastOneSettingsBlock = true;
            }
          }
        }
      }
      expect(
        foundAtLeastOneSettingsBlock,
        isTrue,
        reason: 'At least one settings block must have corner radius 16',
      );
    });
  });
}
