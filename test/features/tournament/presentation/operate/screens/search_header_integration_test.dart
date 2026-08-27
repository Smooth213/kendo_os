import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_search_header.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  group(
    '🔍 Search Header Integration Tests (HomeScreen & ViewerHomeScreen)',
    () {
      late MockTournamentRepository mockTournamentRepo;
      late MockPlayerRepository mockPlayerRepo;
      late MockSyncEngine mockSyncEngine;
      late MockLocalMatchRepository mockLocalRepo;
      late SharedPreferences prefs;

      const testTournamentId = 'test_tournament_1';
      final dummyTournament = TournamentModel(
        id: testTournamentId,
        name: 'テスト大会',
        date: DateTime.now(),
        venue: '道場',
        categories: ['一般の部'],
        organizationId: 'dojo_123',
      );

      final mockMatches = [
        const MatchModel(
          id: 'm1',
          tournamentId: testTournamentId,
          matchType: '個人戦',
          redName: '亀山クラブ : 選手A',
          whiteName: '広島道場 : 選手B',
          status: 'waiting',
          order: 1.0,
        ),
        const MatchModel(
          id: 'm2',
          tournamentId: testTournamentId,
          matchType: '個人戦',
          redName: '岡山館 : 選手C',
          whiteName: '鳥取倶楽部 : 選手D',
          status: 'waiting',
          order: 2.0,
        ),
      ];

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
        mockTournamentRepo = MockTournamentRepository();
        mockPlayerRepo = MockPlayerRepository();
        mockSyncEngine = MockSyncEngine();
        mockLocalRepo = MockLocalMatchRepository();

        when(
          () => mockTournamentRepo.getTournamentStream(any()),
        ).thenAnswer((_) => Stream.value(dummyTournament));
        when(
          () => mockPlayerRepo.watchCustomTeamNames(
            organization: any(named: 'organization'),
          ),
        ).thenAnswer((_) => Stream.value([]));
        when(
          () => mockLocalRepo.watchLocalMatches(any()),
        ).thenAnswer((_) => Stream.value(mockMatches));
        when(
          () => mockLocalRepo.watchAllLocalMatches(),
        ).thenAnswer((_) => Stream.value(mockMatches));
      });

      Widget buildTestApp({
        required Widget child,
        List<Override> overrides = const [],
      }) {
        final router = GoRouter(
          initialLocation: '/',
          routes: [GoRoute(path: '/', builder: (context, state) => child)],
        );

        return ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
            currentTournamentIdProvider.overrideWith((ref) => testTournamentId),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
            dojoRoomSyncProvider.overrideWithValue(null),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(mockMatches),
            ),
            ...overrides,
          ],
          child: MaterialApp.router(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            routerConfig: router,
          ),
        );
      }

      testWidgets(
        '1. HomeScreen（運営）: 検索ボタン押下でAppSearchHeaderが開き、入力・キャンセルで正常に閉じること',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            buildTestApp(
              overrides: [
                currentUserRoleProvider.overrideWith(
                  (ref) => UserRole.operator,
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
              child: const HomeScreen(tournamentId: testTournamentId),
            ),
          );

          await tester.pump();
          await tester.pumpAndSettle();

          // 初期状態: 通常の「大会ホーム」ヘッダーが表示されていること
          expect(find.text('大会ホーム'), findsOneWidget);
          expect(find.byType(AppSearchHeader), findsNothing);

          // 試合リスト内の検索アイコンボタン（tooltip: '試合を検索'）をタップ
          final searchButton = find.byTooltip('試合を検索');
          expect(searchButton, findsOneWidget);
          await tester.tap(searchButton);
          await tester.pumpAndSettle();

          // 検索モード: AppSearchHeader が AppBar に表示されていること
          expect(find.byType(AppSearchHeader), findsOneWidget);
          expect(find.text('大会ホーム'), findsNothing);
          expect(find.text('選手名・チーム名で検索...'), findsOneWidget);
          expect(find.text('キャンセル'), findsOneWidget);

          // 検索ワードを入力
          await tester.enterText(find.byType(AppTextField), '選手A');
          await tester.pumpAndSettle();

          // 「キャンセル」ボタンを押下して検索を終了
          await tester.tap(find.text('キャンセル'));
          await tester.pumpAndSettle();

          // 検索終了: 通常の「大会ホーム」ヘッダーに復帰すること
          expect(find.text('大会ホーム'), findsOneWidget);
          expect(find.byType(AppSearchHeader), findsNothing);
        },
      );

      testWidgets(
        '2. ViewerHomeScreen（観客）: 検索ボタン押下でAppSearchHeaderが開き、入力・キャンセルで正常に閉じること',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            buildTestApp(
              overrides: [
                currentUserRoleProvider.overrideWith((ref) => UserRole.viewer),
                permissionProvider.overrideWith(
                  (ref) => const AppPermissions(
                    isReadOnly: true,
                    canManageTournament: false,
                    canCreateMatch: false,
                    canChangeSettings: false,
                    canDeleteData: false,
                  ),
                ),
              ],
              child: const ViewerHomeScreen(tournamentId: testTournamentId),
            ),
          );

          await tester.pump();
          await tester.pumpAndSettle();

          // 初期状態: 「大会ホーム (観客席)」ヘッダーが表示されていること
          expect(find.text('大会ホーム (観客席)'), findsOneWidget);
          expect(find.byType(AppSearchHeader), findsNothing);

          // 試合リスト内の検索アイコンボタンをタップ
          final searchButton = find.byTooltip('試合を検索');
          expect(searchButton, findsOneWidget);
          await tester.tap(searchButton);
          await tester.pumpAndSettle();

          // 検索モード: AppSearchHeader が表示されること
          expect(find.byType(AppSearchHeader), findsOneWidget);
          expect(find.text('大会ホーム (観客席)'), findsNothing);
          expect(find.text('キャンセル'), findsOneWidget);

          // 「キャンセル」ボタンを押下して検索を終了
          await tester.tap(find.text('キャンセル'));
          await tester.pumpAndSettle();

          // 検索終了: 「大会ホーム (観客席)」ヘッダーに復帰すること
          expect(find.text('大会ホーム (観客席)'), findsOneWidget);
          expect(find.byType(AppSearchHeader), findsNothing);
        },
      );
    },
  );
}
