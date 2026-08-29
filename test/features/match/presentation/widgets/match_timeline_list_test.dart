import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show tournamentProvider;
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';

import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

class FakeSyncEngine implements SyncEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class FakeMatchRepository implements MatchRepository {
  @override
  Future<void> deleteMatch(String matchId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalMatchRepository implements LocalMatchRepository {
  @override
  Future<void> deleteMatch(String matchId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePlayerRepository implements PlayerRepository {
  final List<PlayerModel> players;
  FakePlayerRepository(this.players);

  @override
  Stream<List<PlayerModel>> getPlayers({String organization = ''}) {
    return Stream.value(players);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMatchApplicationService implements MatchApplicationService {
  List<MatchModel>? savedMatches;
  @override
  Future<void> saveMatchesBulk(List<MatchModel> matches) async {
    savedMatches = matches;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MatchModel createMockMatch({
  required String id,
  required String category,
  required String groupName,
  required String matchType,
  required double order,
  bool isKachinuki = false,
  String note = '',
  String redName = '赤',
  String whiteName = '白',
}) {
  return MatchModel(
    id: id,
    tournamentId: 't1',
    category: category,
    groupName: groupName,
    redName: redName,
    whiteName: whiteName,
    matchType: matchType,
    order: order,
    isKachinuki: isKachinuki,
    note: note,
    rule: MatchRule(
      isLeague: note.contains('[リーグ戦]'),
      isKachinuki: isKachinuki,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeMatchApplicationService fakeMatchAppService;

  setUp(() {
    fakeMatchAppService = FakeMatchApplicationService();
  });

  Widget buildTestableWidget(
    List<MatchModel> matches, {
    List<String> customTeamNames = const [],
    List<PlayerModel> players = const [],
    Map<String, List<String>> teamPlayers = const {},
    bool isDark = false,
  }) {
    final themeData = ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      splashFactory: NoSplash.splashFactory, // ★ 追加: テスト時のInkSparkleエラーを回避
      extensions: [AppThemeColors.ofMode(isDark: isDark, mode: 'normal')],
    );

    return ProviderScope(
      overrides: [
        // ★ 修正: MatchTimelineListが依存する `matchListByTournamentProvider` をオーバーライドし、Isarへの依存を断ち切る
        matchListProvider.overrideWith((ref) => matches),
        matchListByTournamentProvider.overrideWith(
          (ref, id) => Stream.value(matches),
        ),
        matchApplicationServiceProvider.overrideWithValue(fakeMatchAppService),
        matchRepositoryProvider.overrideWithValue(FakeMatchRepository()),
        localMatchRepositoryProvider.overrideWithValue(
          FakeLocalMatchRepository(),
        ),
        playerRepositoryProvider.overrideWithValue(
          FakePlayerRepository(players),
        ),
        syncEngineProvider.overrideWith((ref) => FakeSyncEngine()),
        permissionProvider.overrideWith(
          (ref) => const AppPermissions(
            canCreateMatch: true,
            canManageTournament: true,
            isReadOnly: false,
            canChangeSettings: true,
            canDeleteData: true,
          ),
        ),
        commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
        tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
        isarProvider.overrideWithValue(null), // ★ Isar未初期化エラーを解決
        customTeamNamesProvider.overrideWith(
          (ref) => Stream.value(customTeamNames),
        ),
        registeredTeamsProvider.overrideWith((ref, id) {
          final teams = customTeamNames
              .map(
                (name) => TeamModel(
                  id: 't_$name',
                  tournamentId: id,
                  category: '一般',
                  teamName: name,
                  matchType: '団体戦（5人制）',
                  playerNames: teamPlayers[name] ?? const [],
                ),
              )
              .toList();
          return Stream.value(teams);
        }),
        searchQueryProvider.overrideWith((ref) => ''),
        isSearchVisibleProvider.overrideWith((ref) => false),
      ],
      child: MaterialApp(
        theme: themeData,
        home: const Scaffold(body: MatchTimelineList(tournamentId: 't1')),
      ),
    );
  }

  group('MatchTimelineList Sorting Tests', () {
    testWidgets('1. 個人戦の並び替え (_onReorderInnerTimeline)', (
      WidgetTester tester,
    ) async {
      // 抽出された個別試合アコーディオン（個人戦）に入る
      final matches = [
        createMockMatch(
          id: 'm1',
          category: '一般',
          groupName: '',
          matchType: '選手',
          order: 10.0,
          redName: '選手A',
          whiteName: '選手B',
        ),
        createMockMatch(
          id: 'm2',
          category: '一般',
          groupName: '',
          matchType: '選手',
          order: 20.0,
          redName: '選手A',
          whiteName: '選手C',
        ),
        createMockMatch(
          id: 'm3',
          category: '一般',
          groupName: '',
          matchType: '選手',
          order: 30.0,
          redName: '選手A',
          whiteName: '選手D',
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(matches));
      await tester.pumpAndSettle();

      // Expand the ExpansionTile for the player name ('選手A')
      final expansionTileFinder = find.byType(ExpansionTile).first;
      await tester.ensureVisible(expansionTileFinder);
      await tester.tap(expansionTileFinder);
      await tester.pumpAndSettle();

      final innerListViewFinder = find
          .descendant(
            of: find.byType(ExpansionTile),
            matching: find.byType(ReorderableListView),
          )
          .first;
      final reorderableListView = tester.widget<ReorderableListView>(
        innerListViewFinder,
      );

      // 降順ソートにより index 0: m3(30.0), index 1: m2(20.0), index 2: m1(10.0) となる
      // Move index 2 (m1) to index 0
      reorderableListView.onReorderItem!(2, 0);
      await tester.pump();

      expect(fakeMatchAppService.savedMatches, isNotNull);
      expect(fakeMatchAppService.savedMatches!.first.id, 'm1');
      expect(
        fakeMatchAppService.savedMatches!.first.order,
        30.0 - 100.0,
      ); // newOrderBase: list.first(m3: 30.0) - 100.0
    });

    testWidgets('2. 団体戦の並び替え (_onReorderTimeline)', (
      WidgetTester tester,
    ) async {
      // 外側のReorderableListViewでの並び替え
      final matches = [
        createMockMatch(
          id: 'm1_1',
          category: '一般',
          groupName: 'group1',
          matchType: '先鋒',
          order: 10.0,
          redName: '赤',
          whiteName: '白',
        ),
        createMockMatch(
          id: 'm1_2',
          category: '一般',
          groupName: 'group1',
          matchType: '大将',
          order: 11.0,
          redName: '赤',
          whiteName: '白',
        ),
        createMockMatch(
          id: 'm2_1',
          category: '一般',
          groupName: 'group2',
          matchType: '先鋒',
          order: 20.0,
          redName: '赤',
          whiteName: '白',
        ),
        createMockMatch(
          id: 'm2_2',
          category: '一般',
          groupName: 'group2',
          matchType: '大将',
          order: 21.0,
          redName: '赤',
          whiteName: '白',
        ),
        createMockMatch(
          id: 'm3_1',
          category: '一般',
          groupName: 'group3',
          matchType: '先鋒',
          order: 30.0,
          redName: '赤',
          whiteName: '白',
        ),
        createMockMatch(
          id: 'm3_2',
          category: '一般',
          groupName: 'group3',
          matchType: '大将',
          order: 31.0,
          redName: '赤',
          whiteName: '白',
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(matches));
      await tester.pumpAndSettle();

      final listViews = tester
          .widgetList<ReorderableListView>(find.byType(ReorderableListView))
          .toList();
      expect(listViews.isNotEmpty, isTrue);
      final outerReorderable = listViews.first;

      // Move index 0 (group1) to the end
      outerReorderable.onReorderItem!(0, 2);
      await tester.pump();

      expect(fakeMatchAppService.savedMatches, isNotNull);
      expect(fakeMatchAppService.savedMatches!.first.id, 'm3_1');
      // newOrder = 10.0 + 100 = 110.0
      expect(fakeMatchAppService.savedMatches!.first.order, 110.0);
    });

    testWidgets('3. リーグ個人戦の並び替え (_onReorderInnerTimeline)', (
      WidgetTester tester,
    ) async {
      final matches = [
        createMockMatch(
          id: 'm1',
          category: '一般',
          groupName: 'league1',
          matchType: '選手',
          note: '[リーグ戦]',
          order: 10.0,
          redName: '赤',
          whiteName: '白1',
        ),
        createMockMatch(
          id: 'm2',
          category: '一般',
          groupName: 'league1',
          matchType: '選手',
          note: '[リーグ戦]',
          order: 20.0,
          redName: '赤',
          whiteName: '白2',
        ),
        createMockMatch(
          id: 'm3',
          category: '一般',
          groupName: 'league1',
          matchType: '選手',
          note: '[リーグ戦]',
          order: 30.0,
          redName: '赤',
          whiteName: '白3',
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(matches));
      await tester.pumpAndSettle();

      // ExpansionTile を展開する
      final expansionTile = find.byType(ExpansionTile).first;
      await tester.ensureVisible(expansionTile);
      await tester.tap(expansionTile);
      await tester.pumpAndSettle();

      final innerListViewFinder = find
          .descendant(
            of: find.byType(ExpansionTile),
            matching: find.byType(ReorderableListView),
          )
          .first;
      final innerReorderable = tester.widget<ReorderableListView>(
        innerListViewFinder,
      );

      // Move index 1 (m2) to index 0
      innerReorderable.onReorderItem!(1, 0);
      await tester.pump();

      expect(fakeMatchAppService.savedMatches, isNotNull);
      expect(fakeMatchAppService.savedMatches!.first.id, 'm2');
      expect(fakeMatchAppService.savedMatches!.first.order, 10.0 - 100.0);
    });

    testWidgets('4. リーグ団体戦の並び替え不可仕様の確認 (Column固定)', (
      WidgetTester tester,
    ) async {
      final matches = [
        createMockMatch(
          id: 'm1_1',
          category: '一般',
          groupName: 'league1',
          matchType: '先鋒',
          note: '[リーグ戦]',
          order: 10.0,
          redName: 'Aチーム: 赤',
          whiteName: 'Bチーム: 白',
        ),
        createMockMatch(
          id: 'm1_2',
          category: '一般',
          groupName: 'league1',
          matchType: '大将',
          note: '[リーグ戦]',
          order: 11.0,
          redName: 'Aチーム: 赤',
          whiteName: 'Bチーム: 白',
        ),
        createMockMatch(
          id: 'm2_1',
          category: '一般',
          groupName: 'league1',
          matchType: '先鋒',
          note: '[リーグ戦]',
          order: 20.0,
          redName: 'Cチーム: 赤',
          whiteName: 'Dチーム: 白',
        ),
        createMockMatch(
          id: 'm2_2',
          category: '一般',
          groupName: 'league1',
          matchType: '大将',
          note: '[リーグ戦]',
          order: 21.0,
          redName: 'Cチーム: 赤',
          whiteName: 'Dチーム: 白',
        ),
        createMockMatch(
          id: 'm3_1',
          category: '一般',
          groupName: 'league1',
          matchType: '先鋒',
          note: '[リーグ戦]',
          order: 30.0,
          redName: 'Eチーム: 赤',
          whiteName: 'Fチーム: 白',
        ),
        createMockMatch(
          id: 'm3_2',
          category: '一般',
          groupName: 'league1',
          matchType: '大将',
          note: '[リーグ戦]',
          order: 31.0,
          redName: 'Eチーム: 赤',
          whiteName: 'Fチーム: 白',
        ),
      ];

      // Aチームを自チームとして登録することで、同じleague1グループとして1つのタイムラインにまとめられる
      await tester.pumpWidget(
        buildTestableWidget(matches, customTeamNames: ['Aチーム']),
      );
      await tester.pumpAndSettle();

      // ExpansionTile を展開する
      final expansionTile = find.byType(ExpansionTile).first;
      await tester.ensureVisible(expansionTile);
      await tester.tap(expansionTile);
      await tester.pumpAndSettle();

      // ★ 団体戦およびリーグ団体戦では並び替えができない仕様（Column固定）になったため、ReorderableListView が存在しないことを確認する
      final innerListViewFinder = find.descendant(
        of: find.byType(ExpansionTile),
        matching: find.byType(ReorderableListView),
      );

      expect(innerListViewFinder, findsNothing);
    });
  });

  group('MatchTimelineList Grouping Tests (リーグ戦分割不具合の回帰テスト)', () {
    testWidgets('1. 自チームを含まないリーグ戦が分割されず、1つのグループにまとまること', (
      WidgetTester tester,
    ) async {
      final leagueMatches = [
        createMockMatch(
          id: 'league_a_1',
          category: '一般',
          groupName: '男子リーグA',
          matchType: 'リーグ戦',
          note: '[リーグ戦]',
          order: 10.0,
          redName: '赤龍館',
          whiteName: '青龍会',
        ),
        createMockMatch(
          id: 'league_a_2',
          category: '一般',
          groupName: '男子リーグA',
          matchType: 'リーグ戦',
          note: '[リーグ戦]',
          order: 20.0,
          redName: '赤龍館',
          whiteName: '緑道場',
        ),
        createMockMatch(
          id: 'league_a_3',
          category: '一般',
          groupName: '男子リーグA',
          matchType: 'リーグ戦',
          note: '[リーグ戦]',
          order: 30.0,
          redName: '青龍会',
          whiteName: '緑道場',
        ),
      ];

      // 自チーム設定が空の状態でウィジェットをビルド
      await tester.pumpWidget(
        buildTestableWidget(leagueMatches, customTeamNames: []),
      );
      await tester.pumpAndSettle();

      // リーグ戦全体でExpansionTileが1つだけ生成されることを確認
      // これが複数(findsWidgets)になると、不具合が再発していることを意味する
      expect(find.byType(ExpansionTile), findsOneWidget);

      // そのExpansionTileのタイトルが、リーグの最初のチーム名（代表チーム）になっていることを確認
      expect(find.text('赤龍館'), findsOneWidget);
      // 2番目以降のチーム名はヘッダーには出ないはず
      expect(find.text('青龍会'), findsNothing);
    });

    testWidgets('2. 自チームを含むリーグ戦が1つのグループにまとまること', (WidgetTester tester) async {
      final leagueMatches = [
        createMockMatch(
          id: 'league_a_1',
          category: '一般',
          groupName: '男子リーグA',
          matchType: 'リーグ戦',
          note: '[リーグ戦]',
          order: 10.0,
          redName: '赤龍館',
          whiteName: '青龍会',
        ),
        createMockMatch(
          id: 'league_a_2',
          category: '一般',
          groupName: '男子リーグA',
          matchType: 'リーグ戦',
          note: '[リーグ戦]',
          order: 20.0,
          redName: '赤龍館',
          whiteName: '緑道場',
        ),
        createMockMatch(
          id: 'league_a_3',
          category: '一般',
          groupName: '男子リーグA',
          matchType: 'リーグ戦',
          note: '[リーグ戦]',
          order: 30.0,
          redName: '青龍会',
          whiteName: '緑道場',
        ),
      ];

      // 「赤龍館」を自チームとして設定
      await tester.pumpWidget(
        buildTestableWidget(leagueMatches, customTeamNames: ['赤龍館']),
      );
      await tester.pumpAndSettle();

      // この場合も、リーグ戦全体でExpansionTileが1つだけであることを確認
      expect(find.byType(ExpansionTile), findsOneWidget);

      // そのExpansionTileのタイトルが、自チーム名になっていることを確認
      expect(find.text('赤龍館'), findsOneWidget);
    });

    testWidgets('3. リーグ団体戦終了時に同点の場合、決定戦の作成ダイアログと各選択肢（代表戦、再試合、何もしない）が表示されること', (
      WidgetTester tester,
    ) async {
      // 2チームが完全に引き分けた対戦データを作成
      final leagueMatches = [
        MatchModel(
          id: 'm1',
          tournamentId: 't1',
          category: '一般',
          groupName: '男子リーグA',
          matchType: 'リーグ戦',
          note: '[リーグ戦]',
          order: 10.0,
          redName: '赤龍館 : 先鋒',
          whiteName: '青龍会 : 先鋒',
          status: 'finished',
          redScore: 2,
          whiteScore: 1,
          rule: const MatchRule(
            isLeague: true,
            winPoint: 1.0,
            lossPoint: 0.0,
            drawPoint: 0.5,
          ),
        ),
        MatchModel(
          id: 'm2',
          tournamentId: 't1',
          category: '一般',
          groupName: '男子リーグA',
          matchType: 'リーグ戦',
          note: '[リーグ戦]',
          order: 20.0,
          redName: '赤龍館 : 中堅',
          whiteName: '青龍会 : 中堅',
          status: 'finished',
          redScore: 1,
          whiteScore: 2,
          rule: const MatchRule(
            isLeague: true,
            winPoint: 1.0,
            lossPoint: 0.0,
            drawPoint: 0.5,
          ),
        ),
      ];

      // ビルドと描画
      await tester.pumpWidget(
        buildTestableWidget(leagueMatches, customTeamNames: []),
      );
      await tester.pumpAndSettle();

      // ExpansionTileを展開するためにタップする
      expect(find.byType(ExpansionTile), findsOneWidget);
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // 同点を解消するための「順位決定戦を作成」ボタンが表示されることを確認
      expect(find.text('順位決定戦を作成'), findsOneWidget);

      // ボタンをタップしてダイアログを開く
      await tester.tap(find.text('順位決定戦を作成'));
      await tester.pumpAndSettle();

      // ダイアログとその選択肢（代表戦、チーム再試合、何もしない）が表示されていることを確認
      expect(find.text('決定戦の形式を選択'), findsOneWidget);
      expect(find.text('代表戦（1名）'), findsOneWidget);
      expect(find.text('チーム再試合'), findsOneWidget);
      expect(find.text('何もしない'), findsOneWidget);

      // 「何もしない」をタップしてダイアログを閉じる
      await tester.tap(find.text('何もしない'));
      await tester.pumpAndSettle();

      // ダイアログが消えたことを確認
      expect(find.text('決定戦の形式を選択'), findsNothing);
    });

    testWidgets('3. 団体戦のオーダー直前変更（ドラッグ＆ドロップ・控え選手交代）', (
      WidgetTester tester,
    ) async {
      // 団体戦の試合データを作成
      final matches = [
        createMockMatch(
          id: 'm1_1',
          category: '団体戦A',
          groupName: 'group1',
          matchType: '先鋒',
          order: 1.0,
          redName: '白虎剣友会 : 山田 太郎',
          whiteName: '青龍道場 : 鈴木 一郎',
        ),
        createMockMatch(
          id: 'm1_2',
          category: '団体戦A',
          groupName: 'group1',
          matchType: '次鋒',
          order: 2.0,
          redName: '白虎剣友会 : 佐藤 次郎',
          whiteName: '青龍道場 : 田中 二郎',
        ),
      ];

      // 白虎剣友会 の所属選手名簿
      final players = <PlayerModel>[
        PlayerModel(
          id: 'p1',
          lastName: '山田',
          firstName: '太郎',
          lastNameKana: 'やまだ',
          firstNameKana: 'たろう',
          grade: 1,
          organization: '白虎剣友会',
        ),
        PlayerModel(
          id: 'p2',
          lastName: '佐藤',
          firstName: '次郎',
          lastNameKana: 'さとう',
          firstNameKana: 'じろう',
          grade: 1,
          organization: '白虎剣友会',
        ),
        PlayerModel(
          id: 'p3',
          lastName: '中村',
          firstName: '三郎',
          lastNameKana: 'なかむら',
          firstNameKana: 'さぶろう',
          grade: 1,
          organization: '白虎剣友会',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          matches,
          customTeamNames: const ['白虎剣友会'],
          players: players,
          teamPlayers: const {
            '白虎剣友会': ['山田 太郎', '佐藤 次郎', '中村 三郎'],
          },
        ),
      );
      await tester.pumpAndSettle();

      // ExpansionTileを展開するためにタップする
      expect(find.byType(ExpansionTile), findsOneWidget);
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // オーダー編集ボタン（IconButton）が表示されていることを確認
      final editButtonFinder = find.byTooltip('オーダー編集');
      expect(editButtonFinder, findsOneWidget);

      // オーダー編集ボタンをタップしてボトムシートを起動
      await tester.tap(editButtonFinder);
      await tester.pumpAndSettle();

      // ボトムシートが展開され、タイトルが表示されていることを確認
      expect(find.text('オーダー編集 : 白虎剣友会'), findsOneWidget);

      // ポジション（先鋒、次鋒）と控え選手が表示されていることを確認
      final listFinder = find.byType(ReorderableListView).last;
      expect(
        find.descendant(of: listFinder, matching: find.text('先鋒')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: listFinder, matching: find.text('次鋒')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: listFinder, matching: find.text('控え')),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.descendant(of: listFinder, matching: find.text('山田 太郎')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: listFinder, matching: find.text('佐藤 次郎')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: listFinder, matching: find.text('中村 三郎')),
        findsOneWidget,
      );

      // ReorderableListView の onReorderItem を直接呼び出して並べ替える
      final reorderListWidget = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView).last,
      );
      // 中村 三郎(控え、index: 2) を 山田 太郎(先鋒、index: 0) と交代させるため、index 2 を index 0 へ移動
      reorderListWidget.onReorderItem?.call(2, 0);
      await tester.pumpAndSettle();

      // 「オーダーを確定」ボタンをタップして保存
      final confirmButtonFinder = find.text('オーダーを確定');
      expect(confirmButtonFinder, findsOneWidget);
      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      // 保存結果をアサーション確認
      expect(fakeMatchAppService.savedMatches, isNotNull);
      expect(fakeMatchAppService.savedMatches!.length, 2);

      // 先鋒(id: m1_1) の赤側が 中村 三郎 に更新されていること
      final updatedFirstMatch = fakeMatchAppService.savedMatches!.firstWhere(
        (m) => m.id == 'm1_1',
      );
      expect(updatedFirstMatch.redName, '白虎剣友会 : 中村 三郎');

      // 次鋒(id: m1_2) の赤側は 山田 太郎
      final updatedSecondMatch = fakeMatchAppService.savedMatches!.firstWhere(
        (m) => m.id == 'm1_2',
      );
      expect(updatedSecondMatch.redName, '白虎剣友会 : 山田 太郎');
    });

    testWidgets('4. 団体戦のオーダー直前変更（マスタ外・助っ人手動追加）', (WidgetTester tester) async {
      // 団体戦の試合データを作成
      final matches = [
        createMockMatch(
          id: 'm1_1',
          category: '団体戦A',
          groupName: 'group1',
          matchType: '先鋒',
          order: 1.0,
          redName: '白虎剣友会 : 未定',
          whiteName: '青龍道場 : 鈴木 一郎',
        ),
        createMockMatch(
          id: 'm1_2',
          category: '団体戦A',
          groupName: 'group1',
          matchType: '次鋒',
          order: 2.0,
          redName: '白虎剣友会 : 未定',
          whiteName: '青龍道場 : 田中 二郎',
        ),
      ];

      // 所属選手名簿は空（マスタ外追加を検証するため）
      final players = <PlayerModel>[];

      await tester.pumpWidget(
        buildTestableWidget(
          matches,
          customTeamNames: ['白虎剣友会'],
          players: players,
        ),
      );
      await tester.pumpAndSettle();

      // ExpansionTileを展開するためにタップする
      expect(find.byType(ExpansionTile), findsOneWidget);
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // オーダー編集ボタン（IconButton）が表示されていることを確認
      final editButtonFinder = find.byTooltip('オーダー編集');
      expect(editButtonFinder, findsOneWidget);

      // オーダー編集ボタンをタップしてボトムシートを起動
      await tester.tap(editButtonFinder);
      await tester.pumpAndSettle();

      // ボトムシートが展開され、タイトルが表示されていることを確認
      expect(find.text('オーダー編集 : 白虎剣友会'), findsOneWidget);

      // 控えを追加ボタンをタップ
      final addReserveButtonFinder = find.text('控えを追加');
      expect(addReserveButtonFinder, findsOneWidget);
      await tester.tap(addReserveButtonFinder);
      await tester.pumpAndSettle();

      // ダイアログが表示されていることを確認
      expect(find.text('控え選手の追加'), findsOneWidget);
      expect(find.text('未出場の所属選手はいません。'), findsOneWidget);

      // TextFieldを見つけて助っ人の名前を入力
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, '助っ人 太郎');
      await tester.pumpAndSettle();

      // 「追加」ボタンをタップ
      final addButtonFinder = find.text('追加');
      expect(addButtonFinder, findsOneWidget);
      await tester.tap(addButtonFinder);
      await tester.pumpAndSettle();

      // ダイアログが閉じ、ボトムシートに「助っ人 太郎」が控え選手として表示されていることを確認
      expect(find.text('控え選手の追加'), findsNothing);

      final listFinder = find.byType(ReorderableListView);
      expect(
        find.descendant(of: listFinder, matching: find.text('助っ人 太郎')),
        findsOneWidget,
      );

      // ReorderableListView の onReorderItem を直接呼び出して並べ替える
      final reorderListWidget = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView).last,
      );
      // 助っ人 太郎(控え、index: 2) を 未定(先鋒、index: 0) と交代させるため、index 2 を index 0 へ移動
      reorderListWidget.onReorderItem?.call(2, 0);
      await tester.pumpAndSettle();

      // 「オーダーを確定」ボタンをタップして保存
      final confirmButtonFinder = find.text('オーダーを確定');
      expect(confirmButtonFinder, findsOneWidget);
      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      // 保存結果をアサーション確認
      expect(fakeMatchAppService.savedMatches, isNotNull);
      expect(fakeMatchAppService.savedMatches!.length, 2);

      // 先鋒(id: m1_1) の赤側が 助っ人 太郎 に更新されていること
      final updatedFirstMatch = fakeMatchAppService.savedMatches!.firstWhere(
        (m) => m.id == 'm1_1',
      );
      expect(updatedFirstMatch.redName, '白虎剣友会 : 助っ人 太郎');
    });

    testWidgets('5. 団体戦のオーダー直前変更ボトムシートのデザイン整合性検証', (WidgetTester tester) async {
      // 団体戦の試合データを作成
      final matches = [
        createMockMatch(
          id: 'm1_1',
          category: '団体戦A',
          groupName: 'group1',
          matchType: '先鋒',
          order: 1.0,
          redName: '白虎剣友会 : 山田 太郎',
          whiteName: '青龍道場 : 鈴木 一郎',
        ),
        createMockMatch(
          id: 'm1_2',
          category: '団体戦A',
          groupName: 'group1',
          matchType: '次鋒',
          order: 2.0,
          redName: '白虎剣友会 : 佐藤 次郎',
          whiteName: '青龍道場 : 田中 二郎',
        ),
      ];

      final players = <PlayerModel>[
        PlayerModel(
          id: 'p1',
          lastName: '山田',
          firstName: '太郎',
          lastNameKana: 'やまだ',
          firstNameKana: 'たろう',
          grade: 1,
          organization: '白虎剣友会',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          matches,
          customTeamNames: ['白虎剣友会'],
          players: players,
        ),
      );
      await tester.pumpAndSettle();

      // ExpansionTileを展開
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // オーダー編集ボタンをタップしてボトムシートを起動
      await tester.tap(find.byTooltip('オーダー編集'));
      await tester.pumpAndSettle();

      // 1. ボトムシート全体の AppBottomSheetContent または Container を検証
      expect(find.text('オーダー編集 : 白虎剣友会'), findsOneWidget);

      // 2. ドラッグ用つまみ (幅36, 高さ5, capsule) の検証
      final handleFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.constraints != null) {
          final constraints = widget.constraints!;
          if (constraints.minWidth == 36 && constraints.minHeight == 5) {
            return true;
          }
        }
        return false;
      });
      expect(handleFinder, findsOneWidget);

      // 3. タイトルの検証 (semiBold)
      final titleTextFinder = find.text('オーダー編集 : 白虎剣友会');
      expect(titleTextFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(titleTextFinder);
      expect(textWidget.style?.fontWeight, AppFontWeight.semiBold);
    });

    testWidgets('5. ルール一括変更ボタンタップ時の動作検証', (WidgetTester tester) async {
      final matches = [
        createMockMatch(
          id: 'm1',
          category: '一般',
          groupName: 'チームA vs チームB',
          matchType: '先鋒',
          order: 10.0,
          redName: 'チームA:選手1',
          whiteName: 'チームB:選手2',
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(matches));
      await tester.pumpAndSettle();

      // Find the 'ルール一括変更' button and tap it
      final bulkEditBtn = find.text('ルール一括変更');
      expect(bulkEditBtn, findsOneWidget);
      await tester.tap(bulkEditBtn);
      await tester.pumpAndSettle();

      // Verify the sheet is displayed (contains header text)
      expect(find.text('⚙️ 試合ルールの一括変更'), findsOneWidget);

      // Verify that the team match is grouped and displayed correctly as 'チームA vs チームB'
      expect(find.text('[一般] チームA vs チームB'), findsOneWidget);

      // Tap apply button to verify it saves/calls the backend
      final applyBtn = find.text('選択した 1 件にルールを適用する');
      expect(applyBtn, findsOneWidget);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      // Verify SnackBar shown and sheet dismissed
      expect(find.text('1件の対戦ルールを一括変更しました。'), findsOneWidget);
      expect(find.text('⚙️ 試合ルールの一括変更'), findsNothing);
    });

    testWidgets(
      '6. matchCommandProvider.deleteMatch on Web preserves currentDojoIdProvider',
      (WidgetTester tester) async {
        debugIsWebOverride = true;
        addTearDown(() {
          debugIsWebOverride = false;
        });

        final matches = [
          createMockMatch(
            id: 'm1',
            category: '一般',
            groupName: '',
            matchType: '個人戦',
            order: 1.0,
            redName: '赤選手',
            whiteName: '白選手',
          ),
        ];

        await tester.pumpWidget(buildTestableWidget(matches));
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(MatchTimelineList));
        final container = ProviderScope.containerOf(element);

        // Verify initial dojo id state
        final initialDojoId = container.read(currentDojoIdProvider);

        // Execute deleteMatch via matchCommandProvider
        await container.read(matchCommandProvider).deleteMatch('m1');
        await tester.pumpAndSettle();

        // Verify that currentDojoIdProvider is preserved and NOT wiped to default_org
        expect(container.read(currentDojoIdProvider), equals(initialDojoId));
      },
    );

    testWidgets('7. 団体戦 vs 個人戦のヘッダーコメント表示＆ダークモード文字色視認性検証', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final teamMatch = createMockMatch(
        id: 'team_m1',
        category: '団体戦A',
        groupName: 'group1',
        matchType: '先鋒',
        order: 1.0,
        note: '第1試合場, 2回戦 13時開始',
        redName: '白虎剣友会 : 佐藤',
        whiteName: '青龍道場 : 田中',
      );

      final individualMatch = createMockMatch(
        id: 'indiv_m1',
        category: '個人戦B',
        groupName: '',
        matchType: '個人戦',
        order: 2.0,
        note: '第2試合場, 1回戦 14時開始',
        redName: '高橋',
        whiteName: '鈴木',
      );

      // 🌙 【ダークモード検証】
      await tester.pumpWidget(
        buildTestableWidget(
          [teamMatch, individualMatch],
          customTeamNames: ['白虎剣友会'],
          isDark: true,
        ),
      );
      await tester.pumpAndSettle();

      // 団体戦アコーディオンを展開
      await tester.tap(find.byType(ExpansionTile).at(0));
      await tester.pumpAndSettle();

      // 個人戦アコーディオンを展開
      await tester.tap(find.byType(ExpansionTile).at(1));
      await tester.pumpAndSettle();

      // 1. 団体戦子カードの検証:
      // 「第1試合場, 2回戦 13時開始」が子カードから削ぎ落とされ、【先鋒】のみが表示されること
      expect(find.textContaining('【先鋒】'), findsOneWidget);
      // 子カード内に「第1試合場, 2回戦 13時開始 【先鋒】」という結合テキストが存在しないこと
      expect(find.textContaining('第1試合場, 2回戦 13時開始 【先鋒】'), findsNothing);

      // 2. 個人戦カードの検証:
      // 「第2試合場, 1回戦 14時開始」がそのまま表示されること
      expect(find.textContaining('第2試合場, 1回戦 14時開始'), findsOneWidget);

      // 3. ダークモードでの文字色視認性検証:
      // 【先鋒】および個人戦コメントの RichText を取得し、テキストカラーが黒透過色 (0x8A000000) ではなく
      // context.appColors.subTextColor (ダークモード用ライトグレー) であることを確認
      final richTextsDark = tester.widgetList<RichText>(find.byType(RichText));
      bool checkedTeam = false;
      bool checkedIndiv = false;
      for (final rt in richTextsDark) {
        final span = rt.text;
        final plain = span.toPlainText();
        if (plain.contains('【先鋒】')) {
          expect(span.style?.color, isNot(equals(const Color(0x8A000000))));
          checkedTeam = true;
        }
        if (plain.contains('第2試合場, 1回戦 14時開始')) {
          expect(span.style?.color, isNot(equals(const Color(0x8A000000))));
          checkedIndiv = true;
        }
      }
      expect(checkedTeam, isTrue);
      expect(checkedIndiv, isTrue);
    });

    testWidgets('8. 団体戦 vs 個人戦のヘッダーコメント表示＆ライトモード文字色視認性検証', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final teamMatch = createMockMatch(
        id: 'team_m1',
        category: '団体戦A',
        groupName: 'group1',
        matchType: '先鋒',
        order: 1.0,
        note: '第1試合場, 2回戦 13時開始',
        redName: '白虎剣友会 : 佐藤',
        whiteName: '青龍道場 : 田中',
      );

      final individualMatch = createMockMatch(
        id: 'indiv_m1',
        category: '個人戦B',
        groupName: '',
        matchType: '個人戦',
        order: 2.0,
        note: '第2試合場, 1回戦 14時開始',
        redName: '高橋',
        whiteName: '鈴木',
      );

      // ☀️ 【ライトモード検証】
      await tester.pumpWidget(
        buildTestableWidget(
          [teamMatch, individualMatch],
          customTeamNames: ['白虎剣友会'],
          isDark: false,
        ),
      );
      await tester.pumpAndSettle();

      // 団体戦・個人戦アコーディオンを展開
      await tester.tap(find.byType(ExpansionTile).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExpansionTile).at(1));
      await tester.pumpAndSettle();

      expect(find.textContaining('【先鋒】'), findsOneWidget);
      expect(find.textContaining('第2試合場, 1回戦 14時開始'), findsOneWidget);

      // ライトモードでの文字色視認性検証
      final richTextsLight = tester.widgetList<RichText>(find.byType(RichText));
      bool checkedTeamLight = false;
      bool checkedIndivLight = false;
      for (final rt in richTextsLight) {
        final span = rt.text;
        final plain = span.toPlainText();
        if (plain.contains('【先鋒】')) {
          expect(span.style?.color, isNotNull);
          checkedTeamLight = true;
        }
        if (plain.contains('第2試合場, 1回戦 14時開始')) {
          expect(span.style?.color, isNotNull);
          checkedIndivLight = true;
        }
      }
      expect(checkedTeamLight, isTrue);
      expect(checkedIndivLight, isTrue);
    });

    testWidgets(
      '15. 【視認性保証テスト】MatchListTileCard の中央スコアセパレーター（ー）および引き分けマーク（✕）が黒潰れ(0x8A000000)せず、高コントラストな subTextColor で描画されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final scoreMatch = MatchModel(
          id: 'match_score_dash',
          tournamentId: 't1',
          category: '一般の部',
          groupName: '',
          order: 1.0,
          redName: '道上剣友会 : 塚本 大道',
          whiteName: '相手02 : 選手',
          matchType: '個人戦',
          status: 'finished',
          redScore: 1,
          whiteScore: 2,
          events: [
            ScoreEvent(
              id: 'ev1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: DateTime.now(),
            ),
            ScoreEvent(
              id: 'ev2',
              side: Side.white,
              strikeType: StrikeType.kote,
              isIppon: true,
              timestamp: DateTime.now(),
            ),
            ScoreEvent(
              id: 'ev3',
              side: Side.white,
              strikeType: StrikeType.kote,
              isIppon: true,
              timestamp: DateTime.now(),
            ),
          ],
        );

        final drawMatch = MatchModel(
          id: 'match_draw_cross',
          tournamentId: 't1',
          category: '一般の部',
          groupName: '',
          order: 2.0,
          redName: '道上剣友会 : 久安 智也',
          whiteName: '相手02 : 選手',
          matchType: '個人戦',
          status: 'finished',
          redScore: 0,
          whiteScore: 0,
          events: [],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              matchListProvider.overrideWith((ref) => [scoreMatch, drawMatch]),
              customTeamNamesProvider.overrideWith(
                (ref) => Stream.value(['道上剣友会']),
              ),
              permissionProvider.overrideWith(
                (ref) => const PermissionState(
                  isReadOnly: false,
                  canManageTournament: true,
                ),
              ),
            ],
            child: MaterialApp(
              themeMode: ThemeMode.dark,
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                extensions: [
                  AppThemeColors.ofMode(isDark: true, mode: 'normal'),
                ],
              ),
              home: Scaffold(
                body: Column(
                  children: [
                    MatchListTileCard(initialMatch: scoreMatch),
                    MatchListTileCard(initialMatch: drawMatch),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. スコアがある試合のハイフン「ー」が表示され、黒潰れしていないこと
        expect(find.text('ー'), findsOneWidget);
        final dashText = tester.widget<Text>(find.text('ー'));
        expect(dashText.style?.color, isNot(equals(const Color(0x8A000000))));

        // 2. 引き分けの試合のクロス「×」が表示され、黒潰れしていないこと
        expect(find.text('×'), findsOneWidget);
        final crossText = tester.widget<Text>(find.text('×'));
        expect(crossText.style?.color, isNot(equals(const Color(0x8A000000))));
      },
    );
  });
}
