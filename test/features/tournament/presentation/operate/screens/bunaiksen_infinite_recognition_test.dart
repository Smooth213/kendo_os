import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';

class FakeLocalMatchRepository implements LocalMatchRepository {
  final List<MatchModel> matches;
  FakeLocalMatchRepository(this.matches);

  @override
  Stream<List<MatchModel>> watchMatches() => Stream.value(matches);

  @override
  Stream<MatchModel?> watchSingleMatch(String matchId) =>
      Stream.value(matches.where((m) => m.id == matchId).firstOrNull);

  @override
  Future<MatchModel?> getMatch(String matchId) async =>
      matches.where((m) => m.id == matchId).firstOrNull;

  @override
  Future<void> saveMatch(MatchModel match) async {}

  @override
  Future<void> saveMatchesBulk(List<MatchModel> matches) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

class FakeSyncEngine implements SyncEngine {
  @override
  Future<void> processQueue() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

void main() {
  group('🛡️ STEP 5-2: 部内戦・無限勝ち抜き認識＆確定フローの徹底検証要塞', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'kendo_sync_settings': '{"confirmBehavior":"single"}',
      });
    });

    testWidgets(
      'Case 1: 部内戦 + 無限勝ち抜きの場合、ボタンに「確定・部内戦ホームへ」と表示され、タップすると無限次試合ダイアログが出る',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final prefs = await SharedPreferences.getInstance();
        final match = MatchModel(
          id: 'infinite_bunaiksen_1',
          tournamentId: 'bunaiksen_20260703',
          groupName: 'infinite_20260703',
          matchType: '無限勝ち抜き',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          isKachinuki: true,
        );

        final fakeRepo = FakeLocalMatchRepository([match]);

        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const Scaffold(body: Text('Home')),
            ),
            GoRoute(
              path: '/match/:matchId',
              builder: (context, state) =>
                  MatchScreen(matchId: state.pathParameters['matchId']!),
            ),
          ],
        );

        final container = ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localMatchRepositoryProvider.overrideWithValue(fakeRepo),
            syncEngineProvider.overrideWithValue(FakeSyncEngine()),
            matchListProvider.overrideWithValue([match]),
            currentDojoIdProvider.overrideWith((ref) => 'test203'),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
            matchViewStateUserIdProvider.overrideWith((ref) => 'test_user'),
            bunaiksenInfiniteQueueProvider.overrideWith((ref) {
              final notifier = BunaiksenInfiniteQueueNotifier();
              notifier.setPlayers(['選手C']);
              return notifier;
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        );

        await tester.pumpWidget(container);
        router.push('/match/infinite_bunaiksen_1');
        await tester.pumpAndSettle();

        // 1. ボタンが「確定・部内戦ホームへ」と認識されていることを確認
        final confirmBtn = find.text('確定・部内戦ホームへ');
        expect(confirmBtn, findsOneWidget);

        // 2. タップすると「無限稽古: 次の試合」ダイアログが起動することを確認
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(find.text('無限稽古: 次の試合'), findsOneWidget);
        expect(find.text('挑戦(白): 選手C'), findsOneWidget);

        // 3. 「無限稽古を終了」ボタンが表示され、タップすると状態がリセットされてダイアログが閉じることを確認
        final finishBtn = find.text('無限稽古を終了');
        expect(finishBtn, findsOneWidget);

        final providerContainer = ProviderScope.containerOf(
          tester.element(find.byType(MatchScreen)),
        );
        expect(
          providerContainer.read(bunaiksenInfiniteQueueProvider),
          isNotEmpty,
        );

        await tester.tap(finishBtn);
        await tester.pumpAndSettle();

        expect(find.text('無限稽古: 次の試合'), findsNothing);
        expect(providerContainer.read(bunaiksenInfiniteQueueProvider), isEmpty);
      },
    );

    testWidgets(
      'Case 2: 公式大会 + 無限勝ち抜きの場合、ボタンに「確定・大会ホームへ」と表示され、タップすると無限次試合ダイアログが出る',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final prefs = await SharedPreferences.getInstance();
        final match = MatchModel(
          id: 'infinite_official_1',
          tournamentId: 'tournament_20260703', // bunaiksen_ で始まらない
          groupName: 'infinite_20260703',
          matchType: '無限勝ち抜き',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          isKachinuki: true,
        );

        final fakeRepo = FakeLocalMatchRepository([match]);

        final container = ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localMatchRepositoryProvider.overrideWithValue(fakeRepo),
            syncEngineProvider.overrideWithValue(FakeSyncEngine()),
            matchListProvider.overrideWithValue([match]),
            currentDojoIdProvider.overrideWith((ref) => 'test203'),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
            matchViewStateUserIdProvider.overrideWith((ref) => 'test_user'),
            bunaiksenInfiniteQueueProvider.overrideWith((ref) {
              final notifier = BunaiksenInfiniteQueueNotifier();
              notifier.setPlayers(['選手C']);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: MatchScreen(matchId: 'infinite_official_1'),
          ),
        );

        await tester.pumpWidget(container);
        await tester.pumpAndSettle();

        // 1. ボタンが「確定・大会ホームへ」と認識されていることを確認
        final confirmBtn = find.text('確定・大会ホームへ');
        expect(confirmBtn, findsOneWidget);

        // 2. タップすると「無限稽古: 次の試合」ダイアログが起動することを確認
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(find.text('無限稽古: 次の試合'), findsOneWidget);
        expect(find.text('挑戦(白): 選手C'), findsOneWidget);
      },
    );

    testWidgets(
      'Case 3: 部内戦 + 通常試合の場合、ボタンに「確定・部内戦ホームへ」と表示され、タップしても無限次試合ダイアログは出ない',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final prefs = await SharedPreferences.getInstance();
        final match = MatchModel(
          id: 'normal_bunaiksen_1',
          tournamentId: 'bunaiksen_20260703',
          groupName: 'normal_20260703',
          matchType: '個人戦', // 無限勝ち抜きではない
          redName: '選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          isKachinuki: false,
        );

        final fakeRepo = FakeLocalMatchRepository([match]);

        final container = ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localMatchRepositoryProvider.overrideWithValue(fakeRepo),
            syncEngineProvider.overrideWithValue(FakeSyncEngine()),
            matchListProvider.overrideWithValue([match]),
            currentDojoIdProvider.overrideWith((ref) => 'test203'),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
            matchViewStateUserIdProvider.overrideWith((ref) => 'test_user'),
          ],
          child: const MaterialApp(
            home: MatchScreen(matchId: 'normal_bunaiksen_1'),
          ),
        );

        await tester.pumpWidget(container);
        await tester.pumpAndSettle();

        // 1. ボタンが「確定・部内戦ホームへ」と認識されていることを確認
        final confirmBtn = find.text('確定・部内戦ホームへ');
        expect(confirmBtn, findsOneWidget);

        // 2. タップしても「無限稽古: 次の試合」ダイアログは起動しないことを確認
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(find.text('無限稽古: 次の試合'), findsNothing);
      },
    );
  });
}
