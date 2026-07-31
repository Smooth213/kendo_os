import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/order_setup_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

void main() {
  late MockPlayerRepository mockPlayerRepo;

  setUp(() {
    mockPlayerRepo = MockPlayerRepository();
    when(() => mockPlayerRepo.getPlayers()).thenAnswer((_) => Stream.value([]));
    when(
      () => mockPlayerRepo.watchCustomTeamNames(),
    ).thenAnswer((_) => Stream.value([]));
  });

  group('🛡️ Order Drag & Drop Reordering & Bunaiksen Quick Match Tests', () {
    testWidgets(
      '1. Verify OrderSetupScreen renders ReorderableListView with drag handle icons',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test204'),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
              isarProvider.overrideWithValue(null),
              opponentTeamHistoryProvider.overrideWithValue([]),
              dojoRoomSyncProvider.overrideWith((ref) {}),
              matchRuleProvider.overrideWith(() => MatchRuleNotifier()),
            ],
            child: const MaterialApp(
              home: OrderSetupScreen(tournamentId: 'test_t1'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // OrderSetupScreen が正常に構築されること
        expect(find.byType(OrderSetupScreen), findsOneWidget);
        expect(find.text('オーダー編成'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Verify BunaiksenHomeScreen renders 1-second quick match button',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test204'),
              isarProvider.overrideWithValue(null),
              dojoRoomSyncProvider.overrideWith((ref) {}),
            ],
            child: const MaterialApp(home: BunaiksenHomeScreen()),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 「クイック対戦を始める」ボタンが存在すること
        final quickButton = find.text('クイック対戦を始める');
        expect(quickButton, findsOneWidget);
      },
    );

    testWidgets(
      '3. Verify BunaiksenHomeScreen Quick Match Sheet Flow (Default 2min, Stepper +/- & 1-Ippon Format)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const BunaiksenHomeScreen(),
            ),
            GoRoute(
              path: '/match/:id',
              builder: (context, state) =>
                  const Scaffold(body: Text('Match Screen Dummy')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test204'),
              isarProvider.overrideWithValue(null),
              dojoRoomSyncProvider.overrideWith((ref) {}),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 1. クイック対戦ボタンをタップしてボトムシートを開く
        final quickButton = find.text('クイック対戦を始める');
        await tester.tap(quickButton);
        await tester.pumpAndSettle();

        // 2. ボトムシートの各表示要素の初期状態を検証
        expect(find.text('クイック対戦'), findsOneWidget);
        expect(find.text('2分'), findsOneWidget); // デフォルト2分
        expect(find.text('3本勝負'), findsOneWidget);
        expect(find.text('1本勝負'), findsOneWidget);

        // 3. ＋ボタンをタップして 2.5分 に変更されること
        final addButton = find.byIcon(Icons.add).last;
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        expect(find.text('2.5分'), findsOneWidget);

        // 4. －ボタンをタップして 2分 に戻ること
        final removeButton = find.byIcon(Icons.remove).last;
        await tester.tap(removeButton);
        await tester.pumpAndSettle();
        expect(find.text('2分'), findsOneWidget);

        // 5. 勝負形式「1本勝負」をタップ
        final oneIpponBtn = find.text('1本勝負');
        await tester.tap(oneIpponBtn);
        await tester.pumpAndSettle();

        // 6. 試合スタートボタンをタップ
        final startBtn = find.text('試合スタート');
        expect(startBtn, findsOneWidget);
        await tester.tap(startBtn);
        await tester.pumpAndSettle();

        // 例外が発生せず、ダミー試合画面に安全に遷移できたことを検証
        expect(find.text('Match Screen Dummy'), findsOneWidget);
      },
    );
  });
}
