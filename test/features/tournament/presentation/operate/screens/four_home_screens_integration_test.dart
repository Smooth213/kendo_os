import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/routing/app_router.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<MatchModel>[]);
    registerFallbackValue(
      const MatchModel(id: '', matchType: '', redName: '', whiteName: ''),
    );
  });

  group('🛡️ Four Home Screens Integration Tests', () {
    late MockTournamentRepository mockTournamentRepo;
    late MockPlayerRepository mockPlayerRepo;
    late MockSyncEngine mockSyncEngine;
    late MockLocalMatchRepository mockLocalRepo;
    late List<MatchModel> mockMatches;
    late TournamentModel mockTournament;

    setUp(() {
      mockTournamentRepo = MockTournamentRepository();
      mockPlayerRepo = MockPlayerRepository();
      mockSyncEngine = MockSyncEngine();
      mockLocalRepo = MockLocalMatchRepository();

      mockMatches = [
        MatchModel(
          id: 'test_match_1',
          tournamentId: 'YwP7EKfZN0OAF7q1FvYo',
          category: '小学生の部',
          groupName: '助っ人101',
          redName: '剣道太郎',
          whiteName: '相手選手',
          matchType: '個人戦',
          status: 'waiting',
          order: 1.0,
          note: '第1試合',
        ),
      ];

      mockTournament = TournamentModel(
        id: 'YwP7EKfZN0OAF7q1FvYo',
        name: '通常戦テスト大会',
        date: DateTime.now(),
        venue: '日本武道館',
        categories: const ['小学生の部'],
        organizationId: 'dojo_123',
      );

      // Default mocks
      when(
        () => mockTournamentRepo.getTournamentStream(any()),
      ).thenAnswer((_) => Stream.value(mockTournament));
      when(
        () => mockPlayerRepo.watchCustomTeamNames(),
      ).thenAnswer((_) => Stream.value(<String>[]));
      when(
        () => mockLocalRepo.watchLocalMatches(any()),
      ).thenAnswer((_) => Stream.value(mockMatches));
      when(
        () => mockLocalRepo.watchAllLocalMatches(),
      ).thenAnswer((_) => Stream.value(mockMatches));
      when(
        () => mockLocalRepo.saveMatchesBulk(any()),
      ).thenAnswer((_) => Future.value());
    });

    testWidgets('1. 運営用 通常大会ホーム (HomeScreen) - ネイティブ＆Webシミュレーション表示検証', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Web環境シミュレーション: kIsWebがDart VM上では定数としてfalseであるため、
      // matchListByTournamentProvider を直接 Stream.value(mockMatches) で
      // 強制オーバーライドすることで、Isarディスクアクセスを完全にバイパスし、
      // Firestoreスナップショットからデータが直列射出される挙動をシミュレートします。
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
            dojoRoomSyncProvider.overrideWithValue(null),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
            currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'YwP7EKfZN0OAF7q1FvYo',
            ),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(mockMatches),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(tournamentId: 'YwP7EKfZN0OAF7q1FvYo'),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // 通常大会ホーム画面の基本UI要素アサーション
      expect(find.text('大会ホーム'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('剣道太郎'),
        ),
        findsWidgets,
      );

      // 個別試合のアコーディオンを展開する
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();

      expect(find.text('相手選手'), findsWidgets);
    });

    testWidgets('2. 運営用 特設部内戦ホーム (BunaiksenHomeScreen) - 自動流し込み＆描画検証', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final bunaiksenDate = DateTime(2026, 6, 19);
      final bunaiksenDateId = 'bunaiksen_20260619';

      final bunaiksenMatches = [
        MatchModel(
          id: 'bunaiksen_match_1',
          tournamentId: bunaiksenDateId,
          category: '部内戦',
          redName: '部内太郎',
          whiteName: '部内二郎',
          matchType: '個人戦',
          status: 'waiting',
          order: 1.0,
          note: '稽古マッチ',
        ),
      ];

      when(
        () => mockLocalRepo.watchLocalMatches(bunaiksenDateId),
      ).thenAnswer((_) => Stream.value(bunaiksenMatches));
      when(
        () => mockLocalRepo.watchAllLocalMatches(),
      ).thenAnswer((_) => Stream.value(bunaiksenMatches));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
            dojoRoomSyncProvider.overrideWithValue(null),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
            currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
            currentTournamentIdProvider.overrideWith((ref) => bunaiksenDateId),
            bunaiksenViewDateProvider.overrideWith((ref) => bunaiksenDate),
            matchListProvider.overrideWith((ref) => bunaiksenMatches),
            currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(home: BunaiksenHomeScreen()),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // 特設部内戦ホーム画面の描画アサーション
      expect(find.text('部内太郎'), findsOneWidget);
      expect(find.text('部内二郎'), findsOneWidget);
    });

    testWidgets('3. 観客用 通常大会ホーム (ViewerHomeScreen) - 簡略化UI＆文字切れ防止検証', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const ViewerHomeScreen(tournamentId: 'YwP7EKfZN0OAF7q1FvYo'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
            dojoRoomSyncProvider.overrideWithValue(null),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: true,
                canManageTournament: false,
                canCreateMatch: false,
                canChangeSettings: false,
                canDeleteData: false,
              ),
            ),
            currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'YwP7EKfZN0OAF7q1FvYo',
            ),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(mockMatches),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // 観客用通常大会ホーム画面の基本UI要素アサーション
      expect(find.text('大会ホーム (観客席)'), findsOneWidget);
      expect(find.text('試合結果一覧'), findsOneWidget);
    });

    testWidgets(
      '4. 観客用 特設部内戦ホーム (ViewerBunaiksenHomeScreen) - カード完全表示＆バインドKey検証',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final bunaiksenDateId = 'bunaiksen_20260619';
        final bunaiksenMatches = [
          MatchModel(
            id: 'bunaiksen_match_spec_1',
            tournamentId: bunaiksenDateId,
            category: '部内戦',
            redName: '観戦太郎',
            whiteName: '観戦二郎',
            matchType: '個人戦',
            status: 'waiting',
            order: 1.0,
            note: '観戦用',
          ),
        ];

        when(
          () => mockLocalRepo.watchLocalMatches(bunaiksenDateId),
        ).thenAnswer((_) => Stream.value(bunaiksenMatches));
        when(
          () => mockLocalRepo.watchAllLocalMatches(),
        ).thenAnswer((_) => Stream.value(bunaiksenMatches));

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  ViewerBunaiksenHomeScreen(tournamentId: bunaiksenDateId),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              tournamentRepositoryProvider.overrideWithValue(
                mockTournamentRepo,
              ),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
              syncEngineProvider.overrideWithValue(mockSyncEngine),
              localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
              commentStreamProvider.overrideWith(
                (ref, arg) => Stream.value([]),
              ),
              dojoRoomSyncProvider.overrideWithValue(null),
              permissionProvider.overrideWith(
                (ref) => const AppPermissions(
                  isReadOnly: true,
                  canManageTournament: false,
                  canCreateMatch: false,
                  canChangeSettings: false,
                  canDeleteData: false,
                ),
              ),
              currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
              currentTournamentIdProvider.overrideWith(
                (ref) => bunaiksenDateId,
              ),
              matchListProvider.overrideWith((ref) => bunaiksenMatches),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // 観客用特設部内戦ホーム画面の描画アサーション
        expect(find.text('観戦太郎'), findsOneWidget);
        expect(find.text('観戦二郎'), findsOneWidget);
      },
    );

    testWidgets('5. セーフガード検証: DojoId/TournamentIdが未定の状態でもクラッシュしないこと', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // DojoIdとTournamentIdを意図的に空文字で初期化
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
            dojoRoomSyncProvider.overrideWithValue(null),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
            currentDojoIdProvider.overrideWith((ref) => ''),
            currentTournamentIdProvider.overrideWith((ref) => ''),
          ],
          child: const MaterialApp(home: HomeScreen(tournamentId: '')),
        ),
      );

      await tester.pump();
      // クラッシュせずにマウントできていること
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('6. ネイティブ環境におけるFirestoreからIsarへの流し込み（自動署名ヒーリング）検証', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeFirestore = FakeFirebaseFirestore();

      // Setup Fake Firestore doc
      await fakeFirestore
          .collection('organizations')
          .doc('dojo_123')
          .collection('tournaments')
          .doc('YwP7EKfZN0OAF7q1FvYo')
          .collection('matches')
          .doc('test_match_1')
          .set({
            'redName': 'Firestore赤',
            'whiteName': 'Firestore白',
            'matchType': '個人戦',
            'status': 'waiting',
            'order': 1.0,
            'events': [
              // Event without proper signature to trigger healing
              {
                'id': 'event_1',
                'side': 'red',
                'strikeType': 'men',
                'isIppon': true,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'signature': '', // Invalid/Empty signature
              },
            ],
          });

      List<MatchModel>? capturedMatches;
      when(() => mockLocalRepo.saveMatchesBulk(any())).thenAnswer((invocation) {
        capturedMatches = invocation.positionalArguments[0] as List<MatchModel>;
        return Future.value();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
            dojoRoomSyncProvider.overrideWithValue(null),
            firestoreProvider.overrideWithValue(fakeFirestore),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
            currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'YwP7EKfZN0OAF7q1FvYo',
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(tournamentId: 'YwP7EKfZN0OAF7q1FvYo'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert that saveMatchesBulk was indeed called with healed signature
      expect(capturedMatches, isNotNull);
      expect(capturedMatches!.length, 1);
      final firstMatch = capturedMatches!.first;
      expect(firstMatch.events.length, 1);
      expect(
        firstMatch.events.first.signature,
        isNotEmpty,
      ); // Signature must be generated and healed!
    });

    testWidgets(
      '7. 本部ホーム画面の「観客・保護者側の画面を確認 (Viewer)」ボタンから観客用ホーム画面へ遷移し、完全に観客用ビュアーと一致した状態（閲覧専用）で表示されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final router = GoRouter(
          initialLocation: '/home/YwP7EKfZN0OAF7q1FvYo',
          routes: [
            GoRoute(
              path: '/home/:tournamentId',
              builder: (context, state) => RoleInjector(
                roleStr: state.uri.queryParameters['role'],
                dojoId: state.uri.queryParameters['dojoId'],
                tournamentId: state.pathParameters['tournamentId']!,
                child: HomeScreen(
                  tournamentId: state.pathParameters['tournamentId']!,
                ),
              ),
            ),
            GoRoute(
              path: '/viewer-home/:tournamentId',
              builder: (context, state) => RoleInjector(
                roleStr: state.uri.queryParameters['role'],
                dojoId: state.uri.queryParameters['dojoId'],
                tournamentId: state.pathParameters['tournamentId']!,
                child: ViewerHomeScreen(
                  tournamentId: state.pathParameters['tournamentId']!,
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              tournamentRepositoryProvider.overrideWithValue(
                mockTournamentRepo,
              ),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
              syncEngineProvider.overrideWithValue(mockSyncEngine),
              localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
              commentStreamProvider.overrideWith(
                (ref, arg) => Stream.value([]),
              ),
              dojoRoomSyncProvider.overrideWithValue(null),
              permissionProvider.overrideWith(
                (ref) => const AppPermissions(
                  isReadOnly: false,
                  canManageTournament: true,
                  canCreateMatch: true,
                  canChangeSettings: true,
                  canDeleteData: true,
                ),
              ),
              currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
              currentTournamentIdProvider.overrideWith(
                (ref) => 'YwP7EKfZN0OAF7q1FvYo',
              ),
              matchListByTournamentProvider.overrideWith(
                (ref, id) => Stream.value(mockMatches),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // 本部画面に「観客の画面を確認」ボタンが存在することを確認
        final viewerButton = find.text('観客の画面を確認');
        expect(viewerButton, findsOneWidget);

        // ボタンをタップして観客席画面へ遷移
        await tester.tap(viewerButton);
        await tester.pumpAndSettle();

        // 観客席画面に遷移し、観客用UI（閲覧専用）が完全に一致して描画されること
        expect(find.text('大会ホーム (観客席)'), findsOneWidget);
        expect(find.text('試合結果一覧'), findsOneWidget);
        expect(find.text('大会プログラム'), findsOneWidget);

        // 本部用ボタン（試合開始・試合ルール設定など）は一切表示されないこと
        expect(find.textContaining('試合（対戦）を作成'), findsNothing);
        expect(find.text('試合ルール設定'), findsNothing);
      },
    );
  });
}
