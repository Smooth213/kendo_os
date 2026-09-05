import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

void main() {
  group('🛡️ Phase 4: アイコン・スピナー・スイッチ iOS洗練化 テスト', () {
    testWidgets('SettingsSwitchTile が AppSwitch を内包しタップでコールバックが発火すること', (
      tester,
    ) async {
      bool currentValue = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SettingsSwitchTile(
                  title: '通知設定',
                  icon: Icons.notifications,
                  iconBgColor: AppKendoColors.indigo,
                  value: currentValue,
                  onChanged: (val) {
                    setState(() {
                      currentValue = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('通知設定'), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);

      await tester.tap(find.byType(SettingsSwitchTile));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('ViewerSettingsBottomSheet がクラッシュせず正常に描画されること', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showAppBottomSheet(
                        context: context,
                        builder: (_) => const ViewerSettingsBottomSheet(),
                      );
                    },
                    child: const Text('Open Viewer Settings'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Viewer Settings'));
      await tester.pumpAndSettle();

      expect(find.text('表示設定'), findsOneWidget);
      expect(find.text('省エネモード（背景アニメーション停止）'), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
    });
  });
}
