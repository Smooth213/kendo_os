import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart'
    hide bunaiksenMatchesProvider;
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    hide customTeamNamesProvider;

import 'package:kendo_os/shared/domain/repositories/projection_store.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_projection_store.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/application/projections/projection_store.dart'
    as app_store;

import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';

import 'package:kendo_os/features/viewer/providers/viewer_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

class MockTournamentRepository implements TournamentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<TournamentModel?> getTournamentStream(String id) {
    debugPrint('MOCK TOURNAMENT STREAM CALLED for ID: $id');
    return Stream.value(
      TournamentModel(
        id: 'test_tournament_1',
        organizationId: 'default_org',
        name: '春季県大会',
        date: DateTime.now(),
        venue: '県立武道館',
        notes: 'テスト用メモ',
        categories: const ['一般', '個人'],
      ),
    );
  }

  Future<TournamentModel?> getTournament(String id) async => TournamentModel(
    id: 'test_tournament_1',
    organizationId: 'default_org',
    name: '春季県大会',
    date: DateTime.now(),
    venue: '県立武道館',
    notes: 'テスト用メモ',
    categories: const ['一般', '個人'],
  );
}

class MockPlayerRepository implements PlayerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<List<String>> watchCustomTeamNames({String organization = '道上剣友会'}) =>
      Stream.value([]);
}

class MockMatchRepository implements MatchRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<List<MatchModel>> watchAllMatches() => Stream.value(mockMatches);
  @override
  Stream<List<MatchModel>> watchActiveMatches() => Stream.value([]);
  @override
  Future<List<MatchModel>> getStaticMatches() async => mockMatches;

  Stream<List<MatchModel>> watchMatchesByTournament(String tournamentId) =>
      Stream.value(mockMatches);
  Future<List<MatchModel>> getMatchesByTournament(String tournamentId) async =>
      mockMatches;
}

class MockLocalMatchRepository implements LocalMatchRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<List<MatchModel>> watchMatches() => Stream.value(mockMatches);
  @override
  Future<void> saveMatchesBulk(List<MatchModel> matches) async {}

  Stream<List<MatchModel>> watchMatchesByTournament(String tournamentId) =>
      Stream.value(mockMatches);
  Future<List<MatchModel>> getMatchesByTournament(String tournamentId) async =>
      mockMatches;
}

final List<MatchModel> mockMatches = [
  // 団体戦
  const MatchModel(
    id: 'team_match_1',
    tournamentId: 'test_tournament_1',
    category: '一般',
    groupName: '団体戦A',
    redName: '青龍道場 : 先鋒',
    whiteName: '白虎剣友会 : 先鋒',
    matchType: '先鋒',
    status: 'finished',
    redScore: 1,
    whiteScore: 0,
    order: 1.0,
    note: '[団体戦]',
  ),
  const MatchModel(
    id: 'team_match_2',
    tournamentId: 'test_tournament_1',
    category: '一般',
    groupName: '団体戦A',
    redName: '青龍道場 : 次鋒',
    whiteName: '白虎剣友会 : 次鋒',
    matchType: '次鋒',
    status: 'finished',
    redScore: 0,
    whiteScore: 0,
    order: 2.0,
    note: '[団体戦]',
  ),
  // 個人戦
  const MatchModel(
    id: 'indiv_match_1',
    tournamentId: 'test_tournament_1',
    category: '個人',
    redName: '青龍道場 : 山田',
    whiteName: '白虎剣友会 : 鈴木',
    matchType: '個人戦',
    status: 'finished',
    redScore: 2,
    whiteScore: 0,
    order: 3.0,
  ),
  // リーグ団体戦
  const MatchModel(
    id: 'league_team_1',
    tournamentId: 'test_tournament_1',
    category: '一般',
    groupName: '団体リーグA',
    redName: '青龍道場 : 先鋒',
    whiteName: '朱雀会 : 先鋒',
    matchType: '先鋒',
    note: '[リーグ戦] [SUMMARY]',
    status: 'approved',
    redScore: 1,
    whiteScore: 0,
    order: 4.0,
    rule: MatchRule(isLeague: true, positions: ['先鋒', '次鋒', '大将']),
  ),
  // リーグ個人戦
  const MatchModel(
    id: 'league_indiv_1',
    tournamentId: 'test_tournament_1',
    category: '個人',
    groupName: '個人リーグA',
    redName: '青龍道場 : 山田',
    whiteName: '朱雀会 : 佐藤',
    matchType: '選手',
    note: '[リーグ戦] [SUMMARY]',
    status: 'approved',
    redScore: 1,
    whiteScore: 0,
    order: 5.0,
    rule: MatchRule(isLeague: true),
  ),
  // 勝ち抜き戦
  const MatchModel(
    id: 'kachinuki_match_1',
    tournamentId: 'test_tournament_1',
    category: '一般',
    groupName: '勝ち抜き戦A',
    redName: '青龍道場 : 先鋒',
    whiteName: '玄武館 : 先鋒',
    matchType: '勝ち抜き戦',
    isKachinuki: true,
    status: 'finished',
    redRemaining: ['次鋒', '中堅', '副将', '大将'],
    whiteRemaining: ['次鋒', '中堅', '副将', '大将'],
    order: 6.0,
    note: '[勝ち抜き戦]',
    redScore: 0,
    whiteScore: 0,
  ),
];

