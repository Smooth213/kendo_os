import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_full_manual_tab_view.dart';

void main() {
  group('🛡️ ManualFullManualTabView Widget Tests', () {
    testWidgets('Renders download card when not downloaded', (tester) async {
      bool downloadStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualFullManualTabView(
              buildIndexPane: const SizedBox(),
              markdownPane: const SizedBox(),
              isPdfDownloaded: false,
              isDownloading: false,
              downloadProgress: 0.0,
              forceMarkdownFallback: false,
              localPdfFile: null,
              pdfViewerController: null,
              fullManualFileName: 'test.pdf',
              onStartDownload: () => downloadStarted = true,
              onEnableMarkdownFallback: () {},
              onDisableMarkdownFallback: () {},
              onOpenPdfInBrowser: () {},
              onShareWebUrl: () {},
              onPrintPdf: () {},
              onSharePdf: () {},
            ),
          ),
        ),
      );

      expect(find.text('Kendo Sync 総合取扱説明書'), findsOneWidget);
      expect(find.text('PDF版をダウンロード (無料)'), findsOneWidget);

      await tester.tap(find.text('PDF版をダウンロード (無料)'));
      expect(downloadStarted, isTrue);
    });

    testWidgets('Renders downloading indicator when isDownloading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualFullManualTabView(
              buildIndexPane: const SizedBox(),
              markdownPane: const SizedBox(),
              isPdfDownloaded: false,
              isDownloading: true,
              downloadProgress: 0.5,
              forceMarkdownFallback: false,
              localPdfFile: null,
              pdfViewerController: null,
              fullManualFileName: 'test.pdf',
              onStartDownload: () {},
              onEnableMarkdownFallback: () {},
              onDisableMarkdownFallback: () {},
              onOpenPdfInBrowser: () {},
              onShareWebUrl: () {},
              onPrintPdf: () {},
              onSharePdf: () {},
            ),
          ),
        ),
      );

      expect(find.text('マニュアルをロード中...'), findsOneWidget);
      expect(find.text('50% 完了'), findsOneWidget);
    });

    testWidgets(
      'Renders markdown fallback header when forceMarkdownFallback is true',
      (tester) async {
        bool fallbackDisabled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ManualFullManualTabView(
                buildIndexPane: const SizedBox(),
                markdownPane: const Text('Markdownコンテンツ'),
                isPdfDownloaded: false,
                isDownloading: false,
                downloadProgress: 0.0,
                forceMarkdownFallback: true,
                localPdfFile: null,
                pdfViewerController: null,
                fullManualFileName: 'test.pdf',
                onStartDownload: () {},
                onEnableMarkdownFallback: () {},
                onDisableMarkdownFallback: () => fallbackDisabled = true,
                onOpenPdfInBrowser: () {},
                onShareWebUrl: () {},
                onPrintPdf: () {},
                onSharePdf: () {},
              ),
            ),
          ),
        );

        expect(find.text('📖 テキスト簡易版（オフライン対応）'), findsOneWidget);
        expect(find.text('PDF版に戻る'), findsOneWidget);
        expect(find.text('Markdownコンテンツ'), findsOneWidget);

        await tester.tap(find.text('PDF版に戻る'));
        expect(fallbackDisabled, isTrue);
      },
    );
  });
}
