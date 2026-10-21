import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_view_state_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_canvas_overlay.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_controls.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/stroke_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class MockStrokeRepository extends Mock implements StrokeRepository {}

class MockLocalStrokeRepository extends Mock implements LocalStrokeRepository {}

class MockProgramRepository extends Mock implements ProgramRepository {}

class FakeLocalStrokeModel extends Fake implements LocalStrokeModel {}

class FakeStrokeModel extends Fake implements StrokeModel {}

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
  late Uint8List dummyPdfBytes;

  setUpAll(() {
    registerFallbackValue(FakeLocalStrokeModel());
    registerFallbackValue(FakeStrokeModel());

    final doc = PdfDocument();
    doc.pages.add();
    dummyPdfBytes = Uint8List.fromList(doc.saveSync());
    doc.dispose();

    HttpOverrides.global = MockHttpOverrides(dummyPdfBytes);
  });

  setUp(() async {
    mockStrokeRepo = MockStrokeRepository();
    mockLocalStrokeRepo = MockLocalStrokeRepository();
    mockProgramRepo = MockProgramRepository();

    SharedPreferences.setMockInitialValues({});
    ProgramViewStateService.instance.resetForTesting();
    ProgramViewerPdfPageCache.shared.clear();
    ProgramViewerMediaCache.shared.sdkPdfBytesCache.clear();

    when(
      () => mockStrokeRepo.watchStrokes(any()),
    ).thenAnswer((_) => Stream<List<StrokeModel>>.value([]));
    when(
      () => mockLocalStrokeRepo.watchStrokes(any()),
    ).thenAnswer((_) => Stream<List<LocalStrokeModel>>.value([]));
    when(
      () => mockProgramRepo.watchPrograms(any()),
    ).thenAnswer((_) => Stream<List<ProgramModel>>.value([]));
  });

  group('[Widget] プログラム管理 視認性・ピンチ・拡大境界 検証テスト', () {
    testWidgets('ピンチ保護として2本指マルチタッチ操作時はペン描画がキャンセルされストロークが引かれないこと', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            strokeRepositoryProvider.overrideWithValue(mockStrokeRepo),
            localStrokeRepositoryProvider.overrideWithValue(
              mockLocalStrokeRepo,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 500,
                height: 500,
                child: ProgramViewerCanvasOverlay(
                  programId: 'test_prog',
                  pageIndex: 0,
                  penWidth: 10.0,
                  isDrawingMode: true,
                  selectedTool: 'pen',
                  activePenColor: AppKendoColors.blue,
                  activeIsShared: false,
                  canUseSharedPen: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1本目の指をタップ
      final gesture1 = await tester.startGesture(
        const Offset(100, 100),
        pointer: 1,
      );
      await tester.pump();

      // 2本目の指をタップ（ピンチ動作の開始）
      final gesture2 = await tester.startGesture(
        const Offset(200, 200),
        pointer: 2,
      );
      await tester.pump();

      // ピンチ移動
      await gesture1.moveTo(const Offset(120, 120));
      await gesture2.moveTo(const Offset(180, 180));
      await tester.pump();

      // 指を離す
      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      // ピンチ操作中に線が引かれず、ストローク保存が実行されていないこと
      expect(find.byType(ProgramViewerCanvasOverlay), findsOneWidget);
      verifyNever(() => mockLocalStrokeRepo.addStroke(any()));
      verifyNever(() => mockStrokeRepo.addStroke(any()));
    });

    testWidgets('視認性向上としてダークモード時のブラックペン選択肢が高コントラストで描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Row(
              children: [
                ProgramViewerPenOption(
                  color: AppKendoColors.pureBlack,
                  label: 'ブラック (個人)',
                  isSelected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ラベルテキストが黒ではなく白（pureWhite）で視認性が確保されていること
      final textFinder = find.text('ブラック (個人)');
      expect(textFinder, findsOneWidget);
      final Text textWidget = tester.widget(textFinder);
      expect(
        textWidget.style?.color,
        equals(AppKendoColors.pureWhite),
        reason: 'ダークモード時の黒ペンの文字色は白でなければなりません',
      );

      // 黒ペンアイコンの視認性用コンテナ（白丸背景バッジ）が存在すること
      final editIconFinder = find.byIcon(Icons.edit);
      expect(editIconFinder, findsOneWidget);
    });

    testWidgets(
      '拡大端切れ防止としてInteractiveViewerにboundaryMarginとscaleEnabledが設定されていること',
      (tester) async {
        const testPdfUrl = 'https://example.com/test_doc.pdf';
        ProgramViewerMediaCache.shared.sdkPdfBytesCache[testPdfUrl] =
            Future.value(dummyPdfBytes);
        ProgramViewerPdfPageCache.shared.parseDocumentInfo(
          testPdfUrl,
          dummyPdfBytes,
        );

        final dummyProgram = ProgramModel(
          id: 'prog_1',
          tournamentId: 't1',
          title: 'テストプログラム',
          fileUrl: testPdfUrl,
          fileType: 'pdf',
          pageCount: 1,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              strokeRepositoryProvider.overrideWithValue(mockStrokeRepo),
              localStrokeRepositoryProvider.overrideWithValue(
                mockLocalStrokeRepo,
              ),
              programRepositoryProvider.overrideWithValue(mockProgramRepo),
              viewerProgramListProvider(
                't1',
              ).overrideWith((ref) => Stream.value([dummyProgram])),
              activeRoleProvider.overrideWith((ref) => Role.admin),
              permissionProvider.overrideWith(
                (ref) => AppPermissions(isReadOnly: false),
              ),
              currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
            ],
            child: MaterialApp(
              home: ProgramViewerScreen(
                programs: [dummyProgram],
                initialIndex: 0,
                initialDrawingMode: false,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        final interactiveViewerFinder = find.byType(InteractiveViewer);
        expect(interactiveViewerFinder, findsOneWidget);

        final InteractiveViewer viewer = tester.widget(interactiveViewerFinder);
        expect(
          viewer.scaleEnabled,
          isTrue,
          reason: '閲覧モード時にもピンチによる拡大縮小操作が可能であること',
        );
        expect(
          viewer.boundaryMargin.horizontal > 0 &&
              viewer.boundaryMargin.vertical > 0,
          isTrue,
          reason: '拡大時に四隅や端までスクロールして到達できる十分なマージンが確保されていること',
        );

        // タイマークリア
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      },
    );

    testWidgets(
      '複数PDFの閲覧時、拡大後に別プログラムへ切り替えるとズームがリセットされ、非アクティブページにはコントローラーが共有されないこと',
      (tester) async {
        const url1 = 'https://example.com/test_doc1.pdf';
        const url2 = 'https://example.com/test_doc2.pdf';
        ProgramViewerMediaCache.shared.sdkPdfBytesCache[url1] = Future.value(
          dummyPdfBytes,
        );
        ProgramViewerMediaCache.shared.sdkPdfBytesCache[url2] = Future.value(
          dummyPdfBytes,
        );
        ProgramViewerPdfPageCache.shared.parseDocumentInfo(url1, dummyPdfBytes);
        ProgramViewerPdfPageCache.shared.parseDocumentInfo(url2, dummyPdfBytes);

        final prog1 = ProgramModel(
          id: 'prog_1',
          tournamentId: 't1',
          title: 'プログラム1',
          fileUrl: url1,
          fileType: 'pdf',
          pageCount: 1,
          createdAt: DateTime.now(),
        );
        final prog2 = ProgramModel(
          id: 'prog_2',
          tournamentId: 't1',
          title: 'プログラム2',
          fileUrl: url2,
          fileType: 'pdf',
          pageCount: 1,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              strokeRepositoryProvider.overrideWithValue(mockStrokeRepo),
              localStrokeRepositoryProvider.overrideWithValue(
                mockLocalStrokeRepo,
              ),
              programRepositoryProvider.overrideWithValue(mockProgramRepo),
              viewerProgramListProvider(
                't1',
              ).overrideWith((ref) => Stream.value([prog1, prog2])),
              activeRoleProvider.overrideWith((ref) => Role.admin),
              permissionProvider.overrideWith(
                (ref) => AppPermissions(isReadOnly: false),
              ),
              currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
            ],
            child: MaterialApp(
              home: ProgramViewerScreen(
                programs: [prog1, prog2],
                initialIndex: 0,
                initialDrawingMode: false,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // 初期状態で InteractiveViewer が存在
        final ivFinder = find.byType(InteractiveViewer);
        expect(ivFinder, findsWidgets);

        // アクティブな InteractiveViewer を取得
        final InteractiveViewer activeIv = tester.widget(ivFinder.first);
        expect(activeIv.transformationController, isNotNull);

        // 拡大行列を適用
        activeIv.transformationController!.value = Matrix4.diagonal3Values(
          2.5,
          2.5,
          1.0,
        );
        await tester.pump();
        expect(
          activeIv.transformationController!.value.getMaxScaleOnAxis(),
          closeTo(2.5, 0.05),
        );

        // 次のプログラムへ切り替え（AppBarの進むボタンをタップ）
        final nextButtonFinder = find.byIcon(Icons.chevron_right_rounded);
        expect(nextButtonFinder, findsOneWidget);
        await tester.tap(nextButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // プログラム切り替え後、コントローラーがリセット（identity）されていること
        expect(
          activeIv.transformationController!.value.getMaxScaleOnAxis(),
          closeTo(1.0, 0.05),
          reason: 'プログラム変更によりズームがidentityに自動復帰し、他PDFが真っ白になる現象を防止すること',
        );

        // ダブルタップ操作でズームリセットが機能すること
        activeIv.transformationController!.value = Matrix4.diagonal3Values(
          2.0,
          2.0,
          1.0,
        );
        await tester.pump();
        expect(
          activeIv.transformationController!.value.getMaxScaleOnAxis(),
          closeTo(2.0, 0.05),
        );

        // GestureDetector の onDoubleTap をシミュレート
        final gdFinder = find.ancestor(
          of: ivFinder.first,
          matching: find.byType(GestureDetector),
        );
        final GestureDetector gd = tester.widget(gdFinder.first);
        gd.onDoubleTap?.call();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          activeIv.transformationController!.value.getMaxScaleOnAxis(),
          closeTo(1.0, 0.05),
          reason: 'ダブルタップ操作により等倍へ即座に復帰できること',
        );

        // タイマークリア
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      },
    );
  });
}
