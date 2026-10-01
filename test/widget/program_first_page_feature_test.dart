import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_sheet_pagination_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_view_state_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_app_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProgramViewStateService.instance.resetForTesting();
    ProgramViewerMediaCache.shared.clear();
    ProgramViewerPdfPageCache.shared.clear();
  });

  tearDown(() {
    ProgramViewerMediaCache.shared.clear();
    ProgramViewerPdfPageCache.shared.clear();
  });

  group('[Widget] ProgramSheetPaginationBar 「最初のページに戻る」単体テスト', () {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    testWidgets('1ページ目表示時は「最初のページに戻る」ボタンが非活性でタップしてもコールバックが発火しないこと', (
      tester,
    ) async {
      int? requestedPage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProgramSheetPaginationBar(
                currentPage: 1,
                pageCount: 5,
                themeColors: themeColors,
                isDark: false,
                onPageChanged: (page) => requestedPage = page,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstPageButtonFinder = find.byTooltip('最初のページに戻る');
      expect(firstPageButtonFinder, findsOneWidget);

      // タップしても非活性なのでコールバックは発火しない
      await tester.tap(firstPageButtonFinder);
      await tester.pumpAndSettle();

      expect(requestedPage, isNull);
    });

    testWidgets(
      '2ページ目以降表示時は「最初のページに戻る」ボタンが活性化し、タップで onPageChanged(1) が発火すること',
      (tester) async {
        int? requestedPage;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProgramSheetPaginationBar(
                  currentPage: 4,
                  pageCount: 10,
                  themeColors: themeColors,
                  isDark: false,
                  onPageChanged: (page) => requestedPage = page,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final firstPageButtonFinder = find.byTooltip('最初のページに戻る');
        expect(firstPageButtonFinder, findsOneWidget);

        await tester.tap(firstPageButtonFinder);
        await tester.pumpAndSettle();

        expect(requestedPage, 1);
      },
    );

    testWidgets('単一ページ (pageCount <= 1) の場合はページネーションバー自体が非表示になること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProgramSheetPaginationBar(
                currentPage: 1,
                pageCount: 1,
                themeColors: themeColors,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('最初のページに戻る'), findsNothing);
      expect(find.byTooltip('前のページ'), findsNothing);
      expect(find.byTooltip('次のページ'), findsNothing);
    });
  });

  group('ProgramViewerAppBar 「最初のページに戻る」単体テスト', () {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    testWidgets('複数ページPDFで2ページ目以降のとき「最初のページに戻る」ボタンが活性化し、タップでコールバックが呼ばれること', (
      tester,
    ) async {
      bool firstPagePressed = false;
      final pdfProgram = ProgramModel(
        id: 'pdf_sample',
        tournamentId: 'tour_sample',
        title: '大会プログラム',
        fileUrl: 'https://example.com/sample.pdf',
        fileType: 'pdf',
        pageCount: 6,
        createdAt: DateTime(2026, 9, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            appBar: ProgramViewerAppBar(
              isDark: false,
              isDrawingMode: false,
              isSearchMode: false,
              isFilePdf: true,
              currentProgram: pdfProgram,
              safeIndex: 0,
              totalPrograms: 1,
              pdfPageCounts: {'https://example.com/sample.pdf': 6},
              pdfCurrentPages: {'pdf_sample': 3},
              searchTextController: TextEditingController(),
              pdfViewerController: PdfViewerController(),
              searchResult: PdfTextSearchResult(),
              activePenColor: Colors.blue,
              onSearchSubmitted: (_) {},
              onPdfSearchResult: (_) {},
              onCloseSearch: () {},
              onOpenSearch: () {},
              onToggleDrawingMode: () {},
              onFirstPagePressed: () => firstPagePressed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstPageButton = find.widgetWithIcon(IconButton, Icons.first_page);
      expect(firstPageButton, findsOneWidget);

      final iconBtn = tester.widget<IconButton>(firstPageButton);
      expect(iconBtn.onPressed, isNotNull);

      await tester.tap(firstPageButton);
      await tester.pumpAndSettle();

      expect(firstPagePressed, isTrue);
    });

    testWidgets('複数ページPDFでも1ページ目表示時はボタンが非活性（onPressed == null）であること', (
      tester,
    ) async {
      final pdfProgram = ProgramModel(
        id: 'pdf_sample',
        tournamentId: 'tour_sample',
        title: '大会プログラム',
        fileUrl: 'https://example.com/sample.pdf',
        fileType: 'pdf',
        pageCount: 6,
        createdAt: DateTime(2026, 9, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            appBar: ProgramViewerAppBar(
              isDark: false,
              isDrawingMode: false,
              isSearchMode: false,
              isFilePdf: true,
              currentProgram: pdfProgram,
              safeIndex: 0,
              totalPrograms: 1,
              pdfPageCounts: {'https://example.com/sample.pdf': 6},
              pdfCurrentPages: {'pdf_sample': 1},
              searchTextController: TextEditingController(),
              pdfViewerController: PdfViewerController(),
              searchResult: PdfTextSearchResult(),
              activePenColor: Colors.blue,
              onSearchSubmitted: (_) {},
              onPdfSearchResult: (_) {},
              onCloseSearch: () {},
              onOpenSearch: () {},
              onToggleDrawingMode: () {},
              onFirstPagePressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstPageButton = find.widgetWithIcon(IconButton, Icons.first_page);
      expect(firstPageButton, findsOneWidget);

      final iconBtn = tester.widget<IconButton>(firstPageButton);
      expect(iconBtn.onPressed, isNull);
    });

    testWidgets('単一ページPDFの場合は「最初のページに戻る」ボタンが表示されないこと', (tester) async {
      final singlePdf = ProgramModel(
        id: 'pdf_single',
        tournamentId: 'tour_sample',
        title: '単一ページプログラム',
        fileUrl: 'https://example.com/single.pdf',
        fileType: 'pdf',
        pageCount: 1,
        createdAt: DateTime(2026, 9, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            appBar: ProgramViewerAppBar(
              isDark: false,
              isDrawingMode: false,
              isSearchMode: false,
              isFilePdf: true,
              currentProgram: singlePdf,
              safeIndex: 0,
              totalPrograms: 1,
              pdfPageCounts: {'https://example.com/single.pdf': 1},
              pdfCurrentPages: {'pdf_single': 1},
              searchTextController: TextEditingController(),
              pdfViewerController: PdfViewerController(),
              searchResult: PdfTextSearchResult(),
              activePenColor: Colors.blue,
              onSearchSubmitted: (_) {},
              onPdfSearchResult: (_) {},
              onCloseSearch: () {},
              onOpenSearch: () {},
              onToggleDrawingMode: () {},
              onFirstPagePressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithIcon(IconButton, Icons.first_page), findsNothing);
    });

    testWidgets('画像形式（fileType == image）の場合は「最初のページに戻る」ボタンが表示されないこと', (
      tester,
    ) async {
      final imageProgram = ProgramModel(
        id: 'img_sample',
        tournamentId: 'tour_sample',
        title: '進行表画像',
        fileUrl: 'https://example.com/sample.png',
        fileType: 'image',
        pageCount: 1,
        createdAt: DateTime(2026, 9, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            appBar: ProgramViewerAppBar(
              isDark: false,
              isDrawingMode: false,
              isSearchMode: false,
              isFilePdf: false,
              currentProgram: imageProgram,
              safeIndex: 0,
              totalPrograms: 1,
              pdfPageCounts: const {},
              pdfCurrentPages: const {},
              searchTextController: TextEditingController(),
              pdfViewerController: PdfViewerController(),
              searchResult: PdfTextSearchResult(),
              activePenColor: Colors.blue,
              onSearchSubmitted: (_) {},
              onPdfSearchResult: (_) {},
              onCloseSearch: () {},
              onOpenSearch: () {},
              onToggleDrawingMode: () {},
              onFirstPagePressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithIcon(IconButton, Icons.first_page), findsNothing);
    });
  });

  group('ProgramBottomSheet 「最初のページに戻る」統合動作テスト', () {
    testWidgets('ボトムシートでページ遷移後に「最初のページに戻る」をタップすると1ページ目に戻り保存値も1になること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pdfPrograms = [
        ProgramModel(
          id: 'prog_sheet_pdf',
          tournamentId: 'tour_sheet_1',
          title: '大会進行冊子',
          fileUrl: 'https://example.com/sheet.pdf',
          fileType: 'pdf',
          pageCount: 8,
          createdAt: DateTime(2026, 9, 1),
        ),
      ];

      // 事前に 5 ページ目を復元状態として設定
      ProgramViewStateService.instance.setLastPageNumber('prog_sheet_pdf', 5);

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            programListProvider(
              'tour_sheet_1',
            ).overrideWith((ref) => Stream.value(pdfPrograms)),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: ProgramBottomSheet(tournamentId: 'tour_sheet_1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 5 / 8 と表示されていること
      expect(find.text('5 / 8'), findsOneWidget);

      final firstPageButton = find.byTooltip('最初のページに戻る');
      expect(firstPageButton, findsOneWidget);

      // タップして 1 ページ目に戻る
      await tester.tap(firstPageButton);
      await tester.pumpAndSettle();

      expect(find.text('1 / 8'), findsOneWidget);
      expect(
        ProgramViewStateService.instance.getLastPageNumber('prog_sheet_pdf'),
        1,
      );

      // 1 ページ目の状態でもう一度タップしても 1 / 8 のまま維持されること
      await tester.tap(firstPageButton);
      await tester.pumpAndSettle();
      expect(find.text('1 / 8'), findsOneWidget);
    });
  });
}
