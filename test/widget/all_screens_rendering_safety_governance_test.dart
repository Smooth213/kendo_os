import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/auth/presentation/screens/pin_auth_screen.dart';
import 'package:kendo_os/features/auth/presentation/screens/role_select_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_setup_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/category_rules_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/create_tournament_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/order_setup_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_management_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/start_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/tournament_list_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/team_scoreboard_screen.dart';
import 'package:kendo_os/features/tournament/presentation/screens/bunaiksen_official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/features/tournament/presentation/screens/standings_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_match_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_official_record_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_official_record_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_team_scoreboard_screen.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/manual_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_team_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'helpers/rendering_safety_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RenderingSafetyTestHelper.initialize();
  });

  const String testTournamentId = RenderingSafetyTestHelper.testTournamentId;
  final edgeMatches = RenderingSafetyTestHelper.createEdgeCaseMatches();
  final edgeComments = RenderingSafetyTestHelper.createTestComments();

  group('🛡️ 【第15大ガバナンス】全ページ UIゼロレンダリングエラー保証 網羅的テスト', () {
    // -------------------------------------------------------------------------
    // 1. 運営・管理系画面 (14画面)
    // -------------------------------------------------------------------------
    testWidgets(
      '1. 運営・管理系画面（Start, RoleSelect, PinAuth, Settings, Master, TournamentList, ProgramManagement）',
      (tester) async {
        final screens = <Widget>[
          const StartScreen(),
          const RoleSelectScreen(),
          const PinAuthScreen(role: UserRole.operator),
          const SettingsScreen(),
          const MasterManagementScreen(),
          const TournamentListScreen(),
          const ProgramManagementScreen(tournamentId: testTournamentId),
          const ProgramViewerScreen(programs: [], initialIndex: 0),
        ];

        for (final screen in screens) {
          await tester.pumpWidget(
            RenderingSafetyTestHelper.buildTestWidget(child: screen),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} でレンダリングエラーが発生しました',
          );
        }
        await tester.pump(const Duration(milliseconds: 600));
      },
    );

    testWidgets(
      '2. 運営試合・スコア系画面（HomeScreen, TeamMatchStatus, OfficialRecord, TeamScoreboard, KachinukiScoreboard）',
      (tester) async {
        final screens = <Widget>[
          const HomeScreen(tournamentId: testTournamentId),
          const TeamMatchStatusScreen(tournamentId: testTournamentId),
          const OfficialRecordScreen(tournamentId: testTournamentId),
          const TeamScoreboardScreen(groupName: '道上剣友会A'),
          const KachinukiScoreboardScreen(groupName: '道上剣友会A'),
        ];

        for (final screen in screens) {
          await tester.pumpWidget(
            RenderingSafetyTestHelper.buildTestWidget(
              child: screen,
              matches: edgeMatches,
              comments: edgeComments,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} (エッジデータ) でレンダリングエラーが発生しました',
          );
        }
        await tester.pump(const Duration(milliseconds: 600));
      },
    );

    // -------------------------------------------------------------------------
    // 2. 大会セットアップ・設定系画面 (6画面)
    // -------------------------------------------------------------------------
    testWidgets(
      '3. 大会セットアップ系画面（CreateTournament, SetupMatch, OrderSetup, TeamReg, CategoryRules, Standings）',
      (tester) async {
        final setupScreens = <Widget>[
          const CreateTournamentScreen(),
          const SetupMatchFormatScreen(tournamentId: testTournamentId),
          const OrderSetupScreen(tournamentId: testTournamentId),
          const TeamRegistrationScreen(tournamentId: testTournamentId),
          const CategoryRulesScreen(tournamentId: testTournamentId),
          const StandingsScreen(tournamentId: testTournamentId),
        ];

        for (final screen in setupScreens) {
          await tester.pumpWidget(
            RenderingSafetyTestHelper.buildTestWidget(child: screen),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} でレンダリングエラーが発生しました',
          );
        }
        await tester.pump(const Duration(milliseconds: 600));
      },
    );

    // -------------------------------------------------------------------------
    // 3. 部内戦画面 (3画面)
    // -------------------------------------------------------------------------
    testWidgets(
      '4. 部内戦画面（BunaiksenHome, BunaiksenSetup, BunaiksenOfficialRecord）',
      (tester) async {
        final bunaiksenScreens = <Widget>[
          const BunaiksenHomeScreen(),
          const BunaiksenSetupScreen(),
          const BunaiksenOfficialRecordScreen(),
        ];

        for (final screen in bunaiksenScreens) {
          await tester.pumpWidget(
            RenderingSafetyTestHelper.buildTestWidget(
              child: screen,
              matches: edgeMatches,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} でレンダリングエラーが発生しました',
          );
        }
        await tester.pump(const Duration(milliseconds: 600));
      },
    );

    // -------------------------------------------------------------------------
    // 4. 観戦者（Viewer）専用画面 (7画面)
    // -------------------------------------------------------------------------
    testWidgets(
      '5. 観戦者専用画面（ViewerHome, ViewerMatch, ViewerRecord, ViewerTeam, ViewerKachinuki, ViewerBunaiksenHome, ViewerBunaiksenRecord）',
      (tester) async {
        final viewerScreens = <Widget>[
          const ViewerHomeScreen(tournamentId: testTournamentId),
          const ViewerMatchScreen(matchId: 'm_edge_1'),
          const ViewerOfficialRecordScreen(tournamentId: testTournamentId),
          const ViewerTeamScoreboardScreen(groupName: '道上剣友会A'),
          const ViewerKachinukiScoreboardScreen(groupName: '道上剣友会A'),
          const ViewerBunaiksenHomeScreen(tournamentId: testTournamentId),
          const ViewerBunaiksenOfficialRecordScreen(
            tournamentId: testTournamentId,
          ),
        ];

        for (final screen in viewerScreens) {
          await tester.pumpWidget(
            RenderingSafetyTestHelper.buildTestWidget(
              child: screen,
              matches: edgeMatches,
              comments: edgeComments,
              role: UserRole.viewer,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} (観戦モード) でレンダリングエラーが発生しました',
          );
        }
        await tester.pump(const Duration(milliseconds: 600));
      },
    );

    // -------------------------------------------------------------------------
    // 5. フローティングドック展開全ボトムシート (全7種)
    // -------------------------------------------------------------------------
    testWidgets(
      '6. ドック全ボトムシート展開（Program, Memo, Announce, Manual, ViewerSettings, OfficialRecord, TeamStatus）',
      (tester) async {
        final sheets = <Widget>[
          const ProgramBottomSheet(
            tournamentId: testTournamentId,
            isViewerMode: false,
          ),
          const QuickMemoBottomSheet(tournamentId: testTournamentId),
          const AnnounceHistoryBottomSheet(
            tournamentId: testTournamentId,
            isStaffRoom: true,
          ),
          const ManualBottomSheet(isViewerMode: false),
          const ViewerSettingsBottomSheet(),
          const OfficialRecordScreen(
            tournamentId: testTournamentId,
            isBottomSheet: true,
          ),
          const TeamMatchStatusScreen(
            tournamentId: testTournamentId,
            isBottomSheet: true,
          ),
        ];

        for (final sheet in sheets) {
          await tester.pumpWidget(
            RenderingSafetyTestHelper.buildTestWidget(
              child: sheet,
              matches: edgeMatches,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason: '${sheet.runtimeType} ボトムシート展開でレンダリングエラーが発生しました',
          );
        }
        await tester.pump(const Duration(milliseconds: 600));
      },
    );

    // -------------------------------------------------------------------------
    // 6. タイムライン複合エッジケースカード（見出しコメント混在 ReorderableListView 完全保証）
    // -------------------------------------------------------------------------
    testWidgets(
      '7. TimelineTeamCard 見出しコメント混在 ReorderableListView ゼロレンダリングエラー保証',
      (tester) async {
        final teamCard = TimelineTeamCard(
          teamName: '道上剣友会A',
          teamMatchesList: edgeMatches,
          categoryName: '小学生の部',
          tournamentId: testTournamentId,
          sanitizedQuery: '',
          matchedMatchIds: const {},
          matchedGroupNames: const {},
          ownTeams: const ['道上剣友会A'],
          comments: edgeComments,
          isReadOnlyUI: false,
          canManageTournamentUI: true,
          isDark: false,
          permissions: const PermissionState(role: UserRole.operator),
        );

        await tester.pumpWidget(
          RenderingSafetyTestHelper.buildTestWidget(
            child: teamCard,
            matches: edgeMatches,
            comments: edgeComments,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason: 'TimelineTeamCard でレンダリングエラーが発生しました',
        );
        expect(find.text('道上剣友会A'), findsWidgets);
        expect(find.text('【重要連絡】次の試合は第2コートです'), findsOneWidget);
      },
    );
  });
}
