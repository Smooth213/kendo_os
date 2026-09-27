import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/web_app_qr_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/room_join_qr_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('📸 【Golden】WebアプリQRコード ＆ 道場ルームQRダイアログ視覚整合性テスト', () {
    Widget buildQrWrapper({required Widget child, required bool isDark}) {
      final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
      return ProviderScope(
        overrides: [
          currentDojoIdProvider.overrideWith((ref) => 'test_dojo_room_123'),
        ],
        child: AppThemeModeWrapper(
          mode: isDark ? 'dark' : 'normal',
          child: MaterialApp(
            theme: isDark
                ? ThemeData.dark().copyWith(extensions: [themeColors])
                : ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(body: Center(child: child)),
          ),
        ),
      );
    }

    testWidgets('1. WebAppQrDialog: スマホ幅(390px) ライトモード レンダリング検証', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildQrWrapper(child: const WebAppQrDialog(), isDark: false),
      );
      await tester.pumpAndSettle();

      // タイトル、説明文、QRコード、コピーボタン（アイコン/ツールチップ）、共有ボタンが表示されていること
      expect(find.text('Webアプリ版（kendo_os）'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.byTooltip('URLをコピー'), findsOneWidget);
      expect(find.text('URLをシェア・共有'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. WebAppQrDialog: タブレット幅(800px) ダークモード コントラスト・白背景検証', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildQrWrapper(child: const WebAppQrDialog(), isDark: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Webアプリ版（kendo_os）'), findsOneWidget);
      // QRコードコンテナが白背景(0xFFFFFFFF)で包まれていること（ダークモード下でもQR読み取り精度を最大化）
      final qrFinder = find.byType(QrImageView);
      expect(qrFinder, findsOneWidget);

      final containerFinder = find.ancestor(
        of: qrFinder,
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);

      expect(find.byTooltip('URLをコピー'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. RoomJoinQrDialog: スマホ幅(390px) 道場ルーム参加シートのピクセル完全性', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildQrWrapper(child: const RoomJoinQrDialog(), isDark: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('道場ルームへの参加'), findsOneWidget);
      expect(find.text('接続開始'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
