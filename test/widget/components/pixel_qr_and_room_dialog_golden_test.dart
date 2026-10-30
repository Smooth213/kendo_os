import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/web_app_qr_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/room_join_duplicate_warning_dialog.dart';
import 'package:kendo_os/shared/widgets/room_join_qr_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] QRコード ＆ ルーム参加・重複警告ダイアログ 視覚ピクセル統合テスト', () {
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

    Widget buildWarningWrapper({required bool isDark, required String code}) {
      final themeColors = AppThemeColors.ofMode(
        isDark: isDark,
        mode: isDark ? 'dark' : 'normal',
      );

      return MaterialApp(
        theme: isDark
            ? ThemeData.dark().copyWith(extensions: [themeColors])
            : ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: Center(
            child: RoomJoinDuplicateWarningDialog(code: code, onConfirm: () {}),
          ),
        ),
      );
    }

    testWidgets('WebAppQrDialog: スマホ幅(390px) ライトモード レンダリングが正しく検証されること', (
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
      await tester.pump();

      expect(find.text('Webアプリ版（kendo_os）'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.byTooltip('URLをコピー'), findsOneWidget);
      expect(find.text('URLをシェア・共有'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WebAppQrDialog: タブレット幅(800px) ダークモード コントラスト・白背景が正しく検証されること', (
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
      await tester.pump();

      expect(find.text('Webアプリ版（kendo_os）'), findsOneWidget);
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

    testWidgets('RoomJoinQrDialog: スマホ幅(390px) 道場ルーム参加シートのピクセル完全性こと', (
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
      await tester.pump();

      expect(find.text('道場ルームへの参加'), findsOneWidget);
      expect(find.text('接続開始'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ライトモード表示において 警告アイコンおよびボタン配置が正常に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildWarningWrapper(isDark: false, code: 'DOJO-777'),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(RoomJoinDuplicateWarningDialog), findsOneWidget);
      expect(find.textContaining('DOJO-777'), findsOneWidget);
      expect(find.byIcon(Icons.report_problem_rounded), findsOneWidget);
      expect(find.text('このまま接続'), findsOneWidget);
      expect(find.text('キャンセル（変更する）'), findsOneWidget);
    });

    testWidgets('ダークモード表示において ダーク背景およびコントラスト色が正常に適用描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildWarningWrapper(isDark: true, code: 'KENDO-999'),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(RoomJoinDuplicateWarningDialog), findsOneWidget);
      expect(find.textContaining('KENDO-999'), findsOneWidget);
    });
  });
}
