import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/auth/application/google_auth_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_google_auth_tile.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_test_action_panel.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] 設定画面 各種タイル・ブロック・Google認証・テストパネル統合検証テスト', () {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    testWidgets('Google未連携時: 「Googleアカウント連携」および「連携する」ボタンが表示されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isGoogleLinkedProvider.overrideWithValue(false),
            linkedGoogleEmailProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SettingsGoogleAuthTile()),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('Googleアカウント連携'), findsOneWidget);
      expect(find.text('PCとiPadでクイックメモや通知既読を自動同期します'), findsOneWidget);
      expect(find.text('連携する'), findsOneWidget);
      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    });

    testWidgets('Google連携済み時: 「Google連携中」とメールアドレス、同期有効ステータスが表示されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isGoogleLinkedProvider.overrideWithValue(true),
            linkedGoogleEmailProvider.overrideWithValue(
              'kendo.sensei@gmail.com',
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SettingsGoogleAuthTile()),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('Google連携中'), findsOneWidget);
      expect(find.text('kendo.sensei@gmail.com'), findsOneWidget);
      expect(find.text('クラウド同期有効（メモ・既読共有中）'), findsOneWidget);
      expect(find.text('解除'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('SettingsSectionHeaderおよびFooterにおいてテキストが正しく描画されること', (
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

    testWidgets('SettingsBlockにおいて 子要素および区切り線が正しく描画されること', (
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

    testWidgets('SettingsSwitchTileにおいて スイッチ値の切り替えが正しく動作すること', (
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
      await tester.safePumpAndSettle();

      expect(switchValue, isTrue);
    });

    testWidgets('SettingsTestActionPanelにおいて タップ操作に応答して状態が更新されること', (
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
      await tester.safePumpAndSettle();

      expect(find.text('✅ 確定しました (通常タップ)'), findsOneWidget);
    });
  });
}
