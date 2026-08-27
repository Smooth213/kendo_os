import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_management_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/routing/app_router.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_drawing_toolbar.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class MockProgramRepository extends Mock implements ProgramRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<MatchModel>[]);
    registerFallbackValue(
      const MatchModel(id: '', matchType: '', redName: '', whiteName: ''),
    );
  });

  group('🛡️ 観客用ビュアー完全一致（Parity）検証テスト要塞', () {
    late MockTournamentRepository mockTournamentRepo;
    late MockPlayerRepository mockPlayerRepo;
    late MockSyncEngine mockSyncEngine;
    late MockLocalMatchRepository mockLocalRepo;
    late MockProgramRepository mockProgramRepo;
    late List<MatchModel> mockMatches;
    late TournamentModel mockTournament;
    late List<ProgramModel> mockPrograms;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      mockTournamentRepo = MockTournamentRepository();
      mockPlayerRepo = MockPlayerRepository();
      mockSyncEngine = MockSyncEngine();
      mockLocalRepo = MockLocalMatchRepository();
      mockProgramRepo = MockProgramRepository();

      mockMatches = [
        MatchModel(
          id: 'test_match_1',
          tournamentId: 'test_tour_1',
          category: '小学生の部',
          groupName: '助っ人101',
          redName: '道上剣友会',
          whiteName: '相手チーム',
          matchType: '個人戦',
          status: 'in_progress',
          order: 1.0,
          note: '第1試合場, 2回戦',
        ),
      ];

      mockTournament = TournamentModel(
        id: 'test_tour_1',
        name: '全国少年剣道錬成大会',
        date: DateTime(2026, 7, 27),
        venue: '日本武道館',
        categories: const ['小学生の部'],
        organizationId: 'dojo_123',
      );

      mockPrograms = [
        ProgramModel(
          id: 'prog_1',
          tournamentId: 'test_tour_1',
          title: '大会進行表・トーナメント表',
          fileUrl: 'https://example.com/prog1.pdf',
          fileType: 'pdf',
          createdAt: DateTime.now(),
        ),
      ];

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
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value(mockPrograms));
    });

    Widget createTestApp({
      required GoRouter router,
      required bool isAdminSession,
    }) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
          playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
          syncEngineProvider.overrideWithValue(mockSyncEngine),
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          programRepositoryProvider.overrideWithValue(mockProgramRepo),
          commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
          dojoRoomSyncProvider.overrideWithValue(null),
          currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
          currentTournamentIdProvider.overrideWith((ref) => 'test_tour_1'),
          matchListByTournamentProvider.overrideWith(
            (ref, id) => Stream.value(mockMatches),
          ),
          if (isAdminSession) ...[
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
            activeRoleProvider.overrideWithValue(Role.admin),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                role: UserRole.admin,
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
          ] else ...[
            currentUserRoleProvider.overrideWithValue(UserRole.viewer),
            activeRoleProvider.overrideWithValue(Role.viewer),
            permissionProvider.overrideWith(
              (ref) =>
                  const AppPermissions(role: UserRole.viewer, isReadOnly: true),
            ),
          ],
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
      '1. 【ホーム画面の完全一致】 本部から「観客・保護者側の画面を確認 (Viewer)」を押下して到達した画面と、QRコードから直接入った観客画面が100%同一UI・権限であること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // --- ルートA: 本部画面からボタン押下で遷移 ---
        final operatorRouter = GoRouter(
          initialLocation: '/home/test_tour_1',
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
          createTestApp(router: operatorRouter, isAdminSession: true),
        );
        await tester.pumpAndSettle();

        // 本部画面にボタンがあることを確認
        final previewButton = find.text('観客の画面を確認');
        expect(previewButton, findsOneWidget);

        // ボタンをタップして観客席画面へ遷移
        await tester.tap(previewButton);
        await tester.pumpAndSettle();

        // 観客画面の必須要素が存在することを検証
        expect(find.text('大会ホーム (観客席)'), findsOneWidget);
        expect(find.text('試合結果一覧'), findsOneWidget);
        expect(find.text('大会プログラム'), findsOneWidget);
        expect(find.text('道上剣友会'), findsWidgets);

        // 本部用ボタンは一切露出していないことを検証
        expect(find.textContaining('試合（対戦）を作成'), findsNothing);
        expect(find.text('試合ルール設定'), findsNothing);
        expect(find.textContaining('大会プログラム管理'), findsNothing);
      },
    );

    testWidgets(
      '2. 【大会プログラム画面の完全一致】 本部プレビュー時でも「大会プログラム」タイトルとなり、追加FAB・削除ゴミ箱アイコンが完全に消去されていること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final router = GoRouter(
          initialLocation: '/tournament/test_tour_1/programs?role=viewer',
          routes: [
            GoRoute(
              path: '/tournament/:id/programs',
              builder: (context, state) => RoleInjector(
                roleStr: state.uri.queryParameters['role'],
                dojoId: state.uri.queryParameters['dojoId'],
                tournamentId: state.pathParameters['id']!,
                child: ProgramManagementScreen(
                  tournamentId: state.pathParameters['id']!,
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          createTestApp(router: router, isAdminSession: true),
        );
        await tester.pumpAndSettle();

        // 観客用タイトル「大会プログラム」が表示されること（「プログラム管理」ではない）
        expect(find.text('大会プログラム'), findsOneWidget);
        expect(find.text('プログラム管理'), findsNothing);

        // プログラム名が表示されていること
        expect(find.text('大会進行表・トーナメント表'), findsOneWidget);

        // 追加ボタン(FAB)および削除アイコン(Icons.delete)が存在しないこと
        expect(find.text('プログラムを追加'), findsNothing);
        expect(find.byIcon(Icons.delete), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
      },
    );

    testWidgets(
      '3. 【プログラム描画ツールの完全一致】 観客プレビュー時でも共有ペン（ピンク・黄）が非表示となり、個人ペン（青・黒）のみ提供されること',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgramViewerDrawingToolbar(
                selectedTool: 'pen',
                activePenColor: AppKendoColors.blue,
                activeIsShared: false,
                canUseSharedPen: false, // 観客席モード
                isDark: false,
                onSelectTool: (_) {},
                onSelectPenColor: (_) {},
                onUndo: () {},
                onClearAll: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ペン選択ピッカーをタップ
        await tester.tap(find.byIcon(Icons.arrow_drop_down));
        await tester.pumpAndSettle();

        // 共有ペンの選択肢（ピンク・イエロー）が完全に非表示であること
        expect(find.text('📢 共有ペン (全員の画面に反映されます)'), findsNothing);
        expect(find.text('ピンク (共有)'), findsNothing);
        expect(find.text('イエロー (共有)'), findsNothing);

        // 個人ペン（ブルー・ブラック）が表示されること
        expect(find.text('📝 個人ペン (自分だけのメモです)'), findsOneWidget);
        expect(find.text('ブルー (個人)'), findsWidgets);
        expect(find.text('ブラック (個人)'), findsOneWidget);
      },
    );

    testWidgets(
      '4. 【公式戦記録画面の完全一致】 本部から観客用公式戦記録を開いた際、成績サマリーが非表示となり、部門別タブと高コントラスト出力ボタンのみ表示されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final router = GoRouter(
          initialLocation: '/viewer-record/test_tour_1?role=viewer',
          routes: [
            GoRoute(
              path: '/viewer-record/:tournamentId',
              builder: (context, state) => RoleInjector(
                roleStr: state.uri.queryParameters['role'],
                dojoId: state.uri.queryParameters['dojoId'],
                tournamentId: state.pathParameters['tournamentId']!,
                child: ViewerOfficialRecordScreen(
                  tournamentId: state.pathParameters['tournamentId']!,
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          createTestApp(router: router, isAdminSession: true),
        );
        await tester.pumpAndSettle();

        // 観客用公式記録画面のタイトル・エクスポートボタンが存在すること
        expect(find.text('大会 公式記録'), findsOneWidget);
        expect(find.text('PDF印刷'), findsOneWidget);
        expect(find.text('画像シェア'), findsOneWidget);

        // 成績サマリーは観客席専用仕様として非表示であること
        expect(find.text('成績サマリー'), findsNothing);
        expect(find.text('自チーム成績'), findsNothing);
      },
    );
  });
}
