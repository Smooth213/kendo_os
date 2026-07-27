import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/category_rules_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockTeamRepository extends Mock implements TeamRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('Tournament Setup Flow Navigation Tests', () {
    late MockTournamentRepository mockTournamentRepo;
    late MockTeamRepository mockTeamRepo;
    late MockPlayerRepository mockPlayerRepo;
    late TournamentModel mockTournament;

    setUp(() {
      mockTournamentRepo = MockTournamentRepository();
      mockTeamRepo = MockTeamRepository();
      mockPlayerRepo = MockPlayerRepository();

      mockTournament = TournamentModel(
        id: 'test_tournament_123',
        organizationId: 'test_dojo_id',
        name: 'オンボーディングテスト大会',
        date: DateTime.now(),
        venue: 'テスト会場',
        categories: const ['小学生の部'],
        categoryRules: const {},
      );

      when(
        () => mockTournamentRepo.getTournamentStream(any()),
      ).thenAnswer((_) => Stream.value(mockTournament));
      when(
        () => mockTeamRepo.watchTeamsByTournament(any()),
      ).thenAnswer((_) => Stream.value(<TeamModel>[]));
      when(
        () => mockPlayerRepo.getPlayers(),
      ).thenAnswer((_) => Stream.value(<PlayerModel>[]));
      when(
        () => mockPlayerRepo.watchCustomTeamNames(),
      ).thenAnswer((_) => Stream.value(<String>[]));
    });

    testWidgets(
      '1. TeamRegistrationScreen completed button navigates to CategoryRulesScreen with query param',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final router = GoRouter(
          initialLocation: '/team-registration/test_tournament_123',
          routes: [
            GoRoute(
              path: '/team-registration/:id',
              builder: (context, state) => TeamRegistrationScreen(
                tournamentId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: '/tournament/:id/category-rules',
              builder: (context, state) {
                final isFromSetup =
                    state.uri.queryParameters['isFromSetup'] == 'true';
                return Scaffold(
                  body: Text(
                    'CategoryRules: ${state.pathParameters['id']}, isFromSetup: $isFromSetup',
                  ),
                );
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWithValue(
                mockTournamentRepo,
              ),
              teamRepositoryProvider.overrideWithValue(mockTeamRepo),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // Verify page 0 is rendered (we see "次へ進む" button)
        expect(find.text('次へ進む'), findsOneWidget);
        await tester.tap(find.text('次へ進む'));
        await tester.pumpAndSettle();

        // Page 1 is visible. Enter team name in TextField
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, '修武館A');
        await tester.pumpAndSettle();

        // Tap Next on Page 1 to go to Page 2 Confirm screen
        await tester.tap(find.text('次へ進む'));
        await tester.pumpAndSettle();

        // Verify "登録を完了してルール設定へ" button is now visible on Page 2
        expect(find.text('登録を完了してルール設定へ'), findsOneWidget);

        // Tap completion button
        await tester.tap(find.text('登録を完了してルール設定へ'));
        await tester.pumpAndSettle();

        // Verify it navigated to CategoryRulesScreen with isFromSetup=true
        expect(
          find.text('CategoryRules: test_tournament_123, isFromSetup: true'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2. CategoryRulesScreen renders setup buttons and navigates to home when isFromSetup=true',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final populatedTournament = mockTournament.copyWith(
          categoryRules: {'小学生の部': CategoryRuleSet()},
        );

        final router = GoRouter(
          initialLocation:
              '/tournament/test_tournament_123/category-rules?isFromSetup=true',
          routes: [
            GoRoute(
              path: '/tournament/:id/category-rules',
              builder: (context, state) {
                final isFromSetup =
                    state.uri.queryParameters['isFromSetup'] == 'true';
                return CategoryRulesScreen(
                  tournamentId: state.pathParameters['id']!,
                  isFromSetup: isFromSetup,
                );
              },
            ),
            GoRoute(
              path: '/home/:id',
              builder: (context, state) =>
                  Scaffold(body: Text('Home: ${state.pathParameters['id']}')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWithValue(
                mockTournamentRepo,
              ),
              tournamentProvider(
                'test_tournament_123',
              ).overrideWith((ref) => Stream.value(populatedTournament)),
              matchListByTournamentProvider(
                'test_tournament_123',
              ).overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Check skip button is visible in AppBar
        expect(find.text('スキップ'), findsOneWidget);

        // Check bottom completion button is visible
        expect(find.text('設定を完了して大会ホームへ進む'), findsOneWidget);

        // Tap bottom completion button
        await tester.tap(find.text('設定を完了して大会ホームへ進む'));
        await tester.pumpAndSettle();

        // Verify it redirected to home
        expect(find.text('Home: test_tournament_123'), findsOneWidget);
      },
    );

    testWidgets(
      '3. CategoryRulesScreen skip button navigates to home when isFromSetup=true',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final router = GoRouter(
          initialLocation:
              '/tournament/test_tournament_123/category-rules?isFromSetup=true',
          routes: [
            GoRoute(
              path: '/tournament/:id/category-rules',
              builder: (context, state) {
                final isFromSetup =
                    state.uri.queryParameters['isFromSetup'] == 'true';
                return CategoryRulesScreen(
                  tournamentId: state.pathParameters['id']!,
                  isFromSetup: isFromSetup,
                );
              },
            ),
            GoRoute(
              path: '/home/:id',
              builder: (context, state) =>
                  Scaffold(body: Text('Home: ${state.pathParameters['id']}')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWithValue(
                mockTournamentRepo,
              ),
              tournamentProvider(
                'test_tournament_123',
              ).overrideWith((ref) => Stream.value(mockTournament)),
              matchListByTournamentProvider(
                'test_tournament_123',
              ).overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Tap skip button in AppBar
        await tester.tap(find.text('スキップ'));
        await tester.pumpAndSettle();

        // Verify it redirected to home
        expect(find.text('Home: test_tournament_123'), findsOneWidget);
      },
    );

    testWidgets(
      '4. CategoryRulesScreen does NOT show setup UI elements when isFromSetup=false',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final router = GoRouter(
          initialLocation: '/tournament/test_tournament_123/category-rules',
          routes: [
            GoRoute(
              path: '/tournament/:id/category-rules',
              builder: (context, state) {
                final isFromSetup =
                    state.uri.queryParameters['isFromSetup'] == 'true';
                return CategoryRulesScreen(
                  tournamentId: state.pathParameters['id']!,
                  isFromSetup: isFromSetup,
                );
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWithValue(
                mockTournamentRepo,
              ),
              tournamentProvider(
                'test_tournament_123',
              ).overrideWith((ref) => Stream.value(mockTournament)),
              matchListByTournamentProvider(
                'test_tournament_123',
              ).overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Setup specific UI elements should NOT be rendered
        expect(find.text('スキップ'), findsNothing);
        expect(find.text('設定を完了して大会ホームへ進む'), findsNothing);
      },
    );
  });
}
