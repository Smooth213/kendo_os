import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';

void main() {
  group('🛡️ Bunaiksen Score & Match Screen Integration Tests', () {
    const mockMatch = MatchModel(
      id: 'test_match_1',
      tournamentId: 'bunaiksen_20260622',
      matchType: '個人戦',
      redName: '赤選手',
      whiteName: '白選手',
      status: 'waiting',
    );

    test('✅ 1. ViewerMatchScreen Webインデックス未作成エラー根治パッチの存在を検証 (静的コード解析)', () {
      final file = File(
        'lib/features/viewer/presentation/viewer_match_screen.dart',
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: 'viewer_match_screen.dart が存在しません',
      );

      final content = file.readAsStringSync();
      expect(
        content.contains('matchListByTournamentProvider'),
        isTrue,
        reason:
            'webScoreboardMatchProvider 代替用の matchListByTournamentProvider による監視が含まれていません',
      );
      expect(
        content.contains('scoreboardMatchProvider.overrideWithValue'),
        isTrue,
        reason:
            'Scoreboardに直接MatchModelを射出する scoreboardMatchProvider の override が含まれていません',
      );
      expect(
        content.contains('tournamentId'),
        isTrue,
        reason: 'URLから tournamentId を抽出するロジックが含まれていません',
      );
    });

    testWidgets('✅ 2. 運営用部位入力画面 (MatchScreen) データロード & レンダリング検証', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
        initialLocation:
            '/match/test_match_1?tournamentId=bunaiksen_20260622&dojoId=dojo_123',
        routes: [
          GoRoute(
            path: '/match/:id',
            builder: (context, state) =>
                MatchScreen(matchId: state.pathParameters['id']!),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          matchListProvider.overrideWith((ref) => [mockMatch]),
          matchViewStateProvider('test_match_1').overrideWith(
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
          isarProvider.overrideWithValue(null),
          commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData.light(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 無限ローディングがなく、試合テキストが正しく表示されること
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('赤選手 vs 白選手'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      container.dispose();
    });

    testWidgets('✅ 3. 一般観客席 (ViewerMatchScreen) データロード & レンダリング検証', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
        initialLocation:
            '/match/test_match_1?role=viewer&tournamentId=bunaiksen_20260622&dojoId=dojo_123',
        routes: [
          GoRoute(
            path: '/match/:id',
            builder: (context, state) =>
                ViewerMatchScreen(matchId: state.pathParameters['id']!),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          matchListProvider.overrideWith((ref) => [mockMatch]),
          matchViewStateProvider('test_match_1').overrideWith(
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
              isViewOnly: true,
              isInputLocked: true,
              isAllDone: false,
              isTie: false,
              redCleanName: '赤選手',
              whiteCleanName: '白選手',
            ),
          ),
          permissionProvider.overrideWith(
            (ref) => const AppPermissions(
              isReadOnly: true,
              canManageTournament: false,
              canCreateMatch: false,
              canChangeSettings: false,
              canDeleteData: false,
            ),
          ),
          isarProvider.overrideWithValue(null),
          matchViewStateUserIdProvider.overrideWith((ref) => 'mock_user_123'),
          commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData.light(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 観客席画面が正しく描画され、フリーズしないこと
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('試合状況 (観戦)'), findsOneWidget);
      expect(find.byType(MatchScoreboard, skipOffstage: false), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      container.dispose();
    });
  });
}