class MockProjectionStore implements ProjectionStore {
  final List<MatchProjection> projections;
  final List<MatchModel> originalMatches;

  MockProjectionStore(this.projections, this.originalMatches);

  @override
  Future<void> save(MatchProjection projection) async {}

  @override
  Future<MatchProjection?> get(String matchId) async {
    return projections.where((p) => p.id == matchId).firstOrNull;
  }

  @override
  Stream<MatchProjection> watch(String matchId) {
    final p = projections.where((proj) => proj.id == matchId).firstOrNull;
    if (p != null) return Stream.value(p);
    return const Stream.empty();
  }

  @override
  Stream<List<MatchListProjection>> watchByTournament(String tournamentId) {
    final list = originalMatches
        .where((m) => m.tournamentId == tournamentId)
        .map((m) {
          final p = projections.firstWhere((proj) => proj.id == m.id);
          return MatchListProjection(
            id: p.id,
            tournamentId: p.tournamentId,
            matchOrder: p.matchOrder,
            matchType: p.matchType,
            status: p.status,
            redName: p.redName,
            whiteName: p.whiteName,
            redScore: p.redScore,
            whiteScore: p.whiteScore,
            groupName: p.groupName,
            isKachinuki: p.isKachinuki,
            note: p.note,
            firstPointSide: p.firstPointSide,
            redPointMarks: p.redPointMarks,
            whitePointMarks: p.whitePointMarks,
          );
        })
        .toList();
    return Stream.value(list);
  }
}

class MockAppProjectionStore implements app_store.ProjectionStore {
  final List<MatchProjection> projections;
  final List<MatchModel> originalMatches;

  MockAppProjectionStore(this.projections, this.originalMatches);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<MatchProjection?> watch(String matchId) {
    final p = projections.where((proj) => proj.id == matchId).firstOrNull;
    if (p != null) return Stream.value(p);
    return const Stream.empty();
  }

  @override
  Stream<List<MatchListProjection>> watchByTournament(String tournamentId) {
    final list = originalMatches
        .where((m) => m.tournamentId == tournamentId)
        .map((m) {
          final p = projections.firstWhere((proj) => proj.id == m.id);
          return MatchListProjection(
            id: p.id,
            tournamentId: p.tournamentId,
            matchOrder: p.matchOrder,
            matchType: p.matchType,
            status: p.status,
            redName: p.redName,
            whiteName: p.whiteName,
            redScore: p.redScore,
            whiteScore: p.whiteScore,
            groupName: p.groupName,
            isKachinuki: p.isKachinuki,
            note: p.note,
            firstPointSide: p.firstPointSide,
            redPointMarks: p.redPointMarks,
            whitePointMarks: p.whitePointMarks,
          );
        })
        .toList();
    return Stream.value(list);
  }
}

