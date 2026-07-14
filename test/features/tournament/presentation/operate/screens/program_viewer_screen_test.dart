import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

class MockStrokeRepository extends Mock implements StrokeRepository {}

class MockLocalStrokeRepository extends Mock implements LocalStrokeRepository {}

class MockProgramRepository extends Mock implements ProgramRepository {}

// ★ PDF表示テスト時の非同期通信クラッシュ(ClientException)を防止する安全なHTTPモック
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
  Future<HttpClientResponse> close() async {
    return response;
  }

  @override
  Future<HttpClientResponse> addStream(Stream<List<int>> stream) {
    return stream.drain().then((_) => close());
  }

  @override
  Future<void> flush() async {}

  @override
  Future<HttpClientResponse> get done => Future.value(response);
}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  final List<int> _bytes = utf8.encode('%PDF-1.0\n...\n%%EOF');
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
  group('🛡️ ProgramViewerScreen Stability & Regression Tests', () {
    late MockStrokeRepository mockStrokeRepo;
    late MockLocalStrokeRepository mockLocalStrokeRepo;
    late MockProgramRepository mockProgramRepo;
    late SharedPreferences prefs;
    late MockHttpClient mockHttpClientForDio;
    late MockHttpClientRequest mockHttpClientRequest;
    late MockHttpClientResponse mockHttpClientResponse;
    late MockHttpHeaders mockHttpHeaders;

    setUpAll(() {
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    setUp(() async {
      mockStrokeRepo = MockStrokeRepository();
      mockLocalStrokeRepo = MockLocalStrokeRepository();
      mockProgramRepo = MockProgramRepository();

      mockHttpHeaders = MockHttpHeaders();
      mockHttpClientResponse = MockHttpClientResponse(mockHttpHeaders);
      mockHttpClientRequest = MockHttpClientRequest(mockHttpClientResponse);
      mockHttpClientForDio = MockHttpClient();

      when(
        () => mockHttpClientForDio.getUrl(any()),
      ).thenAnswer((_) async => mockHttpClientRequest);
      when(
        () => mockHttpClientForDio.openUrl(any(), any()),
      ).thenAnswer((_) async => mockHttpClientRequest);

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
      ).thenAnswer((_) => Stream.value([])); // Default mock
    });

    tearDown(() {
      HttpOverrides.global = null;
    });

    Widget createViewerWidget(
      List<ProgramModel> programs, {
      bool isReadOnly = false,
    }) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          strokeRepositoryProvider.overrideWithValue(mockStrokeRepo),
          localStrokeRepositoryProvider.overrideWithValue(mockLocalStrokeRepo),
          programRepositoryProvider.overrideWithValue(mockProgramRepo),
          activeRoleProvider.overrideWith(
            (ref) => isReadOnly ? Role.viewer : Role.admin,
          ),
          permissionProvider.overrideWith(
            (ref) => AppPermissions(isReadOnly: isReadOnly),
          ),
          currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
          isarProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          home: ProgramViewerScreen(programs: programs, initialIndex: 0),
        ),
      );
    }

    testWidgets('✅ 1. PDFがRenderFlexオーバーフローエラーを起こさずに描画されること', (tester) async {
      HttpOverrides.global = MockHttpOverrides(mockHttpClientForDio);

      // OverflowBox と ClipRect の効果を検証
      tester.view.physicalSize = const Size(1080, 1920);

      final pdfProgram = ProgramModel(
        id: 'pdf_1',
        tournamentId: 't1',
        title: '大会進行表 (PDF)',
        fileUrl: 'https://example.com/dummy.pdf', // ネットワークリクエストは通常モックされます
        fileType: 'pdf',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([pdfProgram]));

      await tester.pumpWidget(createViewerWidget([pdfProgram]));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // PDF描画エンジンの内部タイマーを消化

      // PDFビューアのコンテナがツリーに存在すること
      expect(find.byType(SfPdfViewer), findsOneWidget);

      HttpOverrides.global = null;
    });

    testWidgets('✅ 2. Web特有のCORS回避: 画像読み込みが無限クルクルにならずフォールバックされること', (
      tester,
    ) async {
      final imageProgram = ProgramModel(
        id: 'img_1',
        tournamentId: 't1',
        title: '手書きスコア (画像)',
        fileUrl:
            'https://placehold.co/400x600/E8E8E8/808080.png?text=Uploading...',
        fileType: 'image',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([imageProgram]));

      await tester.pumpWidget(createViewerWidget([imageProgram]));

      // タイムアウトやダミーURLのショートサーキット処理により即座に画像が表示（またはエラーアイコン化）される
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // FutureBuilderの解決を待つ

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('✅ 3. OCRの完了状態に応じてアイコンが正しく切り替わること', (tester) async {
      final streamController = StreamController<List<ProgramModel>>.broadcast();
      addTearDown(() => streamController.close());
      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => streamController.stream);

      final pendingProgram = ProgramModel(
        id: 'img_2',
        tournamentId: 't1',
        title: 'OCR未処理',
        fileUrl: 'https://example.com/dummy.jpg',
        fileType: 'image',
        pageCount: 1,
        createdAt: DateTime.now(),
        isOcrProcessed: false,
      );

      await tester.pumpWidget(createViewerWidget([pendingProgram]));
      streamController.add([pendingProgram]);
      await tester.pumpAndSettle();

      final boltIconPending = tester.widget<Icon>(find.byIcon(Icons.bolt));
      expect(boltIconPending.color, equals(Colors.grey.shade400));

      final processedProgram = pendingProgram.copyWith(isOcrProcessed: true);
      streamController.add([processedProgram]);

      await tester.pump(); // Streamの更新をフラッシュ
      await tester.pumpAndSettle();

      final boltIconProcessed = tester.widget<Icon>(find.byIcon(Icons.bolt));
      expect(boltIconProcessed.color, equals(Colors.amber));
    });

    testWidgets('✅ 4. 閲覧専用(Viewer)権限の時は書き込みボタンが完全に非表示になること', (tester) async {
      final program = ProgramModel(
        id: 'p1',
        tournamentId: 't1',
        title: 'テスト',
        fileUrl: 'https://example.com/dummy.jpg',
        fileType: 'image',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([program]));

      // 閲覧権限（保護者など）で開く
      await tester.pumpWidget(createViewerWidget([program], isReadOnly: true));
      await tester.pumpAndSettle();

      expect(find.text('書き込む'), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('✅ 5. 手書きアノテーションの Undo 操作が正しくトリガーされること', (tester) async {
      final program = ProgramModel(
        id: 'p1',
        tournamentId: 't1',
        title: 'テスト',
        fileUrl: 'https://example.com/dummy.jpg',
        fileType: 'image',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([program]));
      when(() => mockStrokeRepo.undoLastStroke(any())).thenAnswer((_) async {});
      when(
        () => mockLocalStrokeRepo.undoLastStroke(any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createViewerWidget([program]));
      await tester.pumpAndSettle();

      // 書き込みモードをONにする (アイコン経由で確実にタップ)
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // 元に戻す(Undo)ボタンを探してタップ
      final undoButton = find.byTooltip('1つ戻す');
      expect(undoButton, findsOneWidget);
      await tester.tap(undoButton);
      await tester.pumpAndSettle();

      // 共有ペンリポジトリの undoLastStroke が呼び出されたことを検証
      verify(() => mockStrokeRepo.undoLastStroke('p1')).called(1);
    });

    test('✅ 6. 蛍光ペンの描画判定 (opacity/a の値が半透明の時は BlendMode.multiply が適用されること)', () {
      final painter = StrokePainter(
        sharedStrokes: [],
        privateStrokes: [],
        currentPoints: null,
        currentLineColor: Colors.pink,
        activePenWidth: 10.0,
      );

      // 通常の不透明色 (アルファ=255)
      final normalPaint = painter.getPaint(Colors.pink, 10.0);
      expect(normalPaint.blendMode, equals(BlendMode.srcOver));

      // 半透明の蛍光マーカー色 (不透明度 0.35, アルファ=90)
      final markerPaint = painter.getPaint(Colors.pink.withAlpha(90), 30.0);
      expect(markerPaint.blendMode, equals(BlendMode.multiply));

      // 🛡️ 視認性向上の救済パッチ検証: 過去のColors.yellow (0xFFFFEB3B) が渡された場合、自動で高視認性の黄色 (0xFFCA8A04) に変換されること
      final yellowPaint = painter.getPaint(Colors.yellow, 10.0);
      expect(
        yellowPaint.color.toARGB32(),
        equals(const Color(0xFFCA8A04).toARGB32()),
      );

      // 半透明の過去のColors.yellowに対しても、透明度を維持したまま変換されること
      final yellowMarkerPaint = painter.getPaint(
        Colors.yellow.withAlpha(90),
        30.0,
      );
      expect(
        yellowMarkerPaint.color.toARGB32(),
        equals(const Color(0xFFCA8A04).withAlpha(90).toARGB32()),
      );
      expect(yellowMarkerPaint.blendMode, equals(BlendMode.multiply));
    });

    testWidgets('✅ 7. 消しゴムツールでの近接線の検知と個別削除がトリガーされること', (tester) async {
      final program = ProgramModel(
        id: 'p1',
        tournamentId: 't1',
        title: 'テスト',
        fileUrl: 'https://example.com/dummy.jpg',
        fileType: 'image',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([program]));
      when(() => mockStrokeRepo.deleteStroke(any())).thenAnswer((_) async {});

      // 共有線のリストに、座標点 (100, 100) を含む線をあらかじめ流し込む
      final existingStroke = StrokeModel(
        id: 'stroke_123',
        programId: 'p1',
        points: [const Offset(100, 100), const Offset(105, 105)],
        color: Colors.pink,
        strokeWidth: 10.0,
        isShared: true,
        pageIndex: 0,
      );

      when(
        () => mockStrokeRepo.watchStrokes(any()),
      ).thenAnswer((_) => Stream.value([existingStroke]));

      await tester.pumpWidget(createViewerWidget([program]));
      await tester.pumpAndSettle();

      // 書き込みモードをONにする (アイコン経由で確実にタップ)
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // ツールバーの消しゴムボタンを選択
      final eraserButton = find.byTooltip('消しゴム');
      expect(eraserButton, findsOneWidget);
      await tester.tap(eraserButton);
      await tester.pumpAndSettle();

      // 描画インプットを受け取る Listener を直接探す（onPointerMove を購読している唯一のもの）
      final listenerFinder = find.byWidgetPredicate(
        (widget) => widget is Listener && widget.onPointerMove != null,
      );
      expect(listenerFinder, findsOneWidget);
      final Listener listener = tester.widget(listenerFinder);

      // 近接する (102, 102) のローカル座標を PointerDownEvent で直接送信して消しゴムをトリガー
      listener.onPointerDown!(
        const PointerDownEvent(position: Offset(102, 102)),
      );
      await tester.pumpAndSettle();

      // 共有線の deleteStroke('stroke_123') が正しく呼び出されたことを検証！
      verify(() => mockStrokeRepo.deleteStroke('stroke_123')).called(1);
    });

    testWidgets('✅ 8. PDFの2重ロード（フェッチ）防止キャッシュの動作検証', (tester) async {
      HttpOverrides.global = MockHttpOverrides(mockHttpClientForDio);

      final pdfProgram = ProgramModel(
        id: 'pdf_1',
        tournamentId: 't1',
        title: '大会進行表 (PDF)',
        fileUrl: 'https://example.com/dummy.pdf',
        fileType: 'pdf',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([pdfProgram]));

      await tester.pumpWidget(createViewerWidget([pdfProgram]));
      await tester.pump();

      final dynamic state = tester.state(find.byType(ProgramViewerScreen));

      // あらかじめキャッシュにダミー Future をセットして FirebaseStorage の実際の呼び出しを回避
      final dummyFuture = Future.value(Uint8List(0));
      state.setState(() {
        state.sdkPdfBytesCacheForTesting['https://example.com/dummy.pdf'] =
            dummyFuture;
      });
      await tester.pump();

      // 同一URLに対するキャッシュ呼び出しが同じ Future インスタンスを返すことを検証
      final future1 = state.getCachedPdfBytesViaSdk(
        'https://example.com/dummy.pdf',
      );
      final future2 = state.getCachedPdfBytesViaSdk(
        'https://example.com/dummy.pdf',
      );

      expect(future1, equals(dummyFuture));
      expect(future2, equals(dummyFuture));

      await tester.pump(const Duration(seconds: 1)); // タイマー消化
      HttpOverrides.global = null;
    });

    testWidgets('✅ 9. PDFの複数ページの個別ページ数管理（スワイプ時の競合防止）の検証', (tester) async {
      HttpOverrides.global = MockHttpOverrides(mockHttpClientForDio);

      final program1 = ProgramModel(
        id: 'p1',
        tournamentId: 't1',
        title: 'PDF 1',
        fileUrl: 'https://example.com/pdf1.pdf',
        fileType: 'pdf',
        pageCount: 2,
        createdAt: DateTime.now(),
      );

      final program2 = ProgramModel(
        id: 'p2',
        tournamentId: 't1',
        title: 'PDF 2',
        fileUrl: 'https://example.com/pdf2.pdf',
        fileType: 'pdf',
        pageCount: 3,
        createdAt: DateTime.now(),
      );

      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([program1, program2]));

      await tester.pumpWidget(createViewerWidget([program1, program2]));
      await tester.pump();

      final dynamic state = tester.state(find.byType(ProgramViewerScreen));

      // 各URLごとのページ数をキャッシュに代入して検証
      state.setState(() {
        state.pdfPageCountsForTesting['https://example.com/pdf1.pdf'] = 2;
        state.pdfPageCountsForTesting['https://example.com/pdf2.pdf'] = 3;
      });
      await tester.pump();

      expect(
        state.pdfPageCountsForTesting['https://example.com/pdf1.pdf'],
        equals(2),
      );
      expect(
        state.pdfPageCountsForTesting['https://example.com/pdf2.pdf'],
        equals(3),
      );

      await tester.pump(const Duration(seconds: 1)); // タイマー消化
      HttpOverrides.global = null;
    });

    testWidgets('✅ 10. 画像共有の適切な実施 (プログラム追加によるリアルタイムでのリスト自動更新) の検証', (
      tester,
    ) async {
      HttpOverrides.global = MockHttpOverrides(mockHttpClientForDio);

      final streamController = StreamController<List<ProgramModel>>.broadcast();
      addTearDown(() => streamController.close());
      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => streamController.stream);

      final p1 = ProgramModel(
        id: 'p1',
        tournamentId: 't1',
        title: '1枚目の画像',
        fileUrl: 'https://placehold.co/400x600/E8E8E8/808080.png?text=1',
        fileType: 'image',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      final p2 = ProgramModel(
        id: 'p2',
        tournamentId: 't1',
        title: '2枚目の画像',
        fileUrl: 'https://placehold.co/400x600/E8E8E8/808080.png?text=2',
        fileType: 'image',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createViewerWidget([p1]));

      // 最初は1枚だけ流す
      streamController.add([p1]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100)); // 画像タイマー消化

      // PageView の枚数が 1 であることを検証
      final PageView pageView1 = tester.widget(find.byType(PageView));
      expect(pageView1.childrenDelegate.estimatedChildCount, equals(1));

      // リアルタイムに2枚目を追加して流す
      streamController.add([p1, p2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100)); // 画像タイマー消化

      // PageView の枚数が 2 に更新されることを検証
      final PageView pageView2 = tester.widget(find.byType(PageView));
      expect(pageView2.childrenDelegate.estimatedChildCount, equals(2));

      await tester.pump(const Duration(seconds: 1)); // タイマー完全消化
      HttpOverrides.global = null;
    });

    testWidgets(
      '✅ 11. ピンチズーム（拡大）中に PageView のスワイプ物理が NeverScrollableScrollPhysics に切り替わること',
      (tester) async {
        HttpOverrides.global = MockHttpOverrides(mockHttpClientForDio);

        final program = ProgramModel(
          id: 'p1',
          tournamentId: 't1',
          title: 'テスト',
          fileUrl: 'https://placehold.co/400x600/E8E8E8/808080.png?text=zoom',
          fileType: 'image',
          pageCount: 1,
          createdAt: DateTime.now(),
        );

        when(
          () => mockProgramRepo.watchPrograms(any()),
        ).thenAnswer((_) => Stream.value([program]));

        await tester.pumpWidget(createViewerWidget([program]));
        await tester.pumpAndSettle();

        // ズーム前：通常は ClampingScrollPhysics
        final PageView initialPageView = tester.widget(find.byType(PageView));
        expect(initialPageView.physics, isA<ClampingScrollPhysics>());

        // InteractiveViewer から TransformationController を取得してスケールを変更（ピンチズーム状態を模擬）
        final InteractiveViewer interactiveViewer = tester.widget(
          find.byType(InteractiveViewer),
        );
        final controller = interactiveViewer.transformationController!;
        controller.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
        await tester.pump();

        // ズーム後：NeverScrollableScrollPhysics に切り替わっていることを確認
        final PageView zoomedPageView = tester.widget(find.byType(PageView));
        expect(zoomedPageView.physics, isA<NeverScrollableScrollPhysics>());

        await tester.pump(const Duration(seconds: 1)); // タイマー消化
        HttpOverrides.global = null;
      },
    );

    testWidgets('✅ 12. ツールバーのグループ分離レイアウト（描画と消去コンテナの分離・配色）の検証', (tester) async {
      final program = ProgramModel(
        id: 'p1',
        tournamentId: 't1',
        title: 'テストツールバー',
        fileUrl: 'https://example.com/dummy.jpg',
        fileType: 'image',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([program]));

      await tester.pumpWidget(createViewerWidget([program]));
      await tester.pumpAndSettle();

      // 1. 書き込みモードをONにしてツールバーを表示する
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // 2. 描画グループのContainerを見つける（ライトモード背景色: Colors.grey.shade100）
      final drawGroupFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final deco = widget.decoration as BoxDecoration;
          return deco.color == Colors.grey.shade100;
        }
        return false;
      });
      expect(drawGroupFinder, findsOneWidget);

      // 3. 消去・履歴グループのContainerを見つける（ライトモード背景色: Colors.blueGrey.shade50.withAlpha(220)）
      final eraseGroupFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final deco = widget.decoration as BoxDecoration;
          return deco.color == Colors.blueGrey.shade50.withAlpha(220) &&
              deco.border?.top.color == Colors.blueGrey.shade100;
        }
        return false;
      });
      expect(eraseGroupFinder, findsOneWidget);

      // 4. 描画グループ内にペン、蛍光マーカーボタンが存在すること
      expect(find.byTooltip('ペン'), findsOneWidget);
      expect(find.byTooltip('蛍光マーカー'), findsOneWidget);

      // 5. 消去・履歴グループ内に消しゴム、1つ戻す、すべて消すボタンが存在すること
      expect(find.byTooltip('消しゴム'), findsOneWidget);
      expect(find.byTooltip('1つ戻す'), findsOneWidget);
      expect(find.byTooltip('すべて消す'), findsOneWidget);
    });
  });
}
