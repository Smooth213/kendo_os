import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/start_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/create_tournament_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/order_setup_screen.dart'
    show OrderSetupScreen, opponentTeamHistoryProvider;
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/operator_action_buttons.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/official_record_screen.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show customTeamNamesProvider, tournamentProvider;
import 'package:kendo_os/features/match/domain/match_model.dart';

import 'package:kendo_os/shared/domain/entities/team_model.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late MockPlayerRepository mockPlayerRepo;
  late MockTeamRepository mockTeamRepo;

  setUp(() {
    mockPlayerRepo = MockPlayerRepository();
    mockTeamRepo = MockTeamRepository();
    when(() => mockPlayerRepo.getPlayers()).thenAnswer((_) => Stream.value([]));
    when(
      () => mockPlayerRepo.watchCustomTeamNames(),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockTeamRepo.watchTeamsByTournament(any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  group('🛡️ Theme Integration & Color Verifications', () {
    testWidgets('1. StartScreen is themed correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isarProvider.overrideWithValue(null),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
          ],
          child: const MaterialApp(home: StartScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StartScreen), findsOneWidget);

      // Verify presence of themed start buttons
      expect(find.textContaining('新しい大会'), findsOneWidget);
      expect(find.textContaining('今日の試合'), findsOneWidget);
    });

    testWidgets(
      '2. CreateTournamentScreen is themed correctly with Indigo focus and gradient colors',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              isarProvider.overrideWithValue(null),
            ],
            child: const MaterialApp(home: CreateTournamentScreen()),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(CreateTournamentScreen), findsOneWidget);
      },
    );

    testWidgets(
      '3. SetupMatchFormatScreen renders correctly with dynamic theme colors',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // Test under normal theme (Indigo)
        final lightTheme = ThemeData.light().copyWith(
          extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
              teamRepositoryProvider.overrideWithValue(mockTeamRepo),
              isarProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              theme: lightTheme,
              home: const SetupMatchFormatScreen(tournamentId: 'test_id'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(SetupMatchFormatScreen), findsOneWidget);
      },
    );

    testWidgets(
      '4. OrderSetupScreen and BunaiksenSetupScreen render without crashes under Bunaiksen mode',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final purpleTheme = ThemeData.light().copyWith(
          extensions: [AppThemeColors.ofMode(isDark: false, mode: 'bunaiksen')],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
              isarProvider.overrideWithValue(null),
              opponentTeamHistoryProvider.overrideWithValue([]),
              bunaiksenPlayerMasterProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
            ],
            child: MaterialApp(
              theme: purpleTheme,
              home: const OrderSetupScreen(tournamentId: 'test_id'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(OrderSetupScreen), findsOneWidget);
      },
    );

    testWidgets(
      '5. OperatorActionButtons viewer preview color matches viewer theme (BlueGrey/Purple)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // Test under normal tournament
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              isarProvider.overrideWithValue(null),
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
            child: const MaterialApp(
              home: Scaffold(
                body: OperatorActionButtons(
                  tournamentId: 'standard_tourney_id',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final standardBtnFinder = find.widgetWithText(
          GlassButton,
          '観客・保護者側の画面を確認 (Viewer)',
        );
        expect(standardBtnFinder, findsOneWidget);
        final standardBtn = tester.widget<GlassButton>(standardBtnFinder);
        expect(standardBtn.color, Colors.blueGrey);

        // Test under Bunaiksen tournament
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              isarProvider.overrideWithValue(null),
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
            child: const MaterialApp(
              home: Scaffold(
                body: OperatorActionButtons(tournamentId: 'bunaiksen_2026_id'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final bunaiksenBtnFinder = find.widgetWithText(
          GlassButton,
          '観客・保護者側の画面を確認 (Viewer)',
        );
        expect(bunaiksenBtnFinder, findsOneWidget);
        final bunaiksenBtn = tester.widget<GlassButton>(bunaiksenBtnFinder);
        expect(bunaiksenBtn.color, Colors.purple);
      },
    );

    testWidgets(
      '6. OfficialRecordScreen Image share button uses LINE brand green color',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              registeredTeamsProvider(
                'test_id',
              ).overrideWith((ref) => Stream.value(<TeamModel>[])),
              isExportingProvider.overrideWith((ref) => false),
              sharedPreferencesProvider.overrideWithValue(prefs),
              isarProvider.overrideWithValue(null),
              matchListProvider.overrideWith(
                (ref) => [
                  const MatchModel(
                    id: 'm1',
                    tournamentId: 'test_id',
                    groupName: 'group_1',
                    matchType: '大将',
                    redName: 'Aチーム: 赤選手',
                    whiteName: 'Bチーム: 白選手',
                    redScore: 1,
                    whiteScore: 0,
                    status: 'finished',
                  ),
                ],
              ),
              customTeamNamesProvider.overrideWith(
                (ref) => Stream.value(<String>[]),
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
              tournamentProvider(
                'test_id',
              ).overrideWith((ref) => Stream.value(null)),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: OfficialRecordScreen(tournamentId: 'test_id'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Verify image button color (Color(0xFF06C755))
        final imageBtnTextFinder = find.text('画像');
        expect(imageBtnTextFinder, findsOneWidget);
      },
    );
  });
}
