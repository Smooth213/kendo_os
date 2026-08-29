import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_match_list_header_bar.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_match_card.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_official_record_screen.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/routing/app_router.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ 部内戦 観客用ビュアー完全一致（Parity）検証テスト要塞', () {
    late SharedPreferences prefs;
    final testDate = DateTime(2026, 8, 28);
    final dateStr = DateFormat('yyyyMMdd').format(testDate);
    final dateDisplay = DateFormat('yyyy/MM/dd').format(testDate);
    final tournamentId = 'bunaiksen_$dateStr';

    late List<MatchModel> mockMatches;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      mockMatches = [
        MatchModel(
          id: 'bunaiksen_match_001',
          tournamentId: tournamentId,
          category: '一般の部',
          matchType: '部内戦',
          order: 1.0,
          redName: '神崎 剣士',
          whiteName: '藤堂 達也',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
          note: '第1試合場',
        ),
        MatchModel(
          id: 'bunaiksen_match_002',
          tournamentId: tournamentId,
          category: '青年の部',
          matchType: '無限勝ち抜き',
          order: 2.0,
          redName: '坂本 龍之介',
          whiteName: '沖田 総司',
          redScore: 1,
          whiteScore: 0,
          status: 'in_progress',
          isKachinuki: true,
        ),
      ];
    });

    Widget createTestApp({required GoRouter router, required bool isOperator}) {
      final themeColors = AppThemeColors.ofMode(
        isDark: false,
        mode: isOperator ? 'bunaiksen' : 'bunaiksen_viewer',
      );

      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentDojoIdProvider.overrideWith((ref) => 'dojo_test_001'),
          currentTournamentIdProvider.overrideWith((ref) => tournamentId),
          bunaiksenViewDateProvider.overrideWith((ref) => testDate),
          bunaiksenAvailableDatesProvider.overrideWith(
            (ref) => Stream.value({dateStr}),
          ),
          bunaiksenMatchesProvider(
            tournamentId,
          ).overrideWith((ref) => mockMatches),
          if (isOperator) ...[
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
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
            permissionProvider.overrideWith(
              (ref) =>
                  const AppPermissions(role: UserRole.viewer, isReadOnly: true),
            ),
          ],
        ],
        child: MaterialApp.router(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          routerConfig: router,
        ),
      );
    }

    testWidgets('1. 【本部 👁️ ボタン押下 ➔ 観客席画面への完全遷移検証】'
        '本部ホームからプレビューを開いた際、QR直リンクと同一の ViewerBunaiksenHomeScreen が描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/bunaiksen-home',
        routes: [
          GoRoute(
            path: '/bunaiksen-home',
            builder: (context, state) => const BunaiksenHomeScreen(),
          ),
          GoRoute(
            path: '/bunaiksen-viewer-home/:tournamentId',
            builder: (context, state) => RoleInjector(
              roleStr: 'viewer',
              dojoId: state.uri.queryParameters['dojoId'],
              tournamentId: state.pathParameters['tournamentId']!,
              child: AppThemeModeWrapper(
                mode: 'bunaiksen_viewer',
                child: ViewerBunaiksenHomeScreen(
                  tournamentId: state.pathParameters['tournamentId']!,
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/bunaiksen-viewer-record/:tournamentId',
            builder: (context, state) => RoleInjector(
              roleStr: 'viewer',
              dojoId: state.uri.queryParameters['dojoId'],
              tournamentId: state.pathParameters['tournamentId']!,
              child: AppThemeModeWrapper(
                mode: 'bunaiksen_viewer',
                child: ViewerBunaiksenOfficialRecordScreen(
                  tournamentId: state.pathParameters['tournamentId']!,
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router: router, isOperator: true));
      await tester.pumpAndSettle();

      // 1. 本部画面に「👁️（Icons.visibility）」ボタンが存在すること
      final eyeButtonFinder = find.byIcon(Icons.visibility);
      expect(eyeButtonFinder, findsOneWidget);

      // 2. 本部用UI（クイック対戦・ルール一括変更）が存在すること
      expect(find.text('クイック対戦'), findsOneWidget);
      expect(find.text('ルール一括変更'), findsOneWidget);

      // 3. 👁️ボタンをタップして観客閲覧モードへ遷移
      await tester.tap(eyeButtonFinder);
      await tester.pumpAndSettle();

      // 4. ViewerBunaiksenHomeScreen がマウントされたことを検証
      expect(find.byType(ViewerBunaiksenHomeScreen), findsOneWidget);
      expect(find.text('$dateDisplay の記録 (観戦)'), findsOneWidget);

      // 5. 試合リスト（ViewerBunaiksenMatchCard）が正確に表示されていること
      expect(find.byType(ViewerBunaiksenMatchCard), findsNWidgets(2));
      expect(find.text('神崎 剣士'), findsOneWidget);
      expect(find.text('藤堂 達也'), findsOneWidget);
      expect(find.text('坂本 龍之介'), findsOneWidget);
      expect(find.text('沖田 総司'), findsOneWidget);

      // 6. 運営者専用機能が観客モードでは完全に消去されていること
      expect(find.byType(BunaiksenMatchListHeaderBar), findsNothing);
      expect(find.text('クイック対戦'), findsNothing);
      expect(find.text('ルール一括変更'), findsNothing);
      expect(find.byType(SlidableAction), findsNothing);
    });

    testWidgets('2. 【観客画面の専用機能パリティ検証】'
        '観客席画面において、表示設定・共有・成績一覧の各アクションが正常に利用可能であること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/bunaiksen-viewer-home/$tournamentId',
        routes: [
          GoRoute(
            path: '/bunaiksen-viewer-home/:tournamentId',
            builder: (context, state) => RoleInjector(
              roleStr: 'viewer',
              dojoId: state.uri.queryParameters['dojoId'],
              tournamentId: state.pathParameters['tournamentId']!,
              child: AppThemeModeWrapper(
                mode: 'bunaiksen_viewer',
                child: ViewerBunaiksenHomeScreen(
                  tournamentId: state.pathParameters['tournamentId']!,
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/bunaiksen-viewer-record/:tournamentId',
            builder: (context, state) => RoleInjector(
              roleStr: 'viewer',
              dojoId: state.uri.queryParameters['dojoId'],
              tournamentId: state.pathParameters['tournamentId']!,
              child: AppThemeModeWrapper(
                mode: 'bunaiksen_viewer',
                child: ViewerBunaiksenOfficialRecordScreen(
                  tournamentId: state.pathParameters['tournamentId']!,
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router: router, isOperator: false));
      await tester.pumpAndSettle();

      // Moreメニューの存在確認と展開
      final moreBtn = find.byIcon(Icons.more_horiz_rounded);
      expect(moreBtn, findsOneWidget);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // 観客画面必須アクション（表示設定・共有・成績一覧）の存在確認
      expect(find.text('表示設定'), findsOneWidget);
      expect(find.text('観戦リンクを共有する'), findsOneWidget);
      expect(find.text('部内戦 成績一覧'), findsOneWidget);

      // 成績一覧をタップして遷移
      await tester.tap(find.text('部内戦 成績一覧'));
      await tester.pumpAndSettle();

      // ViewerBunaiksenOfficialRecordScreen が表示されること
      expect(find.byType(ViewerBunaiksenOfficialRecordScreen), findsOneWidget);
      expect(find.text('$dateDisplay 成績 (観戦)'), findsOneWidget);
    });
  });
}
