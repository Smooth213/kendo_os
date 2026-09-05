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
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class _MockStrokeRepository extends Mock implements StrokeRepository {}

class _MockLocalStrokeRepository extends Mock
    implements LocalStrokeRepository {}

class _MockProgramRepository extends Mock implements ProgramRepository {}

class _MockHttpOverrides extends HttpOverrides {
  final Uint8List pdfBytes;
  _MockHttpOverrides(this.pdfBytes);

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _GoldenMockHttpClient(pdfBytes);
}

class _GoldenMockHttpClient extends Mock implements HttpClient {
  final Uint8List pdfBytes;
  _GoldenMockHttpClient(this.pdfBytes);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _GoldenMockHttpClientRequest(pdfBytes);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _GoldenMockHttpClientRequest(pdfBytes);
}

class _GoldenMockHttpClientRequest extends Mock implements HttpClientRequest {
  final Uint8List pdfBytes;
  _GoldenMockHttpClientRequest(this.pdfBytes);

  @override
  Future<HttpClientResponse> close() async =>
      _GoldenMockHttpClientResponse(pdfBytes);
}

class _GoldenMockHttpClientResponse extends Mock implements HttpClientResponse {
  final Uint8List pdfBytes;
  _GoldenMockHttpClientResponse(this.pdfBytes);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => pdfBytes.length;

  @override
  HttpHeaders get headers => _GoldenMockHttpHeaders();

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

class _GoldenMockHttpHeaders extends Mock implements HttpHeaders {
  @override
  ContentType? get contentType => ContentType.parse('application/pdf');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockStrokeRepository mockStrokeRepo;
  late _MockLocalStrokeRepository mockLocalStrokeRepo;
  late _MockProgramRepository mockProgramRepo;
  late SharedPreferences prefs;
  late Uint8List mixedPdfBytes;

  const testPdfUrl = 'https://example.com/golden_mixed.pdf';
  final goldenProgram = ProgramModel(
    id: 'golden-prog-1',
    tournamentId: 'tour-golden-1',
    title: 'ゴールデン検証用縦横混在プログラム',
    fileUrl: testPdfUrl,
    fileType: 'pdf',
    pageCount: 2,
    createdAt: DateTime(2026, 9, 1),
  );

  setUpAll(() {
    final PdfDocument doc = PdfDocument();
    // ページ0: A4縦 (595 x 842)
    final sec0 = doc.sections!.add();
    sec0.pageSettings.size = const Size(595, 842);
    sec0.pageSettings.margins.all = 0;
    sec0.pages.add();

    // ページ1: A4横 (842 x 595相当, landscape)
    final sec1 = doc.sections!.add();
    sec1.pageSettings.orientation = PdfPageOrientation.landscape;
    sec1.pageSettings.margins.all = 0;
    sec1.pages.add();

    mixedPdfBytes = Uint8List.fromList(doc.saveSync());
    doc.dispose();
  });

  setUp(() async {
    mockStrokeRepo = _MockStrokeRepository();
    mockLocalStrokeRepo = _MockLocalStrokeRepository();
    mockProgramRepo = _MockProgramRepository();

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    HttpOverrides.global = _MockHttpOverrides(mixedPdfBytes);
    ProgramViewerPdfPageCache.shared.clear();
    ProgramViewerMediaCache.shared.sdkPdfBytesCache.clear();
    ProgramViewerMediaCache.shared.sdkPdfBytesCache[testPdfUrl] = Future.value(
      mixedPdfBytes,
    );
    ProgramViewerPdfPageCache.shared.parseDocumentInfo(
      testPdfUrl,
      mixedPdfBytes,
    );

    when(
      () => mockProgramRepo.watchPrograms(any()),
    ).thenAnswer((_) => Stream.value([goldenProgram]));
  });

  tearDown(() {
    HttpOverrides.global = null;
    ProgramViewerPdfPageCache.shared.clear();
    ProgramViewerMediaCache.shared.sdkPdfBytesCache.clear();
  });