Widget createTestableWidget(
  Widget child, {
  Role role = Role.viewer,
  List<Override> overrides = const [],
}) {
  final mockProjections = mockMatches.map((m) {
    final proj = MatchProjection(
      id: m.id,
      tournamentId: m.tournamentId ?? '',
      matchOrder: m.order.toInt(),
      matchType: m.matchType,
      status: m.status,
      groupName: m.groupName ?? '',
      isKachinuki: m.isKachinuki || (m.rule?.isKachinuki ?? false),
      redName: m.redName,
      whiteName: m.whiteName,
      redRemaining: m.redRemaining,
      whiteRemaining: m.whiteRemaining,
      redScore: m.redScore,
      whiteScore: m.whiteScore,
      redDisplays: const [],
      whiteDisplays: const [],
      firstPointSide: '',
      redPointMarks: const [],
      whitePointMarks: const [],
      remainingSeconds: m.calculateRemainingSeconds(SystemTimeSource().now()),
      timerIsRunning: m.timerIsRunning,
      note: m.note,
    );
    return proj;
  }).toList();

  final router = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (context, state) => child)],
  );

  return ProviderScope(
    overrides: [
      activeRoleProvider.overrideWith((ref) => role),
      matchListProvider.overrideWithValue(mockMatches),
      matchListByTournamentProvider.overrideWith(
        (ref, tournamentId) => Stream.value(mockMatches),
      ),
      isarProvider.overrideWithValue(null),
      matchStreamProvider.overrideWith((ref) => Stream.value(mockMatches)),
      playerRepositoryProvider.overrideWithValue(MockPlayerRepository()),
      matchRepositoryProvider.overrideWithValue(MockMatchRepository()),
      localMatchRepositoryProvider.overrideWithValue(
        MockLocalMatchRepository(),
      ),
      bunaiksenMatchesProvider.overrideWith(
        (ref, id) => Stream.value(mockMatches),
      ),
      tournamentRepositoryProvider.overrideWithValue(
        MockTournamentRepository(),
      ),
      projectionStoreProvider.overrideWithValue(
        MockProjectionStore(mockProjections, mockMatches),
      ),
      app_store.projectionStoreProvider.overrideWithValue(
        MockAppProjectionStore(mockProjections, mockMatches),
      ),
      customTeamNamesProvider.overrideWith(
        (ref) => Stream.value(<String>['青龍道場', '白虎剣友会']),
      ),
      tournamentProvider.overrideWith(
        (ref, id) => Stream.value(
          TournamentModel(
            id: 'test_tournament_1',
            organizationId: 'default_org',
            name: '春季県大会',
            date: DateTime.now(),
            venue: '県立武道館',
            notes: 'テスト用メモ',
            categories: const ['一般', '個人'],
          ),
        ),
      ),
      viewerTournamentProvider.overrideWith(
        (ref, id) => Stream.value(
          TournamentModel(
            id: 'test_tournament_1',
            organizationId: 'default_org',
            name: '春季県大会',
            date: DateTime.now(),
            venue: '県立武道館',
            notes: 'テスト用メモ',
            categories: const ['一般', '個人'],
          ),
        ),
      ),
      firestoreRoleStreamProvider.overrideWith(
        (ref) => Stream.value(UserRole.viewer),
      ),
      currentUserRoleProvider.overrideWith((ref) => UserRole.viewer),
      currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
      dojoRoomSyncProvider.overrideWith((ref) {}),
      settingsProvider.overrideWith(() => MockSettingsNotifier()),
      commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
      matchViewStateUserIdProvider.overrideWith((ref) => 'test_user_id'),
      ...overrides,
    ],
    child: MaterialApp.router(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      routerConfig: router,
    ),
  );
}

