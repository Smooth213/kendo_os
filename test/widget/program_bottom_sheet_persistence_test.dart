import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_sheet_pagination_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_view_state_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_app_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProgramViewStateService.instance.resetForTesting();
    ProgramViewerMediaCache.shared.clear();
    ProgramViewerPdfPageCache.shared.clear();
  });

  final dummyPrograms = [
    ProgramModel(
      id: 'prog_1',
      tournamentId: 'tour_persist_1',
      title: '進行表_1日目',
      fileUrl: 'https://example.com/prog1.png',
      fileType: 'image',
      pageCount: 1,
      createdAt: DateTime(2026, 9, 1),
    ),
    ProgramModel(
      id: 'prog_2',
      tournamentId: 'tour_persist_1',
      title: 'トーナメント表_女子',
      fileUrl: 'https://example.com/prog2.jpg',
      fileType: 'image',
      pageCount: 1,
      createdAt: DateTime(2026, 9, 2),
    ),
  ];

  Widget createTestWidget({
    required List<ProgramModel> programs,
    String tournamentId = 'tour_persist_1',
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    return ProviderScope(
      overrides: [
        programListProvider(
          tournamentId,
        ).overrideWith((ref) => Stream.value(programs)),
      ],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(body: ProgramBottomSheet(tournamentId: tournamentId)),
      ),
    );
  }

  group('[Widget] ProgramBottomSheet 閲覧位置の端末保存・自動復元テスト', () {
    testWidgets('事前に保存されたプログラムインデックスが自動復元されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 事前に 2番目のプログラム（インデックス1）を保存
      ProgramViewStateService.instance.setLastProgramIndex('tour_persist_1', 1);

      await tester.pumpWidget(createTestWidget(programs: dummyPrograms));
      await tester.pumpAndSettle();

      // 初期状態で2番目のプログラム「トーナメント表_女子」が選択されていることを検証
      final filterChips = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .toList();
      expect(filterChips.length, 2);
      expect(filterChips[0].selected, isFalse);
      expect(filterChips[1].selected, isTrue);
    });

    testWidgets('プログラム切り替え時に端末ストレージへインデックスが保存されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(programs: dummyPrograms));
      await tester.pumpAndSettle();

      // 最初はインデックス0
      expect(
        ProgramViewStateService.instance.getLastProgramIndex('tour_persist_1'),
        0,
      );

      // 2つ目のチップ（トーナメント表_女子）をタップ
      await tester.tap(find.text('トーナメント表_女子'));
      await tester.pumpAndSettle();

      // インデックス1が保存されていること
      expect(
        ProgramViewStateService.instance.getLastProgramIndex('tour_persist_1'),
        1,
      );
    });

    testWidgets('プログラム数が減少して保存インデックスが範囲外になった場合は安全に0へクランプされること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 範囲外のインデックス 10 を事前に保存
      ProgramViewStateService.instance.setLastProgramIndex(
        'tour_persist_1',
        10,
      );

      // 2件しかないプログラムで開く
      await tester.pumpWidget(createTestWidget(programs: dummyPrograms));
      await tester.pumpAndSettle();

      // クラッシュせず、1番目が安全に選択されること
      final filterChips = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .toList();
      expect(filterChips[0].selected, isTrue);
    });

    testWidgets('PDFプログラムのページ変更時に保存され、次回オープン時に復元されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pdfPrograms = [
        ProgramModel(
          id: 'prog_pdf_1',
          tournamentId: 'tour_pdf',
          title: '大会冊子PDF',
          fileUrl: 'https://example.com/book.pdf',
          fileType: 'pdf',
          pageCount: 5,
          createdAt: DateTime(2026, 9, 1),
        ),
      ];

      // 事前にページ 3 を保存
      ProgramViewStateService.instance.setLastPageNumber('prog_pdf_1', 3);

      await tester.pumpWidget(
        createTestWidget(programs: pdfPrograms, tournamentId: 'tour_pdf'),
      );
      await tester.pumpAndSettle();

      // ページャーに 3 / 5 が表示されていること
      expect(find.byType(ProgramSheetPaginationBar), findsOneWidget);
      expect(find.text('3 / 5'), findsOneWidget);

      // 次ページボタンをタップして 4 に進める
      final nextButton = find.byTooltip('次のページ');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 4 / 5 になり、保存値も 4 に更新されること
      expect(find.text('4 / 5'), findsOneWidget);
      expect(
        ProgramViewStateService.instance.getLastPageNumber('prog_pdf_1'),
        4,
      );

      // 「最初のページに戻る」ボタンをタップして 1 に戻ることを検証
      final firstPageButton = find.byTooltip('最初のページに戻る');
      expect(firstPageButton, findsOneWidget);
      await tester.tap(firstPageButton);
      await tester.pumpAndSettle();

      expect(find.text('1 / 5'), findsOneWidget);
      expect(
        ProgramViewStateService.instance.getLastPageNumber('prog_pdf_1'),
        1,
      );

      // 1ページ目では「最初のページに戻る」ボタンをタップしてもページが変わらない（非活性）ことを検証
      await tester.tap(firstPageButton);
      await tester.pumpAndSettle();
      expect(find.text('1 / 5'), findsOneWidget);
    });

    testWidgets('単一ページプログラムではページネーションバー自体が表示されないこと', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final singlePagePdf = [
        ProgramModel(
          id: 'prog_single',
          tournamentId: 'tour_single',
          title: '1ページPDF',
          fileUrl: 'https://example.com/single.pdf',
          fileType: 'pdf',
          pageCount: 1,
          createdAt: DateTime(2026, 9, 1),
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(programs: singlePagePdf, tournamentId: 'tour_single'),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('最初のページに戻る'), findsNothing);
      expect(find.byTooltip('前のページ'), findsNothing);
      expect(find.byTooltip('次のページ'), findsNothing);
    });
  });

  group('ProgramViewerAppBar 最初のページに戻るボタンのテスト', () {
    testWidgets('複数ページPDFで2ページ目以降のときボタンが活性化し、タップでコールバックが呼ばれること', (
      tester,
    ) async {
      bool firstPageCalled = false;
      final pdfProgram = ProgramModel(
        id: 'prog_viewer_pdf',
        tournamentId: 'tour_1',
        title: '大会冊子PDF',
        fileUrl: 'https://example.com/viewer.pdf',
        fileType: 'pdf',
        pageCount: 5,
        createdAt: DateTime(2026, 9, 1),
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

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
              pdfPageCounts: {'https://example.com/viewer.pdf': 5},
              pdfCurrentPages: {'prog_viewer_pdf': 3},
              searchTextController: TextEditingController(),
              pdfViewerController: PdfViewerController(),
              searchResult: PdfTextSearchResult(),
              activePenColor: Colors.blue,
              onSearchSubmitted: (_) {},
              onPdfSearchResult: (_) {},
              onCloseSearch: () {},
              onOpenSearch: () {},
              onToggleDrawingMode: () {},
              onFirstPagePressed: () {
                firstPageCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstPageButtonFinder = find.widgetWithIcon(
        IconButton,
        Icons.first_page,
      );
      expect(firstPageButtonFinder, findsOneWidget);

      final iconButton = tester.widget<IconButton>(firstPageButtonFinder);
      expect(iconButton.onPressed, isNotNull);

      await tester.tap(firstPageButtonFinder);
      await tester.pumpAndSettle();
      expect(firstPageCalled, isTrue);
    });

    testWidgets('複数ページPDFでも1ページ目表示時はボタンが非活性となること', (tester) async {
      final pdfProgram = ProgramModel(
        id: 'prog_viewer_pdf',
        tournamentId: 'tour_1',
        title: '大会冊子PDF',
        fileUrl: 'https://example.com/viewer.pdf',
        fileType: 'pdf',
        pageCount: 5,
        createdAt: DateTime(2026, 9, 1),
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

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
              pdfPageCounts: {'https://example.com/viewer.pdf': 5},
              pdfCurrentPages: {'prog_viewer_pdf': 1},
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

      final firstPageButtonFinder = find.widgetWithIcon(
        IconButton,
        Icons.first_page,
      );
      expect(firstPageButtonFinder, findsOneWidget);

      final iconButton = tester.widget<IconButton>(firstPageButtonFinder);
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('単一ページPDFや画像の場合はボタンが表示されないこと', (tester) async {
      final singlePdfProgram = ProgramModel(
        id: 'prog_viewer_single',
        tournamentId: 'tour_1',
        title: '1ページPDF',
        fileUrl: 'https://example.com/single.pdf',
        fileType: 'pdf',
        pageCount: 1,
        createdAt: DateTime(2026, 9, 1),
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            appBar: ProgramViewerAppBar(
              isDark: false,
              isDrawingMode: false,
              isSearchMode: false,
              isFilePdf: true,
              currentProgram: singlePdfProgram,
              safeIndex: 0,
              totalPrograms: 1,
              pdfPageCounts: {'https://example.com/single.pdf': 1},
              pdfCurrentPages: {'prog_viewer_single': 1},
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

      expect(find.byTooltip('最初のページに戻る'), findsNothing);
    });
  });
}
