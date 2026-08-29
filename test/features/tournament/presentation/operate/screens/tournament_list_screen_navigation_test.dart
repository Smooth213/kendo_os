import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/tournament/presentation/operate/screens/tournament_list_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  group('🛡️ TournamentListScreen Navigation Tests', () {
    late MockTournamentRepository mockTournamentRepo;
    late MockSyncEngine mockSyncEngine;

    setUp(() {
      mockTournamentRepo = MockTournamentRepository();
      mockSyncEngine = MockSyncEngine();
    });

    testWidgets(
      '✅ isReadOnlyがtrue（一般観客席）の場合、大会タップで確実に /viewer-home/:id に遷移すること',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final mockTournaments = [
          TournamentModel(
            id: 'test_tournament_1',
            name: 'テスト大会',
            date: DateTime.now(),
            venue: 'テスト会場',
            categories: const [],
            organizationId: 'default_org',
          ),
        ];

        when(
          () => mockTournamentRepo.watchTournaments(),
        ).thenAnswer((_) => Stream.value(mockTournaments));

        final router = GoRouter(
          initialLocation: '/tournament-list',
          routes: [
            GoRoute(
              path: '/tournament-list',
              builder: (context, state) =>
                  const TournamentListScreen(isArchive: false),
            ),
            GoRoute(
              path: '/viewer-home/:id',
              builder: (context, state) =>
                  Text('ViewerHome: ${state.pathParameters['id']}'),
            ),
            GoRoute(
              path: '/home/:id',
              builder: (context, state) =>
                  Text('AdminHome: ${state.pathParameters['id']}'),
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
              syncEngineProvider.overrideWithValue(mockSyncEngine),
              permissionProvider.overrideWith(
                (ref) => const AppPermissions(
                  isReadOnly: true, // ★ 一般観客席の権限
                  canManageTournament: false,
                  canCreateMatch: false,
                  canChangeSettings: false,
                  canDeleteData: false,
                ),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // 大会名が表示されていることを確認
        expect(find.text('テスト大会'), findsOneWidget);

        // 大会カードをタップ
        await tester.tap(find.text('テスト大会'));
        await tester.pumpAndSettle();

        // 遷移先が ViewerHome であることを確認
        expect(find.text('ViewerHome: test_tournament_1'), findsOneWidget);
        expect(find.text('AdminHome: test_tournament_1'), findsNothing);
      },
    );

    testWidgets('✅ isReadOnlyがfalse（運営・記録者）の場合、大会タップで確実に /home/:id に遷移すること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockTournaments = [
        TournamentModel(
          id: 'test_tournament_2',
          name: 'テスト大会2',
          date: DateTime.now(),
          venue: 'テスト会場2',
          categories: const [],
          organizationId: 'default_org',
        ),
      ];

      when(
        () => mockTournamentRepo.watchTournaments(),
      ).thenAnswer((_) => Stream.value(mockTournaments));

      final router = GoRouter(
        initialLocation: '/tournament-list',
        routes: [
          GoRoute(
            path: '/tournament-list',
            builder: (context, state) =>
                const TournamentListScreen(isArchive: false),
          ),
          GoRoute(
            path: '/viewer-home/:id',
            builder: (context, state) =>
                Text('ViewerHome: ${state.pathParameters['id']}'),
          ),
          GoRoute(
            path: '/home/:id',
            builder: (context, state) =>
                Text('AdminHome: ${state.pathParameters['id']}'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false, // ★ 運営・記録者の権限
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // 大会名が表示されていることを確認
      expect(find.text('テスト大会2'), findsOneWidget);

      // 大会カードをタップ
      await tester.tap(find.text('テスト大会2'));
      await tester.pumpAndSettle();

      // 遷移先が AdminHome であることを確認
      expect(find.text('AdminHome: test_tournament_2'), findsOneWidget);
      expect(find.text('ViewerHome: test_tournament_2'), findsNothing);
    });

    testWidgets(
      '✅ isArchiveがtrueの場合、archivedTournamentsProviderから高速取得・描画されること',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final mockArchivedTournaments = [
          TournamentModel(
            id: 'test_archived_1',
            name: '過去の第10回大会',
            date: DateTime(2025, 5, 10),
            venue: '武道館',
            categories: const [],
            organizationId: 'default_org',
          ),
        ];

        when(
          () => mockTournamentRepo.getArchivedTournaments(),
        ).thenAnswer((_) async => mockArchivedTournaments);

        final router = GoRouter(
          initialLocation: '/tournament-list-archive',
          routes: [
            GoRoute(
              path: '/tournament-list-archive',
              builder: (context, state) =>
                  const TournamentListScreen(isArchive: true),
            ),
            GoRoute(
              path: '/home/:id',
              builder: (context, state) =>
                  Text('AdminHome: ${state.pathParameters['id']}'),
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
              syncEngineProvider.overrideWithValue(mockSyncEngine),
              permissionProvider.overrideWith(
                (ref) => const AppPermissions(
                  isReadOnly: false,
                  canManageTournament: true,
                  canCreateMatch: true,
                  canChangeSettings: true,
                  canDeleteData: true,
                ),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // 過去の大会名が表示されていることを確認
        expect(find.text('過去の第10回大会'), findsOneWidget);

        // 大会カードをタップ
        await tester.tap(find.text('過去の第10回大会'));
        await tester.pumpAndSettle();

        // 遷移先が AdminHome であることを確認
        expect(find.text('AdminHome: test_archived_1'), findsOneWidget);
      },
    );
  });
}
