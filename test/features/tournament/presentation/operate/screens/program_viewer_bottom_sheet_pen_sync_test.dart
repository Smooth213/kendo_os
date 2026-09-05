import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_stroke_layer.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_canvas_overlay.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_body.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/features/tournament/presentation/painters/program_viewer_painters.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/stroke_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class MockStrokeRepository extends Mock implements StrokeRepository {}

class MockLocalStrokeRepository extends Mock implements LocalStrokeRepository {}

class MockProgramRepository extends Mock implements ProgramRepository {}

class MockHttpOverrides extends HttpOverrides {
  final Uint8List pdfBytes;
  MockHttpOverrides(this.pdfBytes);

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _MockHttpClient(pdfBytes);
}

class _MockHttpClient extends Mock implements HttpClient {
  final Uint8List pdfBytes;
  _MockHttpClient(this.pdfBytes);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _MockHttpClientRequest(pdfBytes);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockHttpClientRequest(pdfBytes);
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {
  final Uint8List pdfBytes;
  _MockHttpClientRequest(this.pdfBytes);

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse(pdfBytes);
}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {
  final Uint8List pdfBytes;
  _MockHttpClientResponse(this.pdfBytes);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => pdfBytes.length;

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([pdfBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _MockHttpHeaders extends Mock implements HttpHeaders {
  @override
  ContentType? get contentType => ContentType.parse('application/pdf');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStrokeRepository mockStrokeRepo;
  late MockLocalStrokeRepository mockLocalStrokeRepo;
  late MockProgramRepository mockProgramRepo;
  late SharedPreferences prefs;
  late Uint8List mixedPdfBytes;

  const testPdfUrl = 'https://example.com/tournament_mixed.pdf';
  final mixedProgram = ProgramModel(
    id: 'mixed-prog-1',
    tournamentId: 't-1',
    title: '縦横混在大会プログラム',
    fileUrl: testPdfUrl,
    fileType: 'pdf',
    pageCount: 2,
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    // 縦横混在の2ページPDFを生成
    // Page 0: 縦向き (595 x 842)
    // Page 1: 横向き (orientation: landscape)
    final PdfDocument doc = PdfDocument();
    final sec0 = doc.sections!.add();
    sec0.pageSettings.size = const Size(595, 842);
    sec0.pageSettings.margins.all = 0;
    final p0 = sec0.pages.add();
    p0.graphics.drawString(
      'Page 1 Portrait',
      PdfStandardFont(PdfFontFamily.helvetica, 16),
      bounds: const Rect.fromLTWH(20, 20, 200, 30),
    );

    final sec1 = doc.sections!.add();
    sec1.pageSettings.orientation = PdfPageOrientation.landscape;
    sec1.pageSettings.margins.all = 0;
    final p1 = sec1.pages.add();
    p1.graphics.drawString(
      'Page 2 Landscape',
      PdfStandardFont(PdfFontFamily.helvetica, 16),
      bounds: const Rect.fromLTWH(20, 20, 200, 30),
    );

    mixedPdfBytes = Uint8List.fromList(doc.saveSync());
    doc.dispose();
  });

  setUp(() async {
    mockStrokeRepo = MockStrokeRepository();
    mockLocalStrokeRepo = MockLocalStrokeRepository();
    mockProgramRepo = MockProgramRepository();

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    // キャッシュをクリアし、モックPDFバイト列をプリセット
    ProgramViewerPdfPageCache.shared.clear();
    ProgramViewerMediaCache.shared.sdkPdfBytesCache.clear();
    ProgramViewerMediaCache.shared.sdkPdfBytesCache[testPdfUrl] = Future.value(
      mixedPdfBytes,
    );
    ProgramViewerPdfPageCache.shared.parseDocumentInfo(
      testPdfUrl,
      mixedPdfBytes,
    );
  });

  tearDown(() {
    ProgramViewerPdfPageCache.shared.clear();
    ProgramViewerMediaCache.shared.sdkPdfBytesCache.clear();
  });

  Widget buildTestScope({required Widget child}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        programListProvider(
          't-1',
        ).overrideWith((ref) => Stream.value([mixedProgram])),
        strokeRepositoryProvider.overrideWithValue(mockStrokeRepo),
        localStrokeRepositoryProvider.overrideWithValue(mockLocalStrokeRepo),
        programRepositoryProvider.overrideWithValue(mockProgramRepo),
        activeRoleProvider.overrideWith((ref) => Role.admin),
        permissionProvider.overrideWith(
          (ref) => AppPermissions(isReadOnly: false),
        ),
        currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
        currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
        isarProvider.overrideWithValue(null),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('🥋 プログラム管理 vs ボトムシート: 縦・横・縦横混在PDFにおけるペン完全同期検証テスト', () {
    const testPdfUrl = 'https://example.com/tournament_mixed.pdf';
    final mixedProgram = ProgramModel(
      id: 'mixed-prog-1',
      tournamentId: 't-1',
      title: '縦横混在大会プログラム',
      fileUrl: testPdfUrl,
      fileType: 'pdf',
      pageCount: 2,
      createdAt: DateTime.now(),
    );

    // 縦ページ(p0)用のペン: 用紙中央 (500, 707)
    final strokePage0 = StrokeModel(
      id: 'stroke-p0',
      programId: 'mixed-prog-1',
      authorId: 'user1',
      pageIndex: 0,
      points: const [Offset(450, 707), Offset(500, 707), Offset(550, 707)],
      color: Colors.red,
      strokeWidth: 10.0,
      createdAt: DateTime.now(),
    );

    // 横ページ(p1)用のペン: 用紙中央 (707, 500)
    final strokePage1 = StrokeModel(
      id: 'stroke-p1',
      programId: 'mixed-prog-1',
      authorId: 'user1',
      pageIndex: 1,
      points: const [Offset(650, 500), Offset(707, 500), Offset(750, 500)],
      color: Colors.blue,
      strokeWidth: 10.0,
      createdAt: DateTime.now(),
    );

    testWidgets(
      '1. 縦向きページ（p0）: 全画面とボトムシートでキャンバスが 1000x1414 で完全一致し、ペンが同じ位置に重畳されること',
      (tester) async {
        when(
          () => mockProgramRepo.watchPrograms(any()),
        ).thenAnswer((_) => Stream.value([mixedProgram]));
        when(
          () => mockStrokeRepo.watchStrokes(any()),
        ).thenAnswer((_) => Stream.value([strokePage0]));
        when(
          () => mockLocalStrokeRepo.watchStrokes(any()),
        ).thenAnswer((_) => Stream.value([]));

        // (A) 全画面（ProgramViewerScreen）での縦ページ検証
        await tester.pumpWidget(
          buildTestScope(
            child: ProgramViewerScreen(
              programs: [mixedProgram],
              initialIndex: 0,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // 全画面の用紙キャンバスサイズ（SizedBox）を検証
        final fullscreenSizedBoxFinder = find.descendant(
          of: find.byType(ProgramViewerPdfBody),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == 1000.0 && w.height == 1414.0,
          ),
        );
        expect(
          fullscreenSizedBoxFinder,
          findsOneWidget,
          reason: '全画面表示において、縦向きページのキャンバスは 1000x1414 でなければなりません',
        );

        // 全画面の手書きペン層（ProgramViewerCanvasOverlay）が同一SizedBox内に同居していること
        final fullscreenOverlayFinder = find.descendant(
          of: fullscreenSizedBoxFinder,
          matching: find.byType(ProgramViewerCanvasOverlay),
        );
        expect(fullscreenOverlayFinder, findsOneWidget);

        final ProgramViewerCanvasOverlay fsOverlay = tester.widget(
          fullscreenOverlayFinder,
        );
        expect(fsOverlay.pageIndex, equals(0));

        await tester.pump(const Duration(milliseconds: 500));

        // (B) ボトムシート（ProgramBottomSheet）での縦ページ検証
        await tester.pumpWidget(
          buildTestScope(child: const ProgramBottomSheet(tournamentId: 't-1')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // ボトムシートの用紙キャンバスサイズ（SizedBox）を検証
        final bottomSheetSizedBoxFinder = find.descendant(
          of: find.byType(ProgramViewerPdfBody),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == 1000.0 && w.height == 1414.0,
          ),
        );
        expect(
          bottomSheetSizedBoxFinder,
          findsOneWidget,
          reason: 'ボトムシート表示においても、縦向きページのキャンバスは 1000x1414 で完全一致しなければなりません',
        );

        // ボトムシートの手書きペン層（ProgramStrokeLayer）が同一SizedBox内に同居していること
        final bottomSheetStrokeLayerFinder = find.descendant(
          of: bottomSheetSizedBoxFinder,
          matching: find.byType(ProgramStrokeLayer),
        );
        expect(bottomSheetStrokeLayerFinder, findsOneWidget);

        final ProgramStrokeLayer bsStrokeLayer = tester.widget(
          bottomSheetStrokeLayerFinder,
        );
        expect(bsStrokeLayer.pageIndex, equals(0));

        // StrokePainter に渡されたペンデータ（座標・点数）が完全一致していること
        final customPaintFinder = find.descendant(
          of: bottomSheetStrokeLayerFinder,
          matching: find.byType(CustomPaint),
        );
        expect(customPaintFinder, findsOneWidget);

        final CustomPaint customPaint = tester.widget(customPaintFinder);
        final StrokePainter painter = customPaint.painter as StrokePainter;
        expect(painter.sharedStrokes.length, equals(1));
        expect(painter.sharedStrokes.first.points, equals(strokePage0.points));

        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets(
      '2. 横向きページ（p1）: 全画面とボトムシートでキャンバスが 1414x1000 で完全一致し、ペンが同じ位置に重畳されること',
      (tester) async {
        when(
          () => mockProgramRepo.watchPrograms(any()),
        ).thenAnswer((_) => Stream.value([mixedProgram]));
        when(
          () => mockStrokeRepo.watchStrokes(any()),
        ).thenAnswer((_) => Stream.value([strokePage1]));
        when(
          () => mockLocalStrokeRepo.watchStrokes(any()),
        ).thenAnswer((_) => Stream.value([]));

        // (A) 全画面（ProgramViewerScreen）で横向きページ（p1）を開く
        await tester.pumpWidget(
          buildTestScope(
            child: ProgramViewerScreen(
              programs: [mixedProgram],
              initialIndex: 0,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // ページを1（横向き）へ切り替え
        final verticalPageViewFinder = find.descendant(
          of: find.byType(ProgramViewerPdfBody),
          matching: find.byType(PageView),
        );
        expect(verticalPageViewFinder, findsOneWidget);
        final PageView pageView = tester.widget(verticalPageViewFinder);
        pageView.controller?.jumpToPage(1);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // 横向きページのキャンバスサイズが 1414x1000 であること
        final fullscreenLandscapeFinder = find.descendant(
          of: find.byType(ProgramViewerPdfBody),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == 1414.0 && w.height == 1000.0,
          ),
        );
        expect(
          fullscreenLandscapeFinder,
          findsOneWidget,
          reason: '全画面表示において、横向きページのキャンバスは 1414x1000 でなければなりません',
        );

        // 手書きオーバーレイの pageIndex が 1 であること
        final overlayFinder = find.descendant(
          of: fullscreenLandscapeFinder,
          matching: find.byType(ProgramViewerCanvasOverlay),
        );
        expect(overlayFinder, findsOneWidget);
        final ProgramViewerCanvasOverlay overlay = tester.widget(overlayFinder);
        expect(overlay.pageIndex, equals(1));

        await tester.pump(const Duration(milliseconds: 500));

        // (B) ボトムシート（ProgramBottomSheet）で横向きページ（p1）を開く
        await tester.pumpWidget(
          buildTestScope(child: const ProgramBottomSheet(tournamentId: 't-1')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // ボトムシートのページ送りを実行して 2ページ目（横向き）へ
        final bsPageViewFinder = find.descendant(
          of: find.byType(ProgramViewerPdfBody),
          matching: find.byType(PageView),
        );
        final PageView bsPageView = tester.widget(bsPageViewFinder);
        bsPageView.controller?.jumpToPage(1);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // ボトムシートでも横向きキャンバスが 1414x1000 であること
        final bsLandscapeFinder = find.descendant(
          of: find.byType(ProgramViewerPdfBody),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == 1414.0 && w.height == 1000.0,
          ),
        );
        expect(
          bsLandscapeFinder,
          findsOneWidget,
          reason: 'ボトムシートにおいても、横向きページのキャンバスは 1414x1000 で完全一致しなければなりません',
        );

        // ボトムシートの手書きペン層（ProgramStrokeLayer）の pageIndex が 1 であること
        final bsStrokeLayerFinder = find.descendant(
          of: bsLandscapeFinder,
          matching: find.byType(ProgramStrokeLayer),
        );
        expect(bsStrokeLayerFinder, findsOneWidget);
        final ProgramStrokeLayer strokeLayer = tester.widget(
          bsStrokeLayerFinder,
        );
        expect(strokeLayer.pageIndex, equals(1));

        // StrokePainter に渡されたペンデータ（横ページ中央の座標）が完全一致していること
        final customPaintFinder = find.descendant(
          of: bsStrokeLayerFinder,
          matching: find.byType(CustomPaint),
        );
        expect(customPaintFinder, findsOneWidget);
        final CustomPaint customPaint = tester.widget(customPaintFinder);
        final StrokePainter painter = customPaint.painter as StrokePainter;
        expect(painter.sharedStrokes.length, equals(1));
        expect(painter.sharedStrokes.first.points, equals(strokePage1.points));

        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets('3. 縦横混在ファイルにおけるストロークのページ分離: p0のペンがp1に漏れず、各用紙に正しく描画されること', (
      tester,
    ) async {
      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([mixedProgram]));
      // 両方のページのペンが存在するストリーム
      when(
        () => mockStrokeRepo.watchStrokes(any()),
      ).thenAnswer((_) => Stream.value([strokePage0, strokePage1]));
      when(
        () => mockLocalStrokeRepo.watchStrokes(any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        buildTestScope(child: const ProgramBottomSheet(tournamentId: 't-1')),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // 初期表示（p0: 縦向きページ）
      final p0StrokeFinder = find.descendant(
        of: find.byType(ProgramStrokeLayer),
        matching: find.byType(CustomPaint),
      );
      expect(p0StrokeFinder, findsOneWidget);
      final CustomPaint p0Paint = tester.widget(p0StrokeFinder);
      final StrokePainter p0Painter = p0Paint.painter as StrokePainter;

      // p0 のペインターには p0 のペンのみが含まれ、p1 のペンは混入しないこと
      expect(p0Painter.sharedStrokes.length, equals(1));
      expect(p0Painter.sharedStrokes.first.id, equals('stroke-p0'));

      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
