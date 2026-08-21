import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_quick_action_buttons.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ViewerQuickActionButtons renders buttons correctly', (
    tester,
  ) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: const Scaffold(
            body: ViewerQuickActionButtons(
              tournamentId: 't1',
              enableLiquidGlass: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('試合結果一覧 (PDF/CSV)'), findsOneWidget);
    expect(find.text('大会プログラムを見る（閲覧専用）'), findsOneWidget);
  });
}
