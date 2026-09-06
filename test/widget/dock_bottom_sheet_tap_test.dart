import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_status_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/team_scoreboard_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('🥋 Dock BottomSheet Tap & Navigation Tests', () {
    testWidgets(
      'Inside bottom sheet, finished match section navigates to MatchScreen inside sheet',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(tester.view.resetPhysicalSize);
        final match = MatchModel(
          id: 'match_taisho_123',
          matchType: '大将',
          redName: '吉舎剣友会:平岡',
          whiteName: '道上剣友会:皿田 唯人',
          redScore: 0,
          whiteScore: 1,
          status: 'finished',
          order: 5,
          events: [],
        );

        final teamStatus = TeamProgressStatus(
          teamName: '道上剣友会',
          tournamentId: 't1',
          matches: [match],
          categoryName: '中学生の部',
          currentCourtName: '第3試合場',
          lastFinishedMatch: match,
          completedCount: 1,
          totalCount: 1,
          hasLiveMatch: false,
        );

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              teamProgressListProvider.overrideWith((ref) => [teamStatus]),
              matchListProvider.overrideWith((ref) => [match]),
              playerListProvider.overrideWith((ref) => Stream.value([])),
              permissionProvider.overrideWith(
                (ref) => const AppPermissions(
                  isReadOnly: false,
                  canManageTournament: true,
                  canCreateMatch: true,
                  canChangeSettings: true,
                  canDeleteData: true,
                ),
              ),
              matchViewStateProvider('match_taisho_123').overrideWith(
                (ref) => MatchViewState(
                  scoreText: '0 - 1',
                  redScore: 0,
                  whiteScore: 1,
                  isEncho: false,
                  winner: 'white',
                  lastEventText: '',
                  canUndo: false,
                  statusText: '終了',
                  syncStatus: SyncStatus.synced,
                  isViewOnly: false,
                  isInputLocked: true,
                  isAllDone: true,
                  isTie: false,
                  redCleanName: '平岡',
                  whiteCleanName: '皿田 唯人',
                ),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      FloatingDockSheetManager.show(
                        context: context,
                        builder: (_) => const TeamMatchStatusScreen(
                          tournamentId: 't1',
                          isBottomSheet: true,
                        ),
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        // 1. ボトムシートを開く
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.text('直前の結果: 【大将】'), findsOneWidget);
        expect(find.text('記録を開く 👉'), findsOneWidget);

        // 2. 「直前の結果」の「記録を開く 👉」をタップ
        await tester.tap(find.text('記録を開く 👉'));
        await tester.pumpAndSettle();

        // 3. ボトムシートは開いたままで、内部が MatchScreen に遷移していることを検証
        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(MatchScreen), findsOneWidget);

        // 4. 戻るボタン（Icons.arrow_back_ios_new）を押すとボトムシート内で一覧に戻る
        expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(MatchScreen), findsNothing);
        expect(find.text('直前の結果: 【大将】'), findsOneWidget);

        FloatingDockSheetManager.close(immediate: true);
      },
    );

    testWidgets(
      'Inside bottom sheet, finished team match card navigates to TeamScoreboardScreen inside sheet',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(tester.view.resetPhysicalSize);
        final lastFinished = MatchModel(
          id: 'm_finished_1',
          matchType: '大将',
          groupName: '団体戦_吉舎vs道上',
          redName: '吉舎剣友会:平岡',
          whiteName: '道上剣友会:皿田 唯人',
          redScore: 0,
          whiteScore: 1,
          status: 'finished',
          order: 5,
          events: [],
        );

        final teamStatus = TeamProgressStatus(
          teamName: '道上剣友会',
          tournamentId: 't1',
          targetGroupId: '団体戦_吉舎vs道上',
          matches: [lastFinished],
          categoryName: '中学生の部',
          currentCourtName: '第3試合場',
          lastFinishedMatch: lastFinished,
          completedCount: 5,
          totalCount: 5,
          hasLiveMatch: false,
        );

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              teamProgressListProvider.overrideWith((ref) => [teamStatus]),
              matchListProvider.overrideWith((ref) => [lastFinished]),
              matchListByTournamentProvider(
                't1',
              ).overrideWith((ref) => Stream.value([lastFinished])),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      FloatingDockSheetManager.show(
                        context: context,
                        builder: (_) => const TeamMatchStatusScreen(
                          tournamentId: 't1',
                          isBottomSheet: true,
                        ),
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        // 1. ボトムシートを開く
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);

        // 2. カード（チーム名部分）をタップ
        await tester.tap(find.text('道上剣友会').first);
        await tester.pumpAndSettle();

        // 3. ボトムシートは開いたままで、内部が TeamScoreboardScreen に遷移
        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(TeamScoreboardScreen), findsOneWidget);

        // 4. 戻るボタンを押して復帰
        expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(TeamScoreboardScreen), findsNothing);
        expect(find.text('道上剣友会'), findsWidgets);

        FloatingDockSheetManager.close(immediate: true);
      },
    );

    testWidgets('Outside bottom sheet, card tap navigates via GoRouter', (
      WidgetTester tester,
    ) async {
      String? navigatedRoute;

      final lastFinished = MatchModel(
        id: 'm_finished_1',
        matchType: '個人戦',
        redName: '吉舎剣友会:平岡',
        whiteName: '道上剣友会:皿田 唯人',
        redScore: 0,
        whiteScore: 1,
        status: 'finished',
        order: 1,
        events: [],
      );

      final teamStatus = TeamProgressStatus(
        teamName: '道上剣友会',
        tournamentId: 't1',
        matches: [lastFinished],
        categoryName: '中学生の部',
        currentCourtName: '第3試合場',
        lastFinishedMatch: lastFinished,
        completedCount: 1,
        totalCount: 1,
        hasLiveMatch: false,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TeamStatusCard(status: teamStatus, isDark: false),
            ),
          ),
          GoRoute(
            path: '/match/:id',
            builder: (context, state) {
              navigatedRoute = '/match/${state.pathParameters['id']}';
              return const Scaffold(body: Text('Match Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('道上剣友会').first);
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals('/match/m_finished_1'));
    });

    testWidgets(
      'OfficialRecordScreen export buttons inside FloatingDockSheetManager are tappable',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(tester.view.resetPhysicalSize);
        final testMatch = MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: '個人戦',
          status: 'finished',
          order: 1,
          groupName: 'group1',
          category: '中学生の部',
          redName: '選手A',
          whiteName: '選手B',
          events: [],
        );

        final mockTournament = TournamentModel(
          id: 't1',
          name: 'テスト大会',
          venue: '武道館',
          date: DateTime(2025, 1, 1),
          organizationId: 'org_1',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              matchListProvider.overrideWith((ref) => [testMatch]),
              tournamentProvider(
                't1',
              ).overrideWith((ref) => Stream.value(mockTournament)),
              registeredTeamsProvider(
                't1',
              ).overrideWith((ref) => Stream.value([])),
              customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      FloatingDockSheetManager.show(
                        context: context,
                        builder: (_) => const OfficialRecordScreen(
                          tournamentId: 't1',
                          isBottomSheet: true,
                        ),
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Open bottom sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('PDF'), findsOneWidget);
        expect(find.text('画像'), findsOneWidget);
        expect(find.text('CSV'), findsOneWidget);

        // Tapping CSV button executes smoothly without blocking dialog
        await tester.tap(find.text('CSV'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 1));

        // Tapping PDF button executes
        await tester.tap(find.text('PDF'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 1));

        // Tapping Image button executes
        await tester.tap(find.text('画像'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 1));

        FloatingDockSheetManager.close(immediate: true);
        await tester.pumpAndSettle();
      },
    );
  });
}
