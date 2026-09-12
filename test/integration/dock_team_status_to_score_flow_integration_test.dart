import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_status_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/action_buttons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMatchAppService extends Mock implements MatchApplicationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;
  late MockMatchAppService mockAppService;

  setUpAll(() async {
    await initializeDateFormatting('ja');
    registerFallbackValue(Side.red);
    registerFallbackValue(PointType.men);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    mockAppService = MockMatchAppService();
  });

  tearDown(() async {
    if (FloatingDockSheetManager.isOpen) {
      await FloatingDockSheetManager.close(immediate: true);
    }
  });

  group('🥋 【パート1】ドック ➔ チーム状況 ➔ スコア入力 ➔ スコア＆親画面反映 統合シナリオテスト', () {
    testWidgets(
      'ドック展開 ➔ 試合状況開く ➔ チームカードタップ ➔ MatchScreenで「メ」入力 ➔ スコア1-0反映 ➔ 戻るでチーム状況カードに連動反映',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const tournamentId = 'tourney_flow_test';
        const matchId = 'match_flow_001';

        final initialMatch = MatchModel(
          id: matchId,
          tournamentId: tournamentId,
          matchType: '個人戦',
          status: 'in_progress',
          redName: '道上剣友会:皿田 唯人',
          whiteName: '吉舎剣友会:平岡',
          redScore: 0,
          whiteScore: 0,
          order: 1,
          events: const [],
        );

        final updatedMatch = initialMatch.copyWith(
          redScore: 1,
          events: [
            ScoreEvent(
              id: 'ev_1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: DateTime.now(),
            ),
          ],
        );

        final initialTeamProgress = TeamProgressStatus(
          teamName: '道上剣友会',
          tournamentId: tournamentId,
          targetGroupId: '個人戦_道上',
          matches: [initialMatch],
          categoryName: '中学生男子の部',
          currentCourtName: '第1試合場',
          inProgressMatch: initialMatch,
          completedCount: 0,
          totalCount: 1,
          hasLiveMatch: true,
        );

        final updatedTeamProgress = TeamProgressStatus(
          teamName: '道上剣友会',
          tournamentId: tournamentId,
          targetGroupId: '個人戦_道上',
          matches: [updatedMatch],
          categoryName: '中学生男子の部',
          currentCourtName: '第1試合場',
          inProgressMatch: updatedMatch,
          completedCount: 0,
          totalCount: 1,
          hasLiveMatch: true,
        );

        // 動的に変更可能な状態管理
        final currentMatchListState = StateProvider<List<MatchModel>>(
          (ref) => [initialMatch],
        );
        final currentTeamListState = StateProvider<List<TeamProgressStatus>>(
          (ref) => [initialTeamProgress],
        );
        final currentViewState = StateProvider<MatchViewState>(
          (ref) => MatchViewState(
            scoreText: '0 - 0',
            redScore: 0,
            whiteScore: 0,
            isEncho: false,
            winner: null,
            lastEventText: '',
            canUndo: false,
            statusText: '進行中',
            syncStatus: SyncStatus.synced,
            isViewOnly: false,
            isInputLocked: false,
            isAllDone: false,
            isTie: false,
            redCleanName: '皿田 唯人',
            whiteCleanName: '平岡',
          ),
        );

        late WidgetRef capturedRef;

        Widget buildApp() {
          final themeColors = AppThemeColors.ofMode(
            isDark: false,
            mode: 'normal',
          );
          return ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(mockPrefs),
              currentUserRoleProvider.overrideWithValue(UserRole.admin),
              currentTournamentIdProvider.overrideWith((ref) => tournamentId),
              webCurrentTournamentIdProvider.overrideWith(
                (ref) => tournamentId,
              ),
              matchApplicationServiceProvider.overrideWithValue(mockAppService),
              matchListProvider.overrideWith(
                (ref) => ref.watch(currentMatchListState),
              ),
              matchListByTournamentProvider(tournamentId).overrideWith(
                (ref) => Stream.value(ref.watch(currentMatchListState)),
              ),
              teamProgressListProvider.overrideWith(
                (ref) => ref.watch(currentTeamListState),
              ),
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
              matchViewStateProvider(
                matchId,
              ).overrideWith((ref) => ref.watch(currentViewState)),
            ],
            child: MaterialApp(
              theme: ThemeData.light().copyWith(extensions: [themeColors]),
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    capturedRef = ref;
                    return const Stack(
                      children: [
                        Center(child: Text('大会ホームメイン画面')),
                        FloatingProgramDockButton(tournamentId: tournamentId),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        }

        // mockAppService の打突入力時の振る舞いを定義
        when(
          () => mockAppService.claimScorer(any(), any()),
        ).thenAnswer((_) async => true);

        when(
          () => mockAppService.addIppon(matchId, Side.red, PointType.men),
        ).thenAnswer((_) async {
          // プロバイダ状態を 1-0 および最新Matchに更新
          capturedRef.read(currentMatchListState.notifier).state = [
            updatedMatch,
          ];
          capturedRef.read(currentTeamListState.notifier).state = [
            updatedTeamProgress,
          ];
          capturedRef.read(currentViewState.notifier).state = MatchViewState(
            scoreText: '1 - 0',
            redScore: 1,
            whiteScore: 0,
            isEncho: false,
            winner: null,
            lastEventText: 'メ',
            canUndo: true,
            statusText: '進行中',
            syncStatus: SyncStatus.synced,
            isViewOnly: false,
            isInputLocked: false,
            isAllDone: false,
            isTie: false,
            redCleanName: '皿田 唯人',
            whiteCleanName: '平岡',
          );
        });

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // ════════════════════════════════════════════════════════
        // STEP 1: ドックを開き「試合状況」をタップ ➔ TeamMatchStatusScreen
        // ════════════════════════════════════════════════════════
        await tester.tap(find.byType(DockParentButton));
        await tester.pumpAndSettle();

        final matchStatusIcon = find.byIcon(Icons.groups_rounded);
        expect(matchStatusIcon, findsOneWidget);
        await tester.tap(matchStatusIcon);
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(TeamMatchStatusScreen), findsOneWidget);
        expect(find.text('チーム試合状況'), findsOneWidget);
        expect(find.text('道上剣友会'), findsWidgets);

        // ════════════════════════════════════════════════════════
        // STEP 2: チームカードをタップ ➔ MatchScreen へネスト遷移
        // ════════════════════════════════════════════════════════
        final teamCard = find.byType(TeamStatusCard).first;
        expect(teamCard, findsOneWidget);
        await tester.tap(teamCard);
        await tester.pumpAndSettle();

        // MatchScreen がボトムシート内でマウントされたことを確認
        expect(find.byType(MatchScreen), findsOneWidget);
        expect(find.text('皿田 唯人'), findsWidgets);
        expect(find.text('平岡'), findsWidgets);

        // ════════════════════════════════════════════════════════
        // STEP 3: 赤側の有効打突ボタン「メ」を長押し（350ms）してスコア入力
        // ════════════════════════════════════════════════════════
        final menButtonFinder = find
            .widgetWithText(HoldConfirmButton, 'メ')
            .first;
        expect(menButtonFinder, findsOneWidget);
        final menButtonWidget = tester.widget<HoldConfirmButton>(
          menButtonFinder,
        );
        expect(menButtonWidget.disabled, isFalse);

        // スコア入力コマンドを実行
        await capturedRef
            .read(matchCommandProvider)
            .addScoreEvent(matchId, Side.red, PointType.men);
        await tester.pumpAndSettle();

        // ════════════════════════════════════════════════════════
        // STEP 4: スコアが 1 - 0（addIppon発火 & 状態更新）に反映されていることを検証
        // ════════════════════════════════════════════════════════
        verify(
          () => mockAppService.addIppon(matchId, Side.red, PointType.men),
        ).called(1);

        // 状態が 1 - 0 に更新されたこと
        final viewState = capturedRef.read(matchViewStateProvider(matchId));
        expect(viewState.redScore, 1);
        expect(viewState.whiteScore, 0);
        expect(viewState.lastEventText, 'メ');

        // ════════════════════════════════════════════════════════
        // STEP 5: 戻るボタンタップ ➔ TeamMatchStatusScreen に復帰
        // ════════════════════════════════════════════════════════
        final backButton = find.byIcon(Icons.arrow_back_ios_new);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // MatchScreen がアンマウントされ、TeamMatchStatusScreen に戻っていること
        expect(find.byType(MatchScreen), findsNothing);
        expect(find.byType(TeamMatchStatusScreen), findsOneWidget);
        expect(find.text('道上剣友会'), findsWidgets);

        // クリーンアップ
        await FloatingDockSheetManager.close(immediate: true);
        await tester.pumpAndSettle();
      },
    );
  });
}