void main() {
  group('ViewerHomeScreen Accordion Grouping Tests', () {
    testWidgets(
      'Verify proper grouping/accordion display in ViewerHomeScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestableWidget(
            const ViewerHomeScreen(tournamentId: 'test_tournament_1'),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // Verify category headings
        expect(find.text('一般'), findsWidgets);
        expect(find.text('個人'), findsWidgets);

        // Verify group headers/representatives are shown
        final groupTitleFinder = find.byKey(const PageStorageKey('group_団体戦A'));
        await tester.ensureVisible(groupTitleFinder.first);
        await tester.pumpAndSettle();

        // Expand "団体戦A" group accordion
        await tester.tap(groupTitleFinder.first);
        await tester.pumpAndSettle();

        // Now "白虎剣友会" and other inner widgets should be built and visible
        final opponentFinder = find.text('白虎剣友会');
        await tester.dragUntilVisible(
          opponentFinder.first,
          find.byType(ListView).first,
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
        expect(opponentFinder, findsWidgets);
        expect(find.text('[団体戦]'), findsWidgets);

        // Verify individual matches (single or in league)
        final player1Finder = find.text('山田');
        await tester.ensureVisible(player1Finder.first);
        await tester.pumpAndSettle();
        expect(player1Finder, findsWidgets);

        final player2Finder = find.text('鈴木');
        await tester.dragUntilVisible(
          player2Finder,
          find.byType(ListView).first,
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
        expect(player2Finder, findsWidgets);
      },
    );

    testWidgets(
      'Verify own team is prioritized with styling without swapping left/right in ViewerHomeScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // customTeamNamesProviderを'白虎剣友会'のみに設定
        await tester.pumpWidget(
          createTestableWidget(
            const ViewerHomeScreen(tournamentId: 'test_tournament_1'),
            overrides: [
              customTeamNamesProvider.overrideWith(
                (ref) => Stream.value(<String>['白虎剣友会']),
              ),
            ],
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // 団体戦のヘッダーで、赤側の「青龍道場」と白側の「白虎剣友会」が元の順序（左右反転なし）で表示されていることを確認
        final groupKey = const PageStorageKey<String>('group_団体戦A');
        final leftTeamFinder = find.descendant(
          of: find.byKey(groupKey),
          matching: find.text('青龍道場'),
        );
        final rightTeamFinder = find.descendant(
          of: find.byKey(groupKey),
          matching: find.text('白虎剣友会'),
        );
        expect(leftTeamFinder, findsOneWidget);
        expect(rightTeamFinder, findsOneWidget);

        // x座標をチェックし、赤（青龍道場）が左側、白（白虎剣友会）が右側にある（スワップされていない）ことを保証
        final leftOffset = tester.getCenter(leftTeamFinder);
        final rightOffset = tester.getCenter(rightTeamFinder);
        expect(leftOffset.dx < rightOffset.dx, isTrue);

        // 自チーム（白虎剣友会）のみがイエローゴールド（Colors.amber.shade600）で強調され、青龍道場はそうではないことを確認
        final leftText = tester.widget<Text>(leftTeamFinder);
        final rightText = tester.widget<Text>(rightTeamFinder);
        expect(leftText.style?.color, isNot(Colors.amber.shade600));
        expect(rightText.style?.color, Colors.amber.shade600);

        // 個人戦で自チーム（白虎剣友会）の「鈴木」がアコーディオンヘッダー（playerName）として優先され、
        // かつ自チームではない「山田」はヘッダー名にならない（1つのアコーディオンキー「鈴木」のみが作成される）ことを検証
        final playerHeaderFinder = find.text('鈴木');
        expect(playerHeaderFinder, findsWidgets);

        // アコーディオンを展開
        await tester.tap(playerHeaderFinder.first);
        await tester.pumpAndSettle();

        // 展開後に、対戦相手の「山田」が表示されることを検証
        expect(find.text('山田'), findsWidgets);
      },
    );
  });
}
