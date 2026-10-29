import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_floating_action_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_full_manual_tab_view.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_markdown_view.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_pdf_download_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_search_app_bar_actions.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_search_app_bar_title.dart';

void main() {
  group('[Widget] マニュアル各種UIコンポーネント総合テスト', () {
    // 1. ManualFloatingActionBar & ManualPdfDownloadCard
    testWidgets('アクションバーおよびPDFダウンロードカードのタップと描画が正常動作すること', (tester) async {
      bool primaryTapped = false;
      bool secondaryTapped = false;
      bool downloadPressed = false;
      bool fallbackPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ManualFloatingActionBar(
                  primaryLabel: 'A4印刷',
                  primaryIcon: Icons.print,
                  onPrimaryPressed: () => primaryTapped = true,
                  secondaryLabel: '共有/保存',
                  secondaryIcon: Icons.share,
                  onSecondaryPressed: () => secondaryTapped = true,
                  isDark: false,
                ),
                ManualPdfDownloadCard(
                  onDownloadPressed: () => downloadPressed = true,
                  onTextFallbackPressed: () => fallbackPressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('A4印刷'), findsOneWidget);
      expect(find.text('共有/保存'), findsOneWidget);
      expect(find.text('Kendo Sync 総合取扱説明書'), findsOneWidget);

      await tester.tap(find.text('A4印刷'));
      expect(primaryTapped, isTrue);

      await tester.tap(find.text('共有/保存'));
      expect(secondaryTapped, isTrue);

      await tester.tap(find.text('PDF版をダウンロード (無料)'));
      expect(downloadPressed, isTrue);

      await tester.tap(find.text('テキスト簡易版（オフライン対応）を読む'));
      expect(fallbackPressed, isTrue);
    });

    // 2. ManualMarkdownView
    testWidgets('ManualMarkdownViewにおいて コンテンツ描画とローディング表示が正常動作すること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualMarkdownView(
              markdownContent: '# テスト見出し\n\nこれはテスト本文です。',
              currentFilePath: 'manuals/quickstart/index.md',
              isLoading: false,
              onLinkTapped: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('テスト見出し'), findsOneWidget);
      expect(find.text('これはテスト本文です。'), findsOneWidget);

      // isLoading = true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualMarkdownView(
              markdownContent: '',
              currentFilePath: 'manuals/quickstart/index.md',
              isLoading: true,
              onLinkTapped: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // 3. ManualSearchAppBarTitle & Actions
    testWidgets('マニュアルAppBarにおいて 通常タイトルと検索モードの連動が正常動作すること', (tester) async {
      final controller = TextEditingController();
      bool searchStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: ManualSearchAppBarTitle(
                isSearching: false,
                searchController: controller,
                onSearchChanged: (_) {},
              ),
              actions: [
                ManualSearchAppBarActions(
                  showSearch: true,
                  isSearching: false,
                  isPdfMode: false,
                  searchQuery: '',
                  onPreviousPressed: () {},
                  onNextPressed: () {},
                  onClearPressed: () {},
                  onStartSearchPressed: () => searchStarted = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('ヘルプ・マニュアル'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      expect(searchStarted, isTrue);

      // 検索モードへ切り替え
      String changedText = '';
      bool prevPressed = false;
      bool nextPressed = false;
      bool clearPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: ManualSearchAppBarTitle(
                isSearching: true,
                searchController: controller,
                onSearchChanged: (val) => changedText = val,
              ),
              actions: [
                ManualSearchAppBarActions(
                  showSearch: true,
                  isSearching: true,
                  isPdfMode: true,
                  searchQuery: 'query',
                  onPreviousPressed: () => prevPressed = true,
                  onNextPressed: () => nextPressed = true,
                  onClearPressed: () => clearPressed = true,
                  onStartSearchPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('ヘルプ・マニュアル'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'キーワード');
      expect(changedText, 'キーワード');

      expect(find.byIcon(Icons.navigate_before), findsOneWidget);
      expect(find.byIcon(Icons.navigate_next), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.navigate_before));
      expect(prevPressed, isTrue);

      await tester.tap(find.byIcon(Icons.navigate_next));
      expect(nextPressed, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      expect(clearPressed, isTrue);
    });

    // 4. ManualFullManualTabView
    testWidgets('ManualFullManualTabViewにおいて 各状態のUI描画と操作が正常動作すること', (
      tester,
    ) async {
      bool downloadStarted = false;
      bool fallbackDisabled = false;

      // 状態1: 未ダウンロード
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
      await tester.tap(find.text('PDF版をダウンロード (無料)'));
      expect(downloadStarted, isTrue);

      // 状態2: ダウンロード中
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

      // 状態3: テキスト簡易版フォールバック
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
    });
  });
}
