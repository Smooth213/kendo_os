import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/web_app_qr_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/qr_share_dialog.dart';
import 'package:kendo_os/shared/widgets/room_join_qr_dialog_actions.dart';
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
  group('[Widget] QrDialogsAndActions 統合テスト', () {
    testWidgets('タイトル・説明・QRコード・URL・各ボタンが正常に描画されること', (tester) async {
      bool isClosed = false;
      const testUrl = 'https://kendo-os-beta.web.app/viewer-home/test_tour_999';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: QrShareDialog(
              title: '大会観戦リンク',
              themeColor: AppKendoColors.teal,
              description: '離れた場所にいる保護者や仲間も、\n試合状況をリアルタイムで安心して見守れます。',
              shareUrl: testUrl,
              shareText: '観戦URL: $testUrl',
              subtitleBadge: '大会ID: test_tour_999',
              onClose: () => isClosed = true,
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('大会観戦リンク'), findsOneWidget);
      expect(find.textContaining('離れた場所にいる保護者や仲間も'), findsOneWidget);
      expect(find.text('大会ID: test_tour_999'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text(testUrl), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.text('LINEやSNSでURLを送る'), findsOneWidget);

      final closeButton = find.text('閉じる');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pump();
      expect(isClosed, isTrue);
    });

    testWidgets('カスタム設定（Webアプリ向け）で正しく描画されること', (tester) async {
      const webUrl = 'https://kendo-os-beta.web.app';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
          ),
          home: const Scaffold(
            body: QrShareDialog(
              title: 'Webアプリ版（kendo_os）',
              themeColor: AppKendoColors.blue,
              description: 'カメラでQRコードを読み取るとブラウザから開けます。',
              shareUrl: webUrl,
              shareText: 'Webアプリ版: $webUrl',
              shareButtonLabel: 'URLをシェア・共有',
              copySuccessMessage: 'WebアプリのURLをコピーしました',
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('Webアプリ版（kendo_os）'), findsOneWidget);
      expect(find.text('URLをシェア・共有'), findsOneWidget);
      expect(find.text(webUrl), findsOneWidget);
    });

    testWidgets('非読み込み中においてキャンセルおよび接続開始ボタンが正しく描画されること', (tester) async {
      bool canceled = false;
      bool joined = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomJoinQrDialogActions(
              isLoading: false,
              isDark: false,
              onCancel: () => canceled = true,
              onJoin: () => joined = true,
            ),
          ),
        ),
      );

      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('接続開始'), findsOneWidget);
      expect(find.byType(AppLoadingIndicator), findsNothing);

      await tester.tap(find.text('キャンセル'));
      await tester.pump();
      expect(canceled, isTrue);

      await tester.tap(find.text('接続開始'));
      await tester.pump();
      expect(joined, isTrue);
    });

    testWidgets('読み込み中においてローディング表示されキャンセルが無効化されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomJoinQrDialogActions(
              isLoading: true,
              isDark: true,
              onCancel: () {},
              onJoin: () {},
            ),
          ),
        ),
      );

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.text('接続開始'), findsNothing);

      final outlinedButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(outlinedButton.onPressed, isNull);
    });

    testWidgets('WebAppQrDialog単体表示においてURLとQRコードが表示されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(body: WebAppQrDialog()),
        ),
      );
      await tester.safePumpAndSettle();

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
      await tester.safePumpAndSettle();

      final tileFinder = find.text('Webアプリ版 QRコード');
      expect(tileFinder, findsOneWidget);

      await tester.tap(tileFinder);
      await tester.safePumpAndSettle();

      expect(find.byType(WebAppQrDialog), findsOneWidget);
      expect(find.text('https://kendo-os-beta.web.app'), findsOneWidget);

      await tester.tap(find.text('閉じる'));
      await tester.safePumpAndSettle();

      expect(find.byType(WebAppQrDialog), findsNothing);
    });
  });
}
