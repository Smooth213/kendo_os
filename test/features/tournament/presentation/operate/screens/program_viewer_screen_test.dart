import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
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
  });
}
