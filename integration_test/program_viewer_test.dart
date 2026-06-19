import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_stroke_repository.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

// Mockの定義
class MockStrokeRepository extends Mock implements StrokeRepository {}

class MockLocalStrokeRepository extends Mock implements LocalStrokeRepository {}

final mockHttpClient = MockClient((request) async {
  return http.Response(
    '%PDF-1.4\n%EOF',
    200,
    headers: {'content-type': 'application/pdf'},
  );
});

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockStrokeRepository mockStrokeRepository;
  late MockLocalStrokeRepository mockLocalStrokeRepository;
  FlutterExceptionHandler? originalOnError;
  ErrorCallback? originalPlatformOnError;
  late MockHttpClient mockHttpClientForDio;
  late MockHttpClientRequest mockHttpClientRequest;
  late MockHttpClientResponse mockHttpClientResponse;
  late MockHttpHeaders mockHttpHeaders;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(Stream<List<int>>.empty());
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  setUp(() {
    mockStrokeRepository = MockStrokeRepository();
    mockLocalStrokeRepository = MockLocalStrokeRepository();

    mockHttpHeaders = MockHttpHeaders();
    mockHttpClientResponse = MockHttpClientResponse(mockHttpHeaders);
    mockHttpClientRequest = MockHttpClientRequest(mockHttpClientResponse);
    mockHttpClientForDio = MockHttpClient();

    // HttpOverridesを設定
    HttpOverrides.global = MockHttpOverrides(mockHttpClientForDio);

    // HttpClient のスタブ設定
    when(
      () => mockHttpClientForDio.getUrl(any()),
    ).thenAnswer((_) async => mockHttpClientRequest);
    when(
      () => mockHttpClientForDio.openUrl(any(), any()),
    ).thenAnswer((_) async => mockHttpClientRequest);

    // HttpClientRequest のスタブ設定
    when(() => mockHttpClientRequest.headers).thenReturn(mockHttpHeaders);

    // リポジトリメソッドのデフォルトスタブ
    when(
      () => mockStrokeRepository.watchStrokes(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockLocalStrokeRepository.watchStrokes(any()),
    ).thenAnswer((_) => Stream.value([]));

    // エラーハンドラーの退避
    originalOnError = FlutterError.onError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;

    // テスト用のダミー通信エラー（ClientException/404/Connection Refusedなど）を無視するグローバルハンドラー
    FlutterError.onError = (FlutterErrorDetails details) {
      final errorStr = details.exception.toString();
      if (errorStr.contains('ClientException') ||
          errorStr.contains('404') ||
          errorStr.contains('Connection refused') ||
          errorStr.contains('NetworkImage') ||
          errorStr.contains('Failed host lookup')) {
        debugPrint(
          '🛡️ [Test Sandbox] Ignored expected network exception: $errorStr',
        );
        return; // 無視して終了
      }
      originalOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      final errorStr = error.toString();
      if (errorStr.contains('ClientException') ||
          errorStr.contains('404') ||
          errorStr.contains('Connection refused') ||
          errorStr.contains('NetworkImage') ||
          errorStr.contains('Failed host lookup')) {
        debugPrint(
          '🛡️ [Test Sandbox] Ignored expected platform network error: $errorStr',
        );
        return true; // 例外をキャッチしたとみなしてフレームワークに伝播させない
      }
      return originalPlatformOnError?.call(error, stack) ?? false;
    };
  });

  tearDown(() {
    // 元のエラーハンドラーへ復元
    FlutterError.onError = originalOnError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;
    // クリーンアップ
    HttpOverrides.global = null;
  });

  testWidgets('シナリオA: 画像ファイルの表示担保', (tester) async {
    await http.runWithClient(() async {
      final imageProgram = ProgramModel(
        id: 'img_test_01',
        tournamentId: 'tour_01',
        title: 'テストパンフレット (画像)',
        fileUrl: 'https://placehold.co/400x600.png',
        fileType: 'jpg',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      // SharedPreferencesのモック初期化
      SharedPreferences.setMockInitialValues({});
      final sharedPrefs = await SharedPreferences.getInstance();

      // テスト対象の画面をマウント
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPrefs),
            strokeRepositoryProvider.overrideWithValue(mockStrokeRepository),
            localStrokeRepositoryProvider.overrideWithValue(
              mockLocalStrokeRepository,
            ),
            activeRoleProvider.overrideWithValue(Role.admin),
            permissionProvider.overrideWithValue(
              const PermissionState(isReadOnly: false),
            ),
            viewerProgramListProvider(
              'tour_01',
            ).overrideWith((ref) => Stream.value([imageProgram])),
          ],
          child: MaterialApp(
            home: ProgramViewerScreen(
              programs: [imageProgram],
              initialIndex: 0,
            ),
          ),
        ),
      );

      // 読み込みトランジションの解決を待機
      await tester.pumpAndSettle();

      // 描画キャンバスとズームコンテナが正しく構築されていること
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(FittedBox), findsOneWidget);

      // キャッシュサイズ取得処理（タイムアウト3秒）の進行をシミュレート
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Imageウィジェットが描画されていることをアサート
      expect(find.byType(Image), findsOneWidget);

      // テスト終了前にWidgetツリーを空にして非同期通信を強制キャンセル
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }, () => mockHttpClient);
  });

  testWidgets('シナリオB: PDFファイルの表示担保と環境分岐の検証', (tester) async {
    await http.runWithClient(() async {
      final pdfProgram = ProgramModel(
        id: 'pdf_test_01',
        tournamentId: 'tour_01',
        title: 'テストパンフレット (PDF)',
        fileUrl: 'https://example.com/test_program.pdf',
        fileType: 'pdf',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      // SharedPreferencesのモック初期化
      SharedPreferences.setMockInitialValues({});
      final sharedPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPrefs),
            strokeRepositoryProvider.overrideWithValue(mockStrokeRepository),
            localStrokeRepositoryProvider.overrideWithValue(
              mockLocalStrokeRepository,
            ),
            activeRoleProvider.overrideWithValue(Role.admin),
            permissionProvider.overrideWithValue(
              const PermissionState(isReadOnly: false),
            ),
            viewerProgramListProvider(
              'tour_01',
            ).overrideWith((ref) => Stream.value([pdfProgram])),
          ],
          child: MaterialApp(
            home: ProgramViewerScreen(programs: [pdfProgram], initialIndex: 0),
          ),
        ),
      );

      // ★ 物理調停パッチのテスト用バイパス:
      // Web環境下 (kIsWeb) では Firebase Storage SDK のgetDataメソッドが実行され
      // 初期化されていないFirebaseへアクセスしようとしてクラッシュします。
      // これを完全に防ぐため、マウントしたStateオブジェクトのメモリキャッシュへ直接
      // テスト用の有効なダミーPDF（%PDFシグネチャ付き）を注入し、外部通信を完全に遮断します。
      if (kIsWeb) {
        final state = tester.state(find.byType(ProgramViewerScreen)) as dynamic;
        final dummyPdfBytes = Uint8List.fromList(
          utf8.encode('%PDF-1.4\n%...\n%%EOF'),
        );
        state._sdkPdfBytesCache[pdfProgram.fileUrl] = Future.value(
          dummyPdfBytes,
        );
      }

      // 状態を同期して再構築を待機
      await tester.pumpAndSettle();

      // コアレイアウトコンテキストが構築されていること
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(FittedBox), findsOneWidget);

      // 環境に応じた PDF ビューアの分岐検証
      if (kIsWeb) {
        // Web環境では 一括フェッチされた byte より SfPdfViewer.memory がマウントされること
        expect(find.byType(SfPdfViewer), findsOneWidget);
        expect(find.textContaining('PDFロード失敗'), findsNothing);
      } else {
        // ネイティブ環境では SfPdfViewer.network が直接マウントされること
        expect(find.byType(SfPdfViewer), findsOneWidget);
      }

      // テスト終了前にWidgetツリーを空にして非同期通信を強制キャンセル
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }, () => mockHttpClient);
  });
}

// ==========================================
// ★ HttpOverrides による dart:io HttpClient の完全モック化
// ==========================================

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
