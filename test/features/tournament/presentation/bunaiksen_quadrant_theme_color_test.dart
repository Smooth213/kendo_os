import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';

import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/features/viewer/providers/viewer_view_state_provider.dart'
    hide bunaiksenMatchesProvider;
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';

import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

class FakeGoRouter extends Fake implements GoRouter {
  final bool mockCanPop;
  FakeGoRouter({this.mockCanPop = false});

  @override
  bool canPop() => mockCanPop;

  @override
  void pop<T extends Object?>([T? result]) {}

  @override
  Future<T?> pushReplacement<T extends Object?>(
    String location, {
    Object? extra,
  }) {
    return Future.value(null);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(<MatchModel>[]);
    registerFallbackValue(
      const MatchModel(id: '', matchType: '', redName: '', whiteName: ''),
    );
    registerFallbackValue(
      MatchCommandModel(
        id: '',
        type: CommandType.addScore,
        payload: const {},
        createdAt: DateTime.now(),
      ),
    );
  });

  group('🛡️ Bunaiksen Quadrant Theme Color Verification Tests', () {
    const mockMatch = MatchModel(
      id: 'test_match_01',
      tournamentId: 't1',
      matchType: '個人戦',
      redName: '赤選手',
      whiteName: '白選手',
      status: 'waiting',
      order: 1.0,
    );

    const mockProjection = MatchProjection(
      id: 'test_match_01',
      tournamentId: 't1',
      matchOrder: 1,
      matchType: '個人戦',
      status: 'waiting',
      groupName: '個人戦A',
      isKachinuki: false,
      redName: '赤選手',
      whiteName: '白選手',
      redScore: 0,
      whiteScore: 0,
      redDisplays: [],
      whiteDisplays: [],
      firstPointSide: '',
      redPointMarks: [],
      whitePointMarks: [],
      remainingSeconds: 180,
      timerIsRunning: false,
      note: 'テスト試合',
    );

    // Mock SharedPreferences and Repositories
    late SharedPreferences prefs;
    late MockLocalMatchRepository mockLocalRepo;
    late MockMatchRepository mockMatchRepo;
    late MockPlayerRepository mockPlayerRepo;
    late MockTournamentRepository mockTournamentRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      debugIsWebOverride = true; // Webモードをシミュレート

      mockLocalRepo = MockLocalMatchRepository();
      mockMatchRepo = MockMatchRepository();
      mockPlayerRepo = MockPlayerRepository();
      mockTournamentRepo = MockTournamentRepository();

      when(
        () => mockPlayerRepo.watchCustomTeamNames(),
      ).thenAnswer((_) => Stream.value(<String>[]));
      when(
        () => mockLocalRepo.watchLocalMatches(any()),
      ).thenAnswer((_) => Stream.value(<MatchModel>[]));
      when(
        () => mockLocalRepo.watchAllLocalMatches(),
      ).thenAnswer((_) => Stream.value(<MatchModel>[]));
      when(
        () => mockLocalRepo.getPendingMatches(),
      ).thenAnswer((_) => Future.value(<MatchModel>[]));
      when(
        () => mockLocalRepo.saveMatchesBulk(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockLocalRepo.saveMatch(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockLocalRepo.watchSingleMatch(any()),
      ).thenAnswer((_) => Stream.value(mockMatch));
      when(
        () => mockLocalRepo.getPendingCommands(),
      ).thenAnswer((_) => Future.value(<MatchCommandModel>[]));
      when(
        () => mockLocalRepo.savePendingCommand(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockMatchRepo.watchActiveMatches(),
      ).thenAnswer((_) => Stream.value(<MatchModel>[]));
      when(
        () => mockMatchRepo.getStaticMatches(),
      ).thenAnswer((_) => Future.value(<MatchModel>[]));
    });

    tearDown(() {
      debugIsWebOverride = false;
    });

    // Helper to wrap testable widgets with provider scopes
    Widget buildTestableWidget({
      required Widget child,
      required bool isDark,
      List<Override> customOverrides = const [],
      GoRouter? goRouter,
    }) {
      final baseOverrides = [
        sharedPreferencesProvider.overrideWithValue(prefs),
        matchListProvider.overrideWith((ref) => [mockMatch]),
        matchListByTournamentProvider.overrideWith(
          (ref, id) => Stream.value([mockMatch]),
        ),
        bunaiksenMatchesProvider.overrideWith((ref, id) => [mockMatch]),
        currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
        currentUserRoleProvider.overrideWith((ref) => UserRole.viewer),
        dojoRoomSyncProvider.overrideWith((ref) {}),
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
        viewerMatchProjectionProvider(
          'test_match_01',
        ).overrideWith((ref) => Stream.value(mockProjection)),
        isarProvider.overrideWithValue(null),
        matchStreamProvider.overrideWith((ref) => Stream.value([mockMatch])),
        playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
        matchRepositoryProvider.overrideWithValue(mockMatchRepo),
        localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
        tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
        customTeamNamesProvider.overrideWith((ref) => Stream.value(<String>[])),
        firestoreRoleStreamProvider.overrideWith(
          (ref) => Stream.value(UserRole.viewer),
        ),
        matchViewStateUserIdProvider.overrideWith((ref) => 'test_user_id'),
      ];

      final router =
          goRouter ??
          GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(body: child),
              ),
            ],
          );

      return ProviderScope(
        overrides: [...baseOverrides, ...customOverrides],
        child: Builder(
          builder: (context) {
            if (goRouter != null) {
              return MaterialApp(
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                theme: ThemeData(
                  brightness: Brightness.light,
                  splashFactory: NoSplash.splashFactory,
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  splashFactory: NoSplash.splashFactory,
                ),
                home: InheritedGoRouter(
                  goRouter: goRouter,
                  child: Scaffold(body: child),
                ),
              );
            }
            return MaterialApp.router(
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              theme: ThemeData(
                brightness: Brightness.light,
                splashFactory: NoSplash.splashFactory,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                splashFactory: NoSplash.splashFactory,
              ),
              routerConfig: router,
            );
          },
        ),
      );
    }

    testWidgets(
      '1. 通常運営モード（MatchScreen）：ライトモード下で「インディゴ背景（Colors.indigo.shade600）に白文字」のAppBarカラー検証',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            isDark: false,
            child: const MatchScreen(matchId: 'test_match_01'),
            customOverrides: [
              matchViewStateProvider('test_match_01').overrideWith(
                (ref) => MatchViewState(
                  scoreText: '0 - 0',
                  redScore: 0,
                  whiteScore: 0,
                  isEncho: false,
                  winner: null,
                  lastEventText: '',
                  canUndo: false,
                  statusText: '待機中',
                  syncStatus: SyncStatus.synced,
                  isViewOnly: false,
                  isInputLocked: false,
                  isAllDone: false,
                  isTie: false,
                  redCleanName: '赤選手',
                  whiteCleanName: '白選手',
                ),
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
            ],
          ),
        );

        await tester.pumpAndSettle();

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final AppBar appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.backgroundColor, Colors.indigo.shade600);

        final titleFinder = find.descendant(
          of: appBarFinder,
          matching: find.text('個人戦'),
        );
        expect(titleFinder, findsOneWidget);
        final Text titleText = tester.widget<Text>(titleFinder);
        expect(titleText.style?.color, Colors.white);
      },
    );

    testWidgets(
      '2. 通常観客モード（ViewerMatchScreen）：ヘッダー配色が運営側インディゴと重複せず、iOSスタイルテキストを維持していること',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            isDark: false,
            child: const ViewerMatchScreen(matchId: 'test_match_01'),
          ),
        );

        await tester.pumpAndSettle();

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final AppBar appBar = tester.widget<AppBar>(appBarFinder);
        // Background color is NOT Colors.indigo.shade600
        expect(appBar.backgroundColor, isNot(Colors.indigo.shade600));

        final titleTextFinder = find.descendant(
          of: appBarFinder,
          matching: find.text('試合状況 (観戦)'),
        );
        expect(titleTextFinder, findsOneWidget);
        final Text titleText = tester.widget<Text>(titleTextFinder);
        expect(titleText.style?.color, Colors.black); // Light mode defaults
      },
    );

    testWidgets(
      '3. 部内戦運営モード（BunaiksenHomeScreen）：ライトモード下で「白背景（Colors.white）に臙脂色文字（Color(0xFF8B0000)）」のAppBarカラー検証',
      (WidgetTester tester) async {
        prefs.setString(
          'kendo_sync_settings',
          jsonEncode(const SettingsModel(enableLiquidGlass: false).toJson()),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            isDark: false,
            child: const BunaiksenHomeScreen(),
            customOverrides: [
              bunaiksenViewDateProvider.overrideWith((ref) => DateTime.now()),
              bunaiksenAvailableDatesProvider.overrideWith(
                (ref) => Stream.value(<String>{}),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final AppBar appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.backgroundColor, Colors.white);
        expect(appBar.foregroundColor, Colors.deepPurple.shade700);
      },
    );

    testWidgets(
      '4. 部内戦観客モード（ViewerBunaiksenHomeScreen）：通常インディゴ・部内戦運営臙脂と重複しない「千歳緑（Colors.teal.shade700）背景に白文字」の色分け検証 (すりガラスOFF時)',
      (WidgetTester tester) async {
        // SharedPreferences setup to save enableLiquidGlass as false
        prefs.setString(
          'kendo_sync_settings',
          jsonEncode(const SettingsModel(enableLiquidGlass: false).toJson()),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            isDark: false,
            child: const ViewerBunaiksenHomeScreen(
              tournamentId: 'bunaiksen_20260623',
            ),
            customOverrides: [
              bunaiksenAvailableDatesProvider.overrideWith(
                (ref) => Stream.value(<String>{}),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final AppBar appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.backgroundColor, Colors.purple.shade700);
        expect(appBar.foregroundColor, Colors.white);
      },
    );

    testWidgets(
      '5. 部内戦観客モード（ViewerBunaiksenHomeScreen）：すりガラスON時、背景が透明かつ文字・アイコンがColors.teal.shade700であること',
      (WidgetTester tester) async {
        // SharedPreferences setup to save enableLiquidGlass as true
        prefs.setString(
          'kendo_sync_settings',
          jsonEncode(const SettingsModel(enableLiquidGlass: true).toJson()),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            isDark: false,
            child: const ViewerBunaiksenHomeScreen(
              tournamentId: 'bunaiksen_20260623',
            ),
            customOverrides: [
              bunaiksenAvailableDatesProvider.overrideWith(
                (ref) => Stream.value(<String>{}),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final AppBar appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.backgroundColor, Colors.transparent);
        expect(appBar.foregroundColor, Colors.purple.shade700);
      },
    );

    testWidgets(
      '6. 部内戦観客モード（ViewerBunaiksenHomeScreen）：ダークモード時、文字・アイコンがColors.teal.shade300であること',
      (WidgetTester tester) async {
        prefs.setString(
          'kendo_sync_settings',
          jsonEncode(const SettingsModel(enableLiquidGlass: false).toJson()),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            isDark: true,
            child: const ViewerBunaiksenHomeScreen(
              tournamentId: 'bunaiksen_20260623',
            ),
            customOverrides: [
              bunaiksenAvailableDatesProvider.overrideWith(
                (ref) => Stream.value(<String>{}),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final AppBar appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.foregroundColor, Colors.purple.shade300);
      },
    );

    testWidgets(
      '7. カレンダーダイアログテーマ配色検証（ViewerBunaiksenHomeScreen）：ライトモード時はColors.teal.shade700、ダークモード時はColors.teal.shade300に適合すること',
      (WidgetTester tester) async {
        prefs.setString(
          'kendo_sync_settings',
          jsonEncode(const SettingsModel(enableLiquidGlass: false).toJson()),
        );

        // 7-1. Light mode check
        await tester.pumpWidget(
          buildTestableWidget(
            isDark: false,
            goRouter: FakeGoRouter(mockCanPop: true),
            child: const ViewerBunaiksenHomeScreen(
              tournamentId: 'bunaiksen_20260623',
            ),
            customOverrides: [
              bunaiksenAvailableDatesProvider.overrideWith(
                (ref) => Stream.value(<String>{'20260623'}),
              ),
              bunaiksenViewDateProvider.overrideWith(
                (ref) => DateTime(2026, 6, 23),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Tap calendar icon button to trigger DatePicker dialog
        final calendarBtn = find.byIcon(Icons.calendar_month);
        expect(calendarBtn, findsOneWidget);
        await tester.tap(calendarBtn);
        await tester.pumpAndSettle();

        // Find DatePickerDialog / Theme widget inside
        final themeFinder = find
            .descendant(of: find.byType(Dialog), matching: find.byType(Theme))
            .first;

        final Theme themeWidget = tester.widget<Theme>(themeFinder);
        expect(themeWidget.data.colorScheme.primary, Colors.purple.shade700);

        // Close dialog locale-agnostically
        Navigator.of(tester.element(find.byType(Dialog))).pop();
        await tester.pumpAndSettle();

        // 7-2. Dark mode check
        await tester.pumpWidget(
          buildTestableWidget(
            isDark: true,
            goRouter: FakeGoRouter(mockCanPop: true),
            child: const ViewerBunaiksenHomeScreen(
              tournamentId: 'bunaiksen_20260623',
            ),
            customOverrides: [
              bunaiksenAvailableDatesProvider.overrideWith(
                (ref) => Stream.value(<String>{'20260623'}),
              ),
              bunaiksenViewDateProvider.overrideWith(
                (ref) => DateTime(2026, 6, 23),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        final calendarBtnDark = find.byIcon(Icons.calendar_month);
        expect(calendarBtnDark, findsOneWidget);
        await tester.tap(calendarBtnDark);
        await tester.pumpAndSettle();

        final themeFinderDark = find
            .descendant(of: find.byType(Dialog), matching: find.byType(Theme))
            .first;

        final Theme themeWidgetDark = tester.widget<Theme>(themeFinderDark);
        expect(
          themeWidgetDark.data.colorScheme.primary,
          Colors.purple.shade300,
        );
      },
    );
  });
}
