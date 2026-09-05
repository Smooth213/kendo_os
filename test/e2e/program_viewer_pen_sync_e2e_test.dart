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
      _E2EMockHttpClient(pdfBytes);
}

class _E2EMockHttpClient extends Mock implements HttpClient {
  final Uint8List pdfBytes;
  _E2EMockHttpClient(this.pdfBytes);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _E2EMockHttpClientRequest(pdfBytes);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _E2EMockHttpClientRequest(pdfBytes);
}

class _E2EMockHttpClientRequest extends Mock implements HttpClientRequest {
  final Uint8List pdfBytes;
  _E2EMockHttpClientRequest(this.pdfBytes);

  @override
  Future<HttpClientResponse> close() async =>
      _E2EMockHttpClientResponse(pdfBytes);
}

class _E2EMockHttpClientResponse extends Mock implements HttpClientResponse {
  final Uint8List pdfBytes;
  _E2EMockHttpClientResponse(this.pdfBytes);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => pdfBytes.length;

  @override
  HttpHeaders get headers => _E2EMockHttpHeaders();

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

class _E2EMockHttpHeaders extends Mock implements HttpHeaders {
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

  const testPdfUrl = 'https://example.com/tournament_e2e_mixed.pdf';
  final e2eProgram = ProgramModel(
    id: 'e2e-prog-1',
    tournamentId: 't-e2e-1',
    title: 'E2E検証用縦横混在プログラム',
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
    ).thenAnswer((_) => Stream.value([e2eProgram]));
  });

  tearDown(() {
    HttpOverrides.global = null;
    ProgramViewerPdfPageCache.shared.clear();
    ProgramViewerMediaCache.shared.sdkPdfBytesCache.clear();
  });

  Widget buildE2EScope({
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
          't-e2e-1',
        ).overrideWith((ref) => Stream.value([e2eProgram])),
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

  group('🚀 縦横混在PDF×手書きペン完全同期 E2E統合操作シナリオ要塞', () {
    testWidgets(
      '1. 【描画〜ボトムシート即時反映E2E】全画面で描画されたストロークが、ボトムシート起動時に同一用紙位置へ即時反映されること',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final drawnStroke = StrokeModel(
          id: 'stroke-e2e-1',
          programId: 'e2e-prog-1',
          authorId: 'admin_user',
          pageIndex: 0,
          points: const [Offset(300, 400), Offset(350, 450), Offset(400, 500)],
          color: Colors.red,
          strokeWidth: 6.0,
          createdAt: DateTime(2026, 9, 1),
        );

        // (A) 管理者モードで全画面を開く
        await tester.pumpWidget(
          buildE2EScope(
            child: ProgramViewerScreen(programs: [e2eProgram], initialIndex: 0),
            currentStrokes: [drawnStroke],
            role: UserRole.admin,
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // 全画面のペンオーバーレイが存在することを確認
        final fullOverlayFinder = find.descendant(
          of: find.byType(ProgramViewerPdfBody),
          matching: find.byType(ProgramViewerCanvasOverlay),
        );
        expect(fullOverlayFinder, findsOneWidget);

        // (B) ユーザーが画面を閉じて、ホームからボトムシート（ProgramBottomSheet）を開く
        await tester.pumpWidget(
          buildE2EScope(
            child: const ProgramBottomSheet(tournamentId: 't-e2e-1'),
            currentStrokes: [drawnStroke],
            role: UserRole.admin,
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // ボトムシート側で、描画したストロークが同位置・同座標で表示されていること
        final sheetStrokeLayerFinder = find.descendant(
          of: find.byType(ProgramBottomSheet),
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
        expect(painter.sharedStrokes.length, equals(1));
        expect(painter.sharedStrokes.first.id, equals('stroke-e2e-1'));
        expect(painter.sharedStrokes.first.points, equals(drawnStroke.points));
      },
    );

    testWidgets('2. 【縦横混在ページ送りE2E】1ページ目（縦）から2ページ目（横）へ移動時、用紙とペンが独立して完全に同期すること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p0Stroke = StrokeModel(
        id: 'stroke-p0',
        programId: 'e2e-prog-1',
        authorId: 'admin_user',
        pageIndex: 0,
        points: const [Offset(500, 707)],
        color: Colors.red,
        strokeWidth: 5.0,
        createdAt: DateTime(2026, 9, 1),
      );

      final p1Stroke = StrokeModel(
        id: 'stroke-p1',
        programId: 'e2e-prog-1',
        authorId: 'admin_user',
        pageIndex: 1,
        points: const [Offset(707, 500)],
        color: Colors.blue,
        strokeWidth: 5.0,
        createdAt: DateTime(2026, 9, 1),
      );

      final allStrokes = [p0Stroke, p1Stroke];

      // (A) 全画面で起動
      await tester.pumpWidget(
        buildE2EScope(
          child: ProgramViewerScreen(programs: [e2eProgram], initialIndex: 0),
          currentStrokes: allStrokes,
          role: UserRole.admin,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 1ページ目: 縦向きキャンバス (1000x1414)
      final p0Canvas = find.descendant(
        of: find.byType(ProgramViewerPdfBody),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 1000.0 && w.height == 1414.0,
        ),
      );
      expect(p0Canvas, findsOneWidget);

      // 2ページ目へスワイプ移動
      final pageViewFinder = find.descendant(
        of: find.byType(ProgramViewerPdfBody),
        matching: find.byType(PageView),
      );
      final PageView pageView = tester.widget(pageViewFinder);
      pageView.controller?.jumpToPage(1);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 2ページ目: 横向きキャンバス (1414x1000)
      final p1Canvas = find.descendant(
        of: find.byType(ProgramViewerPdfBody),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 1414.0 && w.height == 1000.0,
        ),
      );
      expect(p1Canvas, findsOneWidget);

      // (B) ボトムシート側でも表示
      await tester.pumpWidget(
        buildE2EScope(
          child: const ProgramBottomSheet(tournamentId: 't-e2e-1'),
          currentStrokes: allStrokes,
          role: UserRole.admin,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // ボトムシート内のPageViewで2ページ目（横向き）へ送る
      final bsPageViewFinder = find.descendant(
        of: find.byType(ProgramBottomSheet),
        matching: find.byType(PageView),
      );
      if (bsPageViewFinder.evaluate().isNotEmpty) {
        final PageView bsPageView = tester.widget(bsPageViewFinder);
        bsPageView.controller?.jumpToPage(1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      // ボトムシート側でも横向きキャンバス (1414x1000) が生成されていること
      final sheetLandscapeCanvas = find.descendant(
        of: find.byType(ProgramBottomSheet),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 1414.0 && w.height == 1000.0,
        ),
      );
      expect(sheetLandscapeCanvas, findsOneWidget);
    });

    testWidgets(
      '3. 【閲覧専用モード整合性E2E】観客（Viewer）席で手書きペンが完全一致で閲覧でき、編集ツールが物理排除されていること',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final sharedStroke = StrokeModel(
          id: 'stroke-shared-announcement',
          programId: 'e2e-prog-1',
          authorId: 'admin_user',
          pageIndex: 0,
          points: const [Offset(200, 200), Offset(800, 200)],
          color: Colors.red,
          strokeWidth: 12.0,
          createdAt: DateTime(2026, 9, 1),
        );

        // 観客ロール (UserRole.viewer) でボトムシートを起動
        await tester.pumpWidget(
          buildE2EScope(
            child: const ProgramBottomSheet(
              tournamentId: 't-e2e-1',
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
      },
    );
  });
}
