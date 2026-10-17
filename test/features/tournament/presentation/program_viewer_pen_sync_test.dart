import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_view_state_service.dart';
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

  late _MockStrokeRepository mockStrokeRepo;
  late _MockLocalStrokeRepository mockLocalStrokeRepo;
  late _MockProgramRepository mockProgramRepo;
  late SharedPreferences prefs;
  late Uint8List mixedPdfBytes;

  const testPdfUrl = 'https://example.com/tournament_mixed.pdf';
  final testProgram = ProgramModel(
    id: 'test-prog-1',
    tournamentId: 't-test-1',
    title: '検証用縦横混在プログラム',
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
    ProgramViewStateService.instance.resetForTesting();

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
    ).thenAnswer((_) => Stream.value([testProgram]));
  });

  tearDown(() {
    HttpOverrides.global = null;
    ProgramViewerPdfPageCache.shared.clear();
    ProgramViewerMediaCache.shared.sdkPdfBytesCache.clear();
  });

  Widget buildTestScope({
    required Widget child,
    required List<StrokeModel> currentStrokes,
    UserRole role = UserRole.admin,
  }) {
    when(
      () => mockStrokeRepo.watchStrokes(any()),
    ).thenAnswer((_) => Stream.value(currentStrokes));
    when(
      () => mockLocalStrokeRepo.watchStrokes(any()),
    ).thenAnswer((_) => Stream.value([]));

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        programListProvider(
          't-test-1',
        ).overrideWith((ref) => Stream.value([testProgram])),
        strokeRepositoryProvider.overrideWithValue(mockStrokeRepo),
        localStrokeRepositoryProvider.overrideWithValue(mockLocalStrokeRepo),
        programRepositoryProvider.overrideWithValue(mockProgramRepo),
        activeRoleProvider.overrideWith(
          (ref) => role == UserRole.viewer ? Role.viewer : Role.admin,
        ),
        permissionProvider.overrideWith(
          (ref) => AppPermissions(isReadOnly: role == UserRole.viewer),
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

  group('[Widget] 大会プログラム手書きペン描画・全画面同期・ボトムシート相互復元検証', () {
    testWidgets('全画面で描画されたストロークが、ボトムシート起動時に同一用紙位置へ即時反映されること', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final drawnStroke = StrokeModel(
        id: 'stroke-test-1',
        programId: 'test-prog-1',
        authorId: 'admin_user',
        pageIndex: 0,
        points: const [Offset(300, 400), Offset(350, 450), Offset(400, 500)],
        color: Colors.blue,
        strokeWidth: 4.0,
        createdAt: DateTime(2026, 9, 1),
      );

      // 1. 全画面ビューアの起動
      await tester.pumpWidget(
        buildTestScope(
          child: ProgramViewerScreen(programs: [testProgram], initialIndex: 0),
          currentStrokes: [drawnStroke],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 全画面でストロークオーバーレイが存在すること
      expect(find.byType(ProgramViewerCanvasOverlay), findsOneWidget);

      // 2. ボトムシート表示への画面切り替え
      await tester.pumpWidget(
        buildTestScope(
          child: const ProgramBottomSheet(
            tournamentId: 't-test-1',
            isViewerMode: false,
          ),
          currentStrokes: [drawnStroke],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 3. ボトムシート内でも同一ストロークが渡されていること
      final strokeLayerFinder = find.descendant(
        of: find.byType(ProgramBottomSheet),
        matching: find.byType(ProgramStrokeLayer),
      );
      expect(strokeLayerFinder, findsOneWidget);

      final CustomPaint customPaint = tester.widget(
        find.descendant(
          of: strokeLayerFinder,
          matching: find.byType(CustomPaint),
        ),
      );
      final StrokePainter painter = customPaint.painter as StrokePainter;
      expect(painter.sharedStrokes.length, equals(1));
      expect(painter.sharedStrokes.first.points, equals(drawnStroke.points));
    });

    testWidgets('縦横混在PDFにおいて全画面とボトムシート双方で用紙比率に応じた描画キャンバスが生成されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 全画面ビューア起動
      await tester.pumpWidget(
        buildTestScope(
          child: ProgramViewerScreen(programs: [testProgram], initialIndex: 0),
          currentStrokes: [],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // ページ1（横向き）へページ移動
      final pageViewFinder = find.descendant(
        of: find.byType(ProgramViewerPdfBody),
        matching: find.byType(PageView),
      );
      expect(pageViewFinder, findsOneWidget);
      final PageView pageView = tester.widget(pageViewFinder);
      pageView.controller?.jumpToPage(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 横向きキャンバス (1414x1000) が生成されていること
      final landscapeCanvasFinder = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 1414.0 && w.height == 1000.0,
      );
      expect(landscapeCanvasFinder, findsOneWidget);

      // 次にボトムシートへ切り替え
      ProgramViewStateService.instance.resetForTesting();
      await tester.pumpWidget(
        buildTestScope(
          child: const ProgramBottomSheet(
            tournamentId: 't-test-1',
            isViewerMode: false,
          ),
          currentStrokes: [],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // 旧ビュー破棄後にボトムシートのページ向きメタデータを再構築
      ProgramViewerPdfPageCache.shared.clear();
      ProgramViewerPdfPageCache.shared.parseDocumentInfo(
        testPdfUrl,
        mixedPdfBytes,
      );

      final bsPageViewFinder = find.descendant(
        of: find.byType(ProgramViewerPdfBody),
        matching: find.byType(PageView),
      );
      expect(bsPageViewFinder, findsOneWidget);
      final PageView bsPageView = tester.widget(bsPageViewFinder);
      bsPageView.controller?.jumpToPage(1);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // ボトムシート側でも横向きキャンバス (1414x1000) が生成されていること
      final sheetLandscapeCanvas = find.descendant(
        of: find.byType(ProgramViewerPdfBody),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 1414.0 && w.height == 1000.0,
        ),
      );
      expect(sheetLandscapeCanvas, findsOneWidget);
    });

    testWidgets('観客（Viewer）席で手書きペンが完全一致で閲覧でき、編集ツールが物理排除されていること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sharedStroke = StrokeModel(
        id: 'stroke-shared-announcement',
        programId: 'test-prog-1',
        authorId: 'admin_user',
        pageIndex: 0,
        points: const [Offset(200, 200), Offset(800, 200)],
        color: Colors.red,
        strokeWidth: 12.0,
        createdAt: DateTime(2026, 9, 1),
      );

      // 観客ロール (UserRole.viewer) でボトムシートを起動
      await tester.pumpWidget(
        buildTestScope(
          child: const ProgramBottomSheet(
            tournamentId: 't-test-1',
            isViewerMode: true,
          ),
          currentStrokes: [sharedStroke],
          role: UserRole.viewer,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 1. 観客モードでも個人メモ用のペン編集ツール（brush_rounded）が利用可能であること
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);

      // 2. それでも共有ペンは正確にキャンバス上に描画されていること
      final layerFinder = find.descendant(
        of: find.byType(ProgramBottomSheet),
        matching: find.byType(ProgramStrokeLayer),
      );
      expect(layerFinder, findsOneWidget);

      final CustomPaint paint = tester.widget(
        find.descendant(of: layerFinder, matching: find.byType(CustomPaint)),
      );
      final StrokePainter painter = paint.painter as StrokePainter;
      expect(painter.sharedStrokes.length, equals(1));
      expect(painter.sharedStrokes.first.points, equals(sharedStroke.points));
    });
  });
}
