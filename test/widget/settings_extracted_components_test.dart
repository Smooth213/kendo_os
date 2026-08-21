import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_test_action_panel.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ Settings Extracted Components Widget Tests', () {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    testWidgets('1. SettingsSectionHeader & Footer render text correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: const Scaffold(
            body: Column(
              children: [
                SettingsSectionHeader(title: '表示設定'),
                SettingsSectionFooter(text: '表示に関する説明文です'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('表示設定'), findsOneWidget);
      expect(find.text('表示に関する説明文です'), findsOneWidget);
    });

    testWidgets('2. SettingsBlock renders children and divider', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: SettingsBlock(
              enableLiquidGlass: false,
              themeColors: themeColors,
              children: const [Text('項目1'), Text('項目2')],
            ),
          ),
        ),
      );

      expect(find.text('項目1'), findsOneWidget);
      expect(find.text('項目2'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('3. SettingsSwitchTile toggles value correctly', (
      WidgetTester tester,
    ) async {
      bool switchValue = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SettingsSwitchTile(
                  title: '通知スイッチ',
                  value: switchValue,
                  icon: Icons.notifications,
                  iconBgColor: AppKendoColors.blue,
                  onChanged: (val) {
                    setState(() => switchValue = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('通知スイッチ'), findsOneWidget);
      expect(switchValue, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(switchValue, isTrue);
    });

    testWidgets('4. SettingsTestActionPanel responds to tap gestures', (
      WidgetTester tester,
    ) async {
      final settings = SettingsModel(confirmBehavior: 'tap');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: SettingsTestActionPanel(
              settings: settings,
              enableLiquidGlass: false,
              themeColors: themeColors,
            ),
          ),
        ),
      );

      expect(find.text('下のボタンをタップしてテスト'), findsOneWidget);
      expect(find.text('テスト用：試合終了ボタン'), findsOneWidget);

      await tester.tap(find.text('テスト用：試合終了ボタン'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('✅ 確定しました (通常タップ)'), findsOneWidget);
    });
  });
}
