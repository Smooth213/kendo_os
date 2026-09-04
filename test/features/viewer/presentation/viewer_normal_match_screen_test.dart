import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/domain/entities/user_session.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/features/viewer/providers/viewer_view_state_provider.dart';

// SharePlatform の呼び出しを検証するためのフェイククラス
class FakeSharePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements SharePlatform {
  static final FakeSharePlatform instance = FakeSharePlatform();
  String? sharedText;

  @override
  Future<ShareResult> share(ShareParams params) async {
    sharedText = params.text;
    return const ShareResult('success', ShareResultStatus.success);
  }

  void reset() {
    sharedText = null;
  }
}

// AuthSessionNotifier のフェイククラス (SessionStorageへのアクセスを回避)
class FakeAuthSessionNotifier extends AuthSessionNotifier {
  FakeAuthSessionNotifier() : super();

  @override
  Future<void> establishSession(UserRole role, String dojoId) async {
    state = UserSession(
      role: role,
      loginAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 12)),
    );
  }
}

void main() {
  group('🛡️ ViewerNormalMatch 観客席防衛線・通常試合モード自動検証テスト', () {
    late MatchModel testNormalMatch;
    late MatchProjection testProjection;
    late MatchViewState testViewState;
    final String targetTournamentId = 'YwP7EKfZN0OAF7q1FvYo';
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      testNormalMatch = MatchModel(
        id: 'normal_match_001',
        tournamentId: targetTournamentId,
        redName: '道上 次郎',
        whiteName: '対戦相手',
        redScore: 0,
        whiteScore: 0,
        status: 'waiting',
        order: 1,
        matchType: '通常試合',
        events: [],
      );

      testProjection = MatchProjection(
        id: testNormalMatch.id,
        tournamentId: targetTournamentId,
        matchOrder: 1,
        matchType: '通常試合',
        status: 'waiting',
        groupName: '',
        isKachinuki: false,
        redName: '道上 次郎',
        whiteName: '対戦相手',
        redScore: 0,
        whiteScore: 0,
        remainingSeconds: 180,
        timerIsRunning: false,
        note: '',
      );

      testViewState = MatchViewState(
        scoreText: '0 - 0',
        redScore: 0,
        whiteScore: 0,
        isEncho: false,
        winner: null,
        lastEventText: '',
        canUndo: false,
        statusText: '待機中',
        syncStatus: SyncStatus.synced,
        isViewOnly: true,
        isInputLocked: true,
        isAllDone: false,
        isTie: false,
        redCleanName: '道上 次郎',
        whiteCleanName: '対戦相手',
      );

      FakeSharePlatform.instance.reset();
      SharePlatform.instance = FakeSharePlatform.instance;
    });

    // 共通のテスト環境構築ヘルパー
    Widget createTestWidget({
      required GoRouter router,
      required List<Override> overrides,
    }) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authSessionProvider.overrideWith((ref) => FakeAuthSessionNotifier()),
          customTeamNamesProvider.overrideWith(
            (ref) => Stream.value(<String>[]),
          ),
          matchListProvider.overrideWithValue([testNormalMatch]),
          ...overrides,
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('①-a 【詳細画面：QR直接アクセス時】スタックが無い状態では、物理的に戻るボタンが非表示（null）になること', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation:
            '/viewer-match/normal_match_001?tournamentId=$targetTournamentId',
        routes: [
          GoRoute(
            path: '/viewer-match/:matchId',
            builder: (context, state) =>
                ViewerMatchScreen(matchId: state.pathParameters['matchId']!),
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          router: router,
          overrides: [
            matchListByTournamentProvider(
              targetTournamentId,
            ).overrideWith((ref) => Stream.value([testNormalMatch])),
            webCurrentTournamentIdProvider.overrideWith(
              (ref) => targetTournamentId,
            ),
            currentDojoIdProvider.overrideWith((ref) => 'test201'),
            viewerMatchProjectionProvider(
              'normal_match_001',
            ).overrideWith((ref) => Stream.value(testProjection)),
            matchViewStateProvider(
              'normal_match_001',
            ).overrideWithValue(testViewState),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 🛡️ アサート: canPopがfalseの時は、AppBarのleading（戻るボタンのアイコン）が存在しないこと
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    });

    testWidgets('①-b 【詳細画面：アプリ内遷移時】スタックが存在する状態では、戻るボタンが正常に表示されること', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: SizedBox()),
          ),
          GoRoute(
            path: '/viewer-match/:matchId',
            builder: (context, state) =>
                ViewerMatchScreen(matchId: state.pathParameters['matchId']!),
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          router: router,
          overrides: [
            matchListByTournamentProvider(
              targetTournamentId,
            ).overrideWith((ref) => Stream.value([testNormalMatch])),
            webCurrentTournamentIdProvider.overrideWith(
              (ref) => targetTournamentId,
            ),
            currentDojoIdProvider.overrideWith((ref) => 'test201'),
            viewerMatchProjectionProvider(
              'normal_match_001',
            ).overrideWith((ref) => Stream.value(testProjection)),
            matchViewStateProvider(
              'normal_match_001',
            ).overrideWithValue(testViewState),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 画面を遷移させる
      router.push(
        '/viewer-match/normal_match_001?tournamentId=$targetTournamentId',
      );
      await tester.pumpAndSettle();

      // 🛡️ アサート: canPopがtrueの時は、戻るボタンのアイコンが物理的に存在すること
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('②-a 【ホーム画面：QRコードURL検証】ホーム画面の共有ボタンから正しいベータ環境URLが生成されること', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/viewer-home/$targetTournamentId',
        routes: [
          GoRoute(
            path: '/viewer-home/:tournamentId',
            builder: (context, state) => ViewerHomeScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          router: router,
          overrides: [
            matchListByTournamentProvider(
              targetTournamentId,
            ).overrideWith((ref) => Stream.value([testNormalMatch])),
            currentDojoIdProvider.overrideWith((ref) => 'test201'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // ヘッダーのQR共有ボタンを直接タップして共有ダイアログを開く
      final qrButton = find.byIcon(Icons.qr_code_2);
      expect(qrButton, findsOneWidget);
      await tester.tap(qrButton);
      await tester.pumpAndSettle();

      // QrImageViewがダイアログ内に存在すること
      final qrFinder = find.byType(QrImageView);
      expect(qrFinder, findsOneWidget);

      // LINEやSNSでURLを送る ボタンをタップして共有をトリガーし、テキストを検証
      final sendButton = find.text('LINEやSNSでURLを送る');
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      expect(FakeSharePlatform.instance.sharedText, isNotNull);
      expect(
        FakeSharePlatform.instance.sharedText,
        contains('https://kendo-os-beta.web.app/viewer-home'),
      );
      expect(FakeSharePlatform.instance.sharedText, contains('dojoId=test201'));
    });

    testWidgets('②-b 【詳細画面：QRコードURL検証】詳細画面の共有ボタンから正しいベータ環境URLが生成されること', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation:
            '/viewer-match/normal_match_001?tournamentId=$targetTournamentId',
        routes: [
          GoRoute(
            path: '/viewer-match/:matchId',
            builder: (context, state) =>
                ViewerMatchScreen(matchId: state.pathParameters['matchId']!),
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          router: router,
          overrides: [
            matchListByTournamentProvider(
              targetTournamentId,
            ).overrideWith((ref) => Stream.value([testNormalMatch])),
            webCurrentTournamentIdProvider.overrideWith(
              (ref) => targetTournamentId,
            ),
            currentDojoIdProvider.overrideWith((ref) => 'test201'),
            viewerMatchProjectionProvider(
              'normal_match_001',
            ).overrideWith((ref) => Stream.value(testProjection)),
            matchViewStateProvider(
              'normal_match_001',
            ).overrideWithValue(testViewState),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 右上のQRコード共有ボタン（Icons.qr_code_2）をタップ
      final shareButton = find.byIcon(Icons.qr_code_2);
      expect(shareButton, findsOneWidget);
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      // QrImageViewがダイアログ内に存在すること
      final qrFinder = find.byType(QrImageView);
      expect(qrFinder, findsOneWidget);

      // LINEやSNSでURLを送る ボタンをタップして共有をトリガーし、テキストを検証
      final sendButton = find.text('LINEやSNSでURLを送る');
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      expect(FakeSharePlatform.instance.sharedText, isNotNull);
      expect(
        FakeSharePlatform.instance.sharedText,
        contains('https://kendo-os-beta.web.app/viewer-home'),
      );
      expect(FakeSharePlatform.instance.sharedText, contains('dojoId=test201'));
    });

    testWidgets('③ 【詳細画面：正常描画】注入された通常試合データが一本速報スコアボードに美しく反映されること', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation:
            '/viewer-match/normal_match_001?tournamentId=$targetTournamentId',
        routes: [
          GoRoute(
            path: '/viewer-match/:matchId',
            builder: (context, state) =>
                ViewerMatchScreen(matchId: state.pathParameters['matchId']!),
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          router: router,
          overrides: [
            matchListByTournamentProvider(
              targetTournamentId,
            ).overrideWith((ref) => Stream.value([testNormalMatch])),
            webCurrentTournamentIdProvider.overrideWith(
              (ref) => targetTournamentId,
            ),
            currentDojoIdProvider.overrideWith((ref) => 'test201'),
            viewerMatchProjectionProvider(
              'normal_match_001',
            ).overrideWith((ref) => Stream.value(testProjection)),
            matchViewStateProvider(
              'normal_match_001',
            ).overrideWithValue(testViewState),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 🛡️ アサート: 詳細画面の核心的UI要素（タイトル、閲覧モードバナー、選手名）がエラーなく描画されていること
      expect(find.text('試合状況 (観戦)'), findsOneWidget);
      expect(find.text('閲覧モード'), findsOneWidget);
      expect(find.text('道上 次郎'), findsOneWidget);
      expect(find.text('対戦相手'), findsOneWidget);
    });
  });
}
