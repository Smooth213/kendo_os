import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  testWidgets(
    'Tapping confirm button in auto-finished Infinite Kachinuki match triggers next match setup dialog',
    (WidgetTester tester) async {
      // Set larger physical size so the bottom button is visible and hit-testable
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Set settings in mock preferences to single-tap confirmation
      SharedPreferences.setMockInitialValues({
        'kendo_sync_settings': '{"confirmBehavior":"single"}',
      });
      final prefs = await SharedPreferences.getInstance();

      final finishedMatch = MatchModel(
        id: 'infinite_match_1',
        tournamentId: 'bunaiksen_20260703',
        groupName: 'infinite_20260703',
        matchType: '無限勝ち抜き',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 2,
        whiteScore: 0,
        status: 'finished', // auto-finished
        isKachinuki: true,
      );

      final fakeRepo = FakeLocalMatchRepository([finishedMatch]);

      final container = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localMatchRepositoryProvider.overrideWithValue(fakeRepo),
          syncEngineProvider.overrideWithValue(FakeSyncEngine()),
          matchListProvider.overrideWithValue([finishedMatch]),
          currentDojoIdProvider.overrideWith((ref) => 'test203'),
          currentUserRoleProvider.overrideWithValue(UserRole.admin),
          matchViewStateUserIdProvider.overrideWith((ref) => 'test_user'),
          bunaiksenInfiniteQueueProvider.overrideWith((ref) {
            final notifier = BunaiksenInfiniteQueueNotifier();
            notifier.setPlayers(['選手C', '選手D']);
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: MatchScreen(matchId: 'infinite_match_1'),
        ),
      );

      await tester.pumpWidget(container);
      await tester.pumpAndSettle();

      // Find the confirm button (shows as "確定・部内戦ホームへ")
      final confirmBtn = find.text('確定・部内戦ホームへ');
      expect(confirmBtn, findsOneWidget);

      // Tap confirm (now single-tap is active)
      await tester.tap(confirmBtn);

      // Wait for all transitions (showing/popping loading indicator, then showing next dialog) to settle
      await tester.pumpAndSettle();

      // Now we should see the "無限稽古: 次の試合" dialog
      expect(find.text('無限稽古: 次の試合'), findsOneWidget);
      expect(find.text('挑戦(白): 選手C'), findsOneWidget);
      expect(find.text('無限稽古を終了'), findsOneWidget);
      expect(find.text('すぐに次の試合を開始'), findsOneWidget);
    },
  );
}
