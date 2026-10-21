import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_matches_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_score_marks.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocalMatchRepository implements LocalMatchRepository {
  final List<MatchModel> matches;
  _FakeLocalMatchRepository(this.matches);

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
  Future<void> saveMatchesBulk(
    List<MatchModel> matches, {
    bool skipTwin = false,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

class _FakeSyncEngine implements SyncEngine {
  @override
  Future<void> processQueue() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] BunaiksenSheetAndConfirmDialog 統合テスト', () {
    testWidgets('ホーム画面と同じ順番で表示されBunaiksenScoreMarksが描画されること', (tester) async {
      final mockMatch1 = MatchModel(
        id: 'match_1',
        tournamentId: 'bunaiksen_20260911',
        matchType: '個人戦',
        matchOrder: 1,
        order: 1,
        redName: '皿田 脩人',
        whiteName: '塚本 大道',
        redScore: 0,
        whiteScore: 0,
        status: 'pending',
      );

      final mockMatch2 = MatchModel(
        id: 'match_2',
        tournamentId: 'bunaiksen_20260911',
        matchType: '個人戦',
        matchOrder: 2,
        order: 2,
        redName: '皿田 梓人',
        whiteName: '久安 智也',
        redScore: 0,
        whiteScore: 0,
        status: 'pending',
      );

      final mockMatch6 = MatchModel(
        id: 'match_6',
        tournamentId: 'bunaiksen_20260911',
        matchType: '個人戦',
        matchOrder: 6,
        order: 6,
        redName: '皿田 脩人',
        whiteName: '塚本 大道',
        redScore: 1,
        whiteScore: 0,
        status: 'approved',
        events: [
          ScoreEvent(
            id: 'ev_1',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final List<MatchModel> mockMatches = [mockMatch1, mockMatch2, mockMatch6];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bunaiksenMatchesProvider(
              'bunaiksen_20260911',
            ).overrideWithValue(mockMatches),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BunaiksenDockMatchesSheet(
                tournamentId: 'bunaiksen_20260911',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('本日の対戦一覧・進行状況'), findsOneWidget);
      expect(find.text('第1試合'), findsOneWidget);
      expect(find.text('第2試合'), findsOneWidget);
      expect(find.text('第3試合'), findsOneWidget);

      expect(find.text('皿田 脩人'), findsNWidgets(2));
      expect(find.text('塚本 大道'), findsNWidgets(2));
      expect(find.text('皿田 梓人'), findsOneWidget);
      expect(find.text('久安 智也'), findsOneWidget);

      expect(find.byType(BunaiksenScoreMarks), findsNWidgets(3));
      expect(find.text('㋙'), findsOneWidget);
      expect(find.text('待機中'), findsNWidgets(2));
      expect(find.text('確定'), findsOneWidget);
    });

    testWidgets('自動終了した勝ち抜き試合の確定ボタンタップ時に次試合設定ダイアログが表示されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
        status: 'finished',
        isKachinuki: true,
      );

      final fakeRepo = _FakeLocalMatchRepository([finishedMatch]);

      final container = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localMatchRepositoryProvider.overrideWithValue(fakeRepo),
          syncEngineProvider.overrideWithValue(_FakeSyncEngine()),
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

      final confirmBtn = find.text('確定・部内戦ホームへ');
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('無限稽古: 次の試合'), findsOneWidget);
      expect(find.text('挑戦(白): 選手C'), findsOneWidget);
      expect(find.text('無限稽古を終了'), findsOneWidget);
      expect(find.text('すぐに次の試合を開始'), findsOneWidget);
    });
  });
}
