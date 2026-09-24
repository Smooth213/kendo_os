import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/web_app_qr_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:qr_flutter/qr_flutter.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() {
    return const SettingsModel();
  }

  @override
  Future<void> updateSettings(SettingsModel newSettings) async {
    state = newSettings;
  }
}

void main() {
  group('Webアプリ版QRコード ダイアログ＆設定画面連携テスト', () {
    testWidgets('WebAppQrDialog 単体表示テスト - URLとQRコードが表示されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(body: WebAppQrDialog()),
        ),
      );
      await tester.pumpAndSettle();

      // タイトル・説明・URLの検証
      expect(find.text('Webアプリ版（kendo_os）'), findsOneWidget);
      expect(find.text('https://kendo-os-beta.web.app'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('URLをシェア・共有'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('SettingsScreen から Webアプリ版QRコード を開けること', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _FakeSettingsNotifier()),
            bandGroupsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 設定画面内に「Webアプリ版 QRコード」タイルが存在するか確認
      final tileFinder = find.text('Webアプリ版 QRコード');
      expect(tileFinder, findsOneWidget);

      // タップしてダイアログを表示
      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      // ダイアログが開いたことを確認
      expect(find.byType(WebAppQrDialog), findsOneWidget);
      expect(find.text('https://kendo-os-beta.web.app'), findsOneWidget);

      // 「閉じる」をタップして閉じる
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      expect(find.byType(WebAppQrDialog), findsNothing);
    });
  });
}
