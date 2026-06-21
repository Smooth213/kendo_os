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
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/auth_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart'
    as legacy_sync;

import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:kendo_os/features/tournament/presentation/operate/screens/start_screen.dart';

class MockUser extends Mock implements firebase_auth.User {}

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

  group('🛡️ Staff Bunaiksen Routing Tests', () {
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
          tournamentId: 'bunaiksen_20260620',
          category: '部内戦',
          redName: '剣道太郎',
          whiteName: '相手選手',
          matchType: '個人戦',
          status: 'waiting',
          order: 1.0,
          note: '第1試合',
        ),
      ];

      mockTournament = TournamentModel(
        id: 'bunaiksen_20260620',
        name: '特設部内戦',
        date: DateTime.now(),
        venue: '道場',
        categories: const ['部内戦'],
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

    testWidgets(
      '1. スタッフ権限（UserRole.admin）での部内戦遷移検証：BunaiksenHomeScreenへ遷移し試合作成ボタンが活性化していること',
      (WidgetTester tester) async {
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
              tournamentRepositoryProvider.overrideWithValue(
                mockTournamentRepo,
              ),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
              syncEngineProvider.overrideWithValue(mockSyncEngine),
              legacy_sync.syncEngineProvider.overrideWithValue(
                mockLegacySyncEngine,
              ),
              localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
              dojoRoomSyncProvider.overrideWithValue(null),
              commentStreamProvider.overrideWith(
                (ref, arg) => Stream.value([]),
              ),
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
              currentTournamentIdProvider.overrideWith((ref) => expectedDateId),
              matchListProvider.overrideWith((ref) => mockMatches),
              matchListByTournamentProvider.overrideWith(
                (ref, id) => Stream.value(mockMatches),
              ),
              authStateProvider.overrideWith((ref) => Stream.value(MockUser())),
              currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
              authSessionProvider.overrideWith(
                (ref) => MockAuthSessionNotifier(
                  UserSession(
                    role: UserRole.admin, // ★ スタッフ権限（Admin）
                    loginAt: DateTime.now(),
                    expiresAt: DateTime.now().add(const Duration(hours: 1)),
                  ),
                ),
              ),
              firestoreRoleStreamProvider.overrideWith(
                (ref) => Stream.value(UserRole.admin),
              ),
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

        // StartScreenが表示されていることを検証
        expect(find.byType(StartScreen), findsOneWidget);

        // 「部内戦をはじめる」ボタンを見つけてタップ
        final startBunaiksenButton = find.text('部内戦をはじめる');
        expect(startBunaiksenButton, findsOneWidget);
        await tester.tap(startBunaiksenButton);

        await tester.pump();
        await tester.pumpAndSettle();

        // 運営用の BunaiksenHomeScreen がマウントされていることを検証
        expect(find.byType(BunaiksenHomeScreen), findsOneWidget);
        expect(find.byType(ViewerBunaiksenHomeScreen), findsNothing);

        // 試合作成ボタン（FloatingActionButton）が活性化していて表示されていることを検証
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        final fabWidget = tester.widget<FloatingActionButton>(fabFinder);
        expect(fabWidget.onPressed, isNotNull); // 活性化していること
      },
    );
  });
}
