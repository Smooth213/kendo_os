import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_tab_views.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({required Widget child, bool isDark = false}) {
    return MaterialApp(
      theme: isDark
          ? ThemeData.dark().copyWith(
              extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
            )
          : ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
      home: Scaffold(body: child),
    );
  }

  group('[Golden] 総合マニュアルタブビュー視覚ピクセルテスト', () {
    testWidgets('ライトモードでテキスト簡易版マニュアルが明瞭に描画されオーバーフローがないこと', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          child: EmbeddedManualTabViews.buildFullManualTab(
            buildIndexPane: const SizedBox(
              width: 250,
              child: Text('【目次】\n1. はじめに\n2. 試合操作\n3. 印刷手順'),
            ),
            markdownPane: const Expanded(
              child: Text('# 総合マニュアル\n詳細な操作手順について解説します。'),
            ),
            isPdfDownloaded: false,
            isDownloading: false,
            downloadProgress: 0.0,
            forceMarkdownFallback: true,
            localPdfFile: null,
            pdfViewerController: null,
            onStartDownload: () {},
            onEnableMarkdownFallback: () {},
            onDisableMarkdownFallback: () {},
            onPrint:
                ({
                  required isAsset,
                  assetPath,
                  file,
                  required fileName,
                }) async {},
            onShare:
                ({
                  required isAsset,
                  assetPath,
                  file,
                  required fileName,
                }) async {},
          ),
          isDark: false,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('📖 テキスト簡易版（オフライン対応）'), findsOneWidget);
      expect(find.text('PDF版に戻る'), findsOneWidget);
      expect(find.textContaining('【目次】'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ダークモードでPDF未ダウンロード時の案内カードが美しく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          child: EmbeddedManualTabViews.buildFullManualTab(
            buildIndexPane: const SizedBox(),
            markdownPane: const SizedBox(),
            isPdfDownloaded: false,
            isDownloading: false,
            downloadProgress: 0.0,
            forceMarkdownFallback: false,
            localPdfFile: null,
            pdfViewerController: null,
            onStartDownload: () {},
            onEnableMarkdownFallback: () {},
            onDisableMarkdownFallback: () {},
            onPrint:
                ({
                  required isAsset,
                  assetPath,
                  file,
                  required fileName,
                }) async {},
            onShare:
                ({
                  required isAsset,
                  assetPath,
                  file,
                  required fileName,
                }) async {},
          ),
          isDark: true,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Kendo Sync 総合取扱説明書'), findsOneWidget);
      expect(find.text('PDF版をダウンロード (無料)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
