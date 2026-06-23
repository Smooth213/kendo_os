import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:kendo_os/main.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/domain/entities/user_session.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/auth_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart'
    as legacy_sync;

import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/start_screen.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockLegacySyncEngine extends Mock implements legacy_sync.SyncEngine {}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class MockAuthSessionNotifier extends AuthSessionNotifier {
  MockAuthSessionNotifier(UserSession? initialSession) {
    state = initialSession;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(<MatchModel>[]);
    registerFallbackValue(
      const MatchModel(id: '', matchType: '', redName: '', whiteName: ''),
    );
  });

  group('🛡️ Viewer Routing Integration Tests', () {
    late MockTournamentRepository mockTournamentRepo;
    late MockPlayerRepository mockPlayerRepo;
    late MockSyncEngine mockSyncEngine;
    late MockLegacySyncEngine mockLegacySyncEngine;
    late MockLocalMatchRepository mockLocalRepo;
    late List<MatchModel> mockMatches;
    late TournamentModel mockTournament;

    setUp(() {
      mockTournamentRepo = MockTournamentRepository();
      mockPlayerRepo = MockPlayerRepository();
      mockSyncEngine = MockSyncEngine();
      mockLegacySyncEngine = MockLegacySyncEngine();
      mockLocalRepo = MockLocalMatchRepository();

      mockMatches = [
        MatchModel(
          id: 'test_match_1',
          tournamentId: 'test_tournament_123',
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
        id: 'test_tournament_123',
        name: '通常戦テスト大会',
        date: DateTime.now(),
        venue: '日本武道館',
        categories: const ['小学生の部'],
        organizationId: 'dojo_123',
      );

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
      when(
        () => mockLocalRepo.getPendingMatches(),
      ).thenAnswer((_) => Future.value(<MatchModel>[]));
      when(
        () => mockLegacySyncEngine.syncNow(),
      ).thenAnswer((_) => Future.value());
    });

    testWidgets('1. 通常大会の観客席ルーティング検証：ViewerHomeScreenのみマウントされること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            legacy_sync.syncEngineProvider.overrideWithValue(
              mockLegacySyncEngine,
            ),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            dojoRoomSyncProvider.overrideWithValue(null),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
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
              (ref) => 'test_tournament_123',
            ),
            matchListProvider.overrideWith((ref) => mockMatches),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(mockMatches),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authSessionProvider.overrideWith(
              (ref) => MockAuthSessionNotifier(
                UserSession(
                  role: UserRole.viewer,
                  loginAt: DateTime.now(),
                  expiresAt: DateTime.now().add(const Duration(hours: 1)),
                ),
              ),
            ),
            firestoreRoleStreamProvider.overrideWith(
              (ref) => Stream.value(UserRole.viewer),
            ),
            matchViewStateUserIdProvider.overrideWith((ref) => 'mock_user_123'),
          ],
          child: const KendoOSApp(),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // GoRouterを取得して /viewer-home/test_tournament_123 へ遷移
      final routerContext = tester.element(find.byType(Navigator).first);
      GoRouter.of(routerContext).go('/viewer-home/test_tournament_123');

      await tester.pump();
      await tester.pumpAndSettle();

      // ViewerHomeScreenがマウントされていることを検証
      expect(find.byType(ViewerHomeScreen), findsOneWidget);
      // HomeScreenがマウントされていないことを検証
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('2. 特設部内戦の観客席ルーティング検証：ViewerBunaiksenHomeScreenのみマウントされること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final bunaiksenDateId = 'bunaiksen_20260619';
      final bunaiksenMatches = [
        MatchModel(
          id: 'bunaiksen_match_1',
          tournamentId: bunaiksenDateId,
          category: '部内戦',
          redName: '観戦太郎',
          whiteName: '観戦二郎',
          matchType: '個人戦',
          status: 'waiting',
          order: 1.0,
          note: '部内稽古',
        ),
      ];

      when(
        () => mockLocalRepo.watchLocalMatches(bunaiksenDateId),
      ).thenAnswer((_) => Stream.value(bunaiksenMatches));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            legacy_sync.syncEngineProvider.overrideWithValue(
              mockLegacySyncEngine,
            ),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            dojoRoomSyncProvider.overrideWithValue(null),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
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
            currentTournamentIdProvider.overrideWith((ref) => bunaiksenDateId),
            matchListProvider.overrideWith((ref) => bunaiksenMatches),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(bunaiksenMatches),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authSessionProvider.overrideWith(
              (ref) => MockAuthSessionNotifier(
                UserSession(
                  role: UserRole.viewer,
                  loginAt: DateTime.now(),
                  expiresAt: DateTime.now().add(const Duration(hours: 1)),
                ),
              ),
            ),
            firestoreRoleStreamProvider.overrideWith(
              (ref) => Stream.value(UserRole.viewer),
            ),
            matchViewStateUserIdProvider.overrideWith((ref) => 'mock_user_123'),
          ],
          child: const KendoOSApp(),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // GoRouterを取得して /bunaiksen-viewer-home/bunaiksen_20260619 へ遷移
      final routerContext = tester.element(find.byType(Navigator).first);
      GoRouter.of(
        routerContext,
      ).go('/bunaiksen-viewer-home/bunaiksen_20260619');

      await tester.pump();
      await tester.pumpAndSettle();

      // ViewerBunaiksenHomeScreenがマウントされていることを検証
      expect(find.byType(ViewerBunaiksenHomeScreen), findsOneWidget);
      // BunaiksenHomeScreenがマウントされていないことを検証
      expect(find.byType(BunaiksenHomeScreen), findsNothing);

      // 試合カードをタップし、クエリパラメータが伝播して /match/:matchId に遷移することを検証
      final cardFinder = find.byKey(
        const Key('viewer_match_card_bunaiksen_match_1'),
      );
      expect(cardFinder, findsOneWidget);
      await tester.tap(cardFinder);
      await tester.pump();
      await tester.pumpAndSettle();

      // ViewerMatchScreenがマウントされていることを検証
      expect(find.byType(ViewerMatchScreen), findsOneWidget);

      // 次のテストへの状態リークを防ぐため、ルーターを初期位置に戻しておく
      GoRouter.of(routerContext).go('/');
      await tester.pumpAndSettle();
    });

    testWidgets('3. 一般観客セッション（PINなし通過）の連動テスト：StartScreenから自動で観客席専用パスへ遷移すること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();
      final yyyy = now.year.toString();
      final mm = now.month.toString().padLeft(2, '0');
      final dd = now.day.toString().padLeft(2, '0');
      final expectedDateId = 'bunaiksen_$yyyy$mm$dd';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            legacy_sync.syncEngineProvider.overrideWithValue(
              mockLegacySyncEngine,
            ),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            dojoRoomSyncProvider.overrideWithValue(null),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
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
            currentTournamentIdProvider.overrideWith((ref) => expectedDateId),
            matchListProvider.overrideWith((ref) => mockMatches),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(mockMatches),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authSessionProvider.overrideWith(
              (ref) => MockAuthSessionNotifier(
                UserSession(
                  role: UserRole.viewer,
                  loginAt: DateTime.now(),
                  expiresAt: DateTime.now().add(const Duration(hours: 1)),
                ),
              ),
            ),
            firestoreRoleStreamProvider.overrideWith(
              (ref) => Stream.value(UserRole.viewer),
            ),
            matchViewStateUserIdProvider.overrideWith((ref) => 'mock_user_123'),
          ],
          child: const KendoOSApp(),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // GoRouterを取得してルート / (StartScreen) へ遷移
      final routerContext = tester.element(find.byType(Navigator).first);
      GoRouter.of(routerContext).go('/');

      await tester.pump();
      await tester.pumpAndSettle();

      // AuthGuardに弾かれずStartScreenが表示されていることを検証
      expect(find.byType(StartScreen), findsOneWidget);

      // 「部内戦をはじめる」ボタンを見つけてタップ
      final startBunaiksenButton = find.text('部内戦をはじめる');
      expect(startBunaiksenButton, findsOneWidget);
      await tester.tap(startBunaiksenButton);

      await tester.pump();
      await tester.pumpAndSettle();

      // ViewerBunaiksenHomeScreenがマウントされていることを検証（観客席専用パスへの正しい遷移）
      expect(find.byType(ViewerBunaiksenHomeScreen), findsOneWidget);
    });
  });
}
