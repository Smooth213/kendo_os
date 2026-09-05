import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_canvas_overlay.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_body.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
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
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class MockStrokeRepository extends Mock implements StrokeRepository {}

class MockLocalStrokeRepository extends Mock implements LocalStrokeRepository {}

class MockProgramRepository extends Mock implements ProgramRepository {}

class MockHttpOverrides extends HttpOverrides {
  final HttpClient client;
  MockHttpOverrides(this.client);
  @override
  HttpClient createHttpClient(SecurityContext? context) => client;
}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {
  final HttpClientResponse response;
  MockHttpClientRequest(this.response);

  @override
  Future<HttpClientResponse> close() async => response;

  @override
  Future<HttpClientResponse> addStream(Stream<List<int>> stream) =>
      stream.drain().then((_) => close());

  @override
  Future<void> flush() async {}

  @override
  Future<HttpClientResponse> get done => Future.value(response);
}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  static final List<int> _mockPdfBytes = () {
    final doc = PdfDocument();
    doc.pages.add();
    doc.pages.add();
    final bytes = doc.saveSync();
    doc.dispose();
    return bytes;
  }();

  final List<int> _bytes = _mockPdfBytes;
  final HttpHeaders _headers;

  MockHttpClientResponse(this._headers);

  @override
  HttpHeaders get headers => _headers;

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _bytes.length;

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class MockHttpHeaders extends Mock implements HttpHeaders {
  @override
  List<String>? operator [](String name) =>
      name.toLowerCase() == 'content-type' ? ['application/pdf'] : null;

  @override
  String? value(String name) =>
      name.toLowerCase() == 'content-type' ? 'application/pdf' : null;

  @override
  ContentType? get contentType => ContentType.parse('application/pdf');

  @override
  int get contentLength => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStrokeRepository mockStrokeRepo;
  late MockLocalStrokeRepository mockLocalStrokeRepo;
  late MockProgramRepository mockProgramRepo;
  late MockHttpClient mockClient;
  late MockHttpHeaders mockHeaders;
  late SharedPreferences prefs;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    mockClient = MockHttpClient();
    mockHeaders = MockHttpHeaders();
    when(() => mockClient.getUrl(any())).thenAnswer(
      (_) async => MockHttpClientRequest(MockHttpClientResponse(mockHeaders)),
    );
    when(() => mockClient.openUrl(any(), any())).thenAnswer(
      (_) async => MockHttpClientRequest(MockHttpClientResponse(mockHeaders)),
    );
    HttpOverrides.global = MockHttpOverrides(mockClient);
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  setUp(() async {
    mockStrokeRepo = MockStrokeRepository();
    mockLocalStrokeRepo = MockLocalStrokeRepository();
    mockProgramRepo = MockProgramRepository();

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    when(
      () => mockStrokeRepo.watchStrokes(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockLocalStrokeRepo.watchStrokes(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockProgramRepo.watchPrograms(any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  Widget createTestViewer(List<ProgramModel> programs) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
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
      child: MaterialApp(
        home: ProgramViewerScreen(programs: programs, initialIndex: 0),
      ),
    );
  }

  group('🥋 PDFプログラムビューア 直交ジェスチャー＆ペン完全一体化 堅牢性保護テスト', () {
    testWidgets(
      '1. 縦スクロール（Axis.vertical）と横スワイプ（Axis.horizontal）が直交して正しく配備されていること',
      (tester) async {
        final pdfProgram = ProgramModel(
          id: 'pdf-prog-1',
          tournamentId: 'tourney-test',
          title: '大会要項PDF',
          fileUrl: 'https://example.com/test_program.pdf',
          fileType: 'pdf',
          pageCount: 1,
          createdAt: DateTime.now(),
        );
        final imgProgram = ProgramModel(
          id: 'img-prog-2',
          tournamentId: 'tourney-test',
          title: 'トーナメント表画像',
          fileUrl: 'https://example.com/test_bracket.png',
          fileType: 'image',
          createdAt: DateTime.now(),
        );

        when(
          () => mockProgramRepo.watchPrograms(any()),
        ).thenAnswer((_) => Stream.value([pdfProgram, imgProgram]));

        await tester.pumpWidget(createTestViewer([pdfProgram, imgProgram]));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // 外側の PageView（横スワイプ・ファイル間移動）の存在と方向を検証
        final outerPageViewFinder = find.byType(PageView);
        expect(outerPageViewFinder, findsWidgets);

        final PageView outerPageView = tester.widget(outerPageViewFinder.first);
        expect(
          outerPageView.scrollDirection,
          equals(Axis.horizontal),
          reason: 'ファイル間移動は横スワイプ（Axis.horizontal）でなければなりません',
        );

        // PDF本文（ProgramViewerPdfBody）の存在を検証
        expect(find.byType(ProgramViewerPdfBody), findsOneWidget);

        // ProgramViewerPdfBody 内部の縦スクロール PageView（PDFページ間移動）を検証
        final verticalPageViewFinder = find.descendant(
          of: find.byType(ProgramViewerPdfBody),
          matching: find.byType(PageView),
        );
        expect(verticalPageViewFinder, findsOneWidget);

        final PageView verticalPageView = tester.widget(verticalPageViewFinder);
        expect(
          verticalPageView.scrollDirection,
          equals(Axis.vertical),
          reason: 'PDFページめくりは直感的な縦スクロール（Axis.vertical）でなければなりません',
        );
        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets(
      '2. Safari 4096px メモリ制限回避: PDF各ページのキャンバスサイズが 1414px 安全固定されていること',
      (tester) async {
        final pdfProgram = ProgramModel(
          id: 'pdf-prog-large',
          tournamentId: 'tourney-test',
          title: '長大プログラムPDF',
          fileUrl: 'https://example.com/large_program.pdf',
          fileType: 'pdf',
          pageCount: 3,
          createdAt: DateTime.now(),
        );

        when(
          () => mockProgramRepo.watchPrograms(any()),
        ).thenAnswer((_) => Stream.value([pdfProgram]));

        await tester.pumpWidget(createTestViewer([pdfProgram]));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // ProgramViewerPdfBody 内のキャンバス SizedBox を検証
        final sizedBoxFinder = find.descendant(
          of: find.byType(ProgramViewerPdfBody),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is SizedBox &&
                widget.width == 1000.0 &&
                widget.height == 1414.0,
          ),
        );
        expect(
          sizedBoxFinder,
          findsOneWidget,
          reason:
              'Safariの4096pxメモリ上限を超えないよう、各ページは高さ1414pxの安全サイズで固定されていなければなりません',
        );
        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets(
      '3. ペン書き込みモード時: 縦・横両方のスワイプ物理が NeverScrollableScrollPhysics にロックされること',
      (tester) async {
        final pdfProgram = ProgramModel(
          id: 'pdf-prog-lock',
          tournamentId: 'tourney-test',
          title: '大会要項PDF',
          fileUrl: 'https://example.com/test.pdf',
          fileType: 'pdf',
          pageCount: 2,
          createdAt: DateTime.now(),
        );

        when(
          () => mockProgramRepo.watchPrograms(any()),
        ).thenAnswer((_) => Stream.value([pdfProgram]));

        await tester.pumpWidget(createTestViewer([pdfProgram]));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // 初期状態（通常表示）: 縦スクロールは PageScrollPhysics、横スクロールは ClampingScrollPhysics
        PageView outerPageView = tester.widget(find.byType(PageView).first);
        expect(
          outerPageView.physics,
          isA<ClampingScrollPhysics>(),
          reason: '倍率1倍の通常時は横スワイプが有効でなければなりません',
        );

        // 「書き込む」ボタンをタップして描画モードをONにする
        final drawButton = find.byIcon(Icons.edit);
        expect(drawButton, findsOneWidget);
        await tester.tap(drawButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // 描画モードON時: 外側（横）も内側（縦）も NeverScrollableScrollPhysics にロックされることを検証
        outerPageView = tester.widget(find.byType(PageView).first);
        expect(
          outerPageView.physics,
          isA<NeverScrollableScrollPhysics>(),
          reason: 'ペン描画中は誤ってファイルが横移動しないようロックされなければなりません',
        );

        final verticalPageViewFinder = find.descendant(
          of: find.byType(ProgramViewerPdfBody),
          matching: find.byType(PageView),
        );
        final PageView verticalPageView = tester.widget(verticalPageViewFinder);
        expect(
          verticalPageView.physics,
          isA<NeverScrollableScrollPhysics>(),
          reason: 'ペン描画中は誤ってページが縦スクロールしないようロックされなければなりません',
        );
        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets('4. ペンと用紙の完全一体化: 用紙と手書きオーバーレイが同一の Stack 内で同居していること', (
      tester,
    ) async {
      final pdfProgram = ProgramModel(
        id: 'pdf-prog-stack',
        tournamentId: 'tourney-test',
        title: '大会要項PDF',
        fileUrl: 'https://example.com/test.pdf',
        fileType: 'pdf',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([pdfProgram]));

      await tester.pumpWidget(createTestViewer([pdfProgram]));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // ProgramViewerCanvasOverlay と SfPdfViewer が同一の親 Stack 内で同居していること
      final overlayFinder = find.byType(ProgramViewerCanvasOverlay);
      expect(overlayFinder, findsOneWidget);

      final parentStackFinder = find.ancestor(
        of: overlayFinder,
        matching: find.byType(Stack),
      );
      expect(parentStackFinder, findsWidgets);

      final pdfViewerInSameStack = find.descendant(
        of: parentStackFinder.first,
        matching: find.byType(SfPdfViewer),
      );
      expect(
        pdfViewerInSameStack,
        findsOneWidget,
        reason: 'PDF用紙と手書きペンは同じStack内に一体配置されていなければなりません',
      );
      expect(
        overlayFinder,
        findsOneWidget,
        reason: 'PDF用紙と手書きペンは同じStack内に一体配置されていなければなりません',
      );
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('5. ページごとのペン分離: 各ページの手書きペンがページ番号（pageIndex）ごとに独立管理されること', (
      tester,
    ) async {
      final pdfProgram = ProgramModel(
        id: 'pdf-prog-multi',
        tournamentId: 'tourney-test',
        title: '大会要項PDF',
        fileUrl: 'https://example.com/test_multi.pdf',
        fileType: 'pdf',
        pageCount: 2,
        createdAt: DateTime.now(),
      );

      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([pdfProgram]));

      await tester.pumpWidget(createTestViewer([pdfProgram]));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // ページ0の ProgramViewerCanvasOverlay を検証
      final overlay = tester.widget<ProgramViewerCanvasOverlay>(
        find.byType(ProgramViewerCanvasOverlay),
      );
      expect(
        overlay.pageIndex,
        equals(0),
        reason: '1ページ目のペンは pageIndex: 0 として独立管理されなければなりません',
      );
      expect(overlay.programId, equals('pdf-prog-multi'));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