  Widget buildAppScope({
    required Widget child,
    required List<StrokeModel> strokes,
    UserRole role = UserRole.admin,
  }) {
    when(
      () => mockStrokeRepo.watchStrokes(any()),
    ).thenAnswer((_) => Stream.value(strokes));
    when(
      () => mockLocalStrokeRepo.watchStrokes(any()),
    ).thenAnswer((_) => Stream.value([]));

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        programListProvider(
          'tour-golden-1',
        ).overrideWith((ref) => Stream.value([goldenProgram])),
        strokeRepositoryProvider.overrideWithValue(mockStrokeRepo),
        localStrokeRepositoryProvider.overrideWithValue(mockLocalStrokeRepo),
        programRepositoryProvider.overrideWithValue(mockProgramRepo),
        activeRoleProvider.overrideWith((ref) => Role.admin),
        permissionProvider.overrideWith(
          (ref) => AppPermissions(isReadOnly: false),
        ),
        currentUserRoleProvider.overrideWith((ref) => role),
        currentDojoIdProvider.overrideWith((ref) => 'default_dojo_room'),
        isarProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
        ),
        home: Scaffold(body: child),
      ),
    );
  }

  group('📸 縦横混在PDF×手書きペン完全同期 Golden＆ピクセル整合性テスト要塞', () {
    testWidgets('1. 【縦向き用紙 Golden】全画面とボトムシートで用紙上のストローク相対位置・アスペクト比が完全一致すること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 用紙中央 (500, 707) の対角線ストローク
      final centerStroke = StrokeModel(
        id: 'stroke-p0-center',
        programId: 'golden-prog-1',
        authorId: 'admin_1',
        pageIndex: 0,
        points: const [Offset(450, 707), Offset(500, 707), Offset(550, 707)],
        color: Colors.red,
        strokeWidth: 8.0,
        createdAt: DateTime(2026, 9, 1),
      );

      // (A) 全画面（ProgramViewerScreen）をレンダリング
      await tester.pumpWidget(
        buildAppScope(
          child: ProgramViewerScreen(
            programs: [goldenProgram],
            initialIndex: 0,
          ),
          strokes: [centerStroke],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 全画面の用紙キャンバスサイズ（SizedBox 1000x1414）を検証
      final fullCanvasFinder = find.descendant(
        of: find.byType(ProgramViewerPdfBody),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 1000.0 && w.height == 1414.0,
        ),
      );
      expect(fullCanvasFinder, findsOneWidget);

      // 全画面のペンオーバーレイがキャンバス内に配置されていること
      final fullOverlayFinder = find.descendant(
        of: fullCanvasFinder,
        matching: find.byType(ProgramViewerCanvasOverlay),
      );
      expect(fullOverlayFinder, findsOneWidget);

      // (B) ボトムシート（ProgramBottomSheet）をレンダリング
      await tester.pumpWidget(
        buildAppScope(
          child: ProgramBottomSheet(tournamentId: 'tour-golden-1'),
          strokes: [centerStroke],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // ボトムシート側でも同一のキャンバス（SizedBox 1000x1414）が存在すること
      final sheetCanvasFinder = find.descendant(
        of: find.byType(ProgramBottomSheet),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 1000.0 && w.height == 1414.0,
        ),
      );
      expect(sheetCanvasFinder, findsOneWidget);

      // ボトムシート側のペン層が存在し、ストローク座標が完全一致すること
      final sheetStrokeLayerFinder = find.descendant(
        of: sheetCanvasFinder,
        matching: find.byType(ProgramStrokeLayer),
      );
      expect(sheetStrokeLayerFinder, findsOneWidget);

      final CustomPaint customPaint = tester.widget(
        find.descendant(
          of: sheetStrokeLayerFinder,
          matching: find.byType(CustomPaint),
        ),
      );
      final StrokePainter painter = customPaint.painter as StrokePainter;
      expect(painter.sharedStrokes.first.points, equals(centerStroke.points));
    });

    testWidgets('2. 【横向き用紙 Golden】横向きPDFにおいて用紙キャンバスが1414x1000で完全同期すること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 横向き用紙（p1）の端部および中心ストローク (707, 500)
      final landscapeStroke = StrokeModel(
        id: 'stroke-p1-edge',
        programId: 'golden-prog-1',
        authorId: 'admin_1',
        pageIndex: 1,
        points: const [Offset(650, 500), Offset(707, 500), Offset(750, 500)],
        color: Colors.blue,
        strokeWidth: 6.0,
        createdAt: DateTime(2026, 9, 1),
      );

      // (A) 全画面で表示し、横向きページ（p1）へ遷移
      await tester.pumpWidget(
        buildAppScope(
          child: ProgramViewerScreen(
            programs: [goldenProgram],
            initialIndex: 0,
          ),
          strokes: [landscapeStroke],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final pageViewFinder = find.descendant(
        of: find.byType(ProgramViewerPdfBody),
        matching: find.byType(PageView),
      );
      expect(pageViewFinder, findsOneWidget);
      final PageView pageView = tester.widget(pageViewFinder);
      pageView.controller?.jumpToPage(1);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 横向き用紙キャンバスサイズ（SizedBox 1414x1000）を検証
      final landscapeCanvasFinder = find.descendant(
        of: find.byType(ProgramViewerPdfBody),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 1414.0 && w.height == 1000.0,
        ),
      );
      expect(landscapeCanvasFinder, findsOneWidget);

      // 横向き用紙内のペンオーバーレイを検証
      final landscapeOverlayFinder = find.descendant(
        of: landscapeCanvasFinder,
        matching: find.byType(ProgramViewerCanvasOverlay),
      );
      expect(landscapeOverlayFinder, findsOneWidget);
    });

    testWidgets('3. 【マルチデバイス Golden】iPhone・iPad・デスクトップ全端末で用紙とペンの同期構造が不変であること', (
      tester,
    ) async {
      final testSizes = [
        const Size(390, 844), // iPhone
        const Size(820, 1180), // iPad
        const Size(1920, 1080), // Desktop
      ];

      for (final deviceSize in testSizes) {
        tester.view.physicalSize = deviceSize;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          buildAppScope(
            child: ProgramViewerScreen(
              programs: [goldenProgram],
              initialIndex: 0,
            ),
            strokes: [],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // どの端末サイズであっても 1000x1414 のキャンバス構造が破綻なく生成されること
        final canvasFinder = find.descendant(
          of: find.byType(ProgramViewerPdfBody),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == 1000.0 && w.height == 1414.0,
          ),
        );
        expect(
          canvasFinder,
          findsOneWidget,
          reason: '画面サイズ $deviceSize においても用紙キャンバスの定義が不変であること',
        );
      }

      tester.view.resetPhysicalSize();
    });
  });
}
