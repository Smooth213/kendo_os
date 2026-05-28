import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/application/usecases/match_application_service.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/presentation/operate/screens/home_screen.dart' show tournamentProvider, customTeamNamesProvider, searchQueryProvider, isSearchVisibleProvider;
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';

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

  Widget buildTestableWidget(List<MatchModel> matches, {List<String> customTeamNames = const []}) {
    return ProviderScope(
      overrides: [
        // ★ 修正: MatchTimelineListが依存する `matchListByTournamentProvider` をオーバーライドし、Isarへの依存を断ち切る
        matchListByTournamentProvider.overrideWith((ref, id) => Stream.value(matches)),
        matchApplicationServiceProvider.overrideWithValue(fakeMatchAppService),
        permissionProvider.overrideWith((ref) => const AppPermissions(
          canCreateMatch: true, canManageTournament: true, isReadOnly: false, canChangeSettings: true, canDeleteData: true,
        )),
        commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
        tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
        isarProvider.overrideWithValue(null), // ★ Isar未初期化エラーを解決
        customTeamNamesProvider.overrideWith((ref) => Stream.value(customTeamNames)),
        searchQueryProvider.overrideWith((ref) => ''),
        isSearchVisibleProvider.overrideWith((ref) => false),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: MatchTimelineList(tournamentId: 't1'),
        ),
      ),
    );
  }
  
  group('MatchTimelineList Sorting Tests', () {

    testWidgets('1. 個人戦の並び替え (_onReorderInnerTimeline)', (WidgetTester tester) async {
      // 抽出された個別試合アコーディオン（個人戦）に入る
      final matches = [
        createMockMatch(id: 'm1', category: '一般', groupName: '', matchType: '選手', order: 10.0, redName: '選手A', whiteName: '選手B'),
        createMockMatch(id: 'm2', category: '一般', groupName: '', matchType: '選手', order: 20.0, redName: '選手A', whiteName: '選手C'),
        createMockMatch(id: 'm3', category: '一般', groupName: '', matchType: '選手', order: 30.0, redName: '選手A', whiteName: '選手D'),
      ];

      await tester.pumpWidget(buildTestableWidget(matches));
      await tester.pumpAndSettle();

      // Expand the ExpansionTile for the player name ('選手A')
      final expansionTileFinder = find.byType(ExpansionTile).first;
      await tester.ensureVisible(expansionTileFinder);
      await tester.tap(expansionTileFinder);
      await tester.pumpAndSettle();

      final innerListViewFinder = find.descendant(
        of: find.byType(ExpansionTile),
        matching: find.byType(ReorderableListView),
      ).first;
      final reorderableListView = tester.widget<ReorderableListView>(innerListViewFinder);
      
      // Move index 2 (m3) to index 0
      // ignore: invalid_null_aware_operator
      reorderableListView.onReorder?.call(2, 0);
      await tester.pump();

      expect(fakeMatchAppService.savedMatches, isNotNull);
      expect(fakeMatchAppService.savedMatches!.first.id, 'm3');
      expect(fakeMatchAppService.savedMatches!.first.order, 10.0 - 100.0); // newOrderBase
    });

    testWidgets('2. 団体戦の並び替え (_onReorderTimeline)', (WidgetTester tester) async {
      // 外側のReorderableListViewでの並び替え
      final matches = [
        createMockMatch(id: 'm1_1', category: '一般', groupName: 'group1', matchType: '先鋒', order: 10.0, redName: '赤', whiteName: '白'),
        createMockMatch(id: 'm1_2', category: '一般', groupName: 'group1', matchType: '大将', order: 11.0, redName: '赤', whiteName: '白'),
        createMockMatch(id: 'm2_1', category: '一般', groupName: 'group2', matchType: '先鋒', order: 20.0, redName: '赤', whiteName: '白'),
        createMockMatch(id: 'm2_2', category: '一般', groupName: 'group2', matchType: '大将', order: 21.0, redName: '赤', whiteName: '白'),
        createMockMatch(id: 'm3_1', category: '一般', groupName: 'group3', matchType: '先鋒', order: 30.0, redName: '赤', whiteName: '白'),
        createMockMatch(id: 'm3_2', category: '一般', groupName: 'group3', matchType: '大将', order: 31.0, redName: '赤', whiteName: '白'),
      ];

      await tester.pumpWidget(buildTestableWidget(matches));
      await tester.pumpAndSettle();

      final listViews = tester.widgetList<ReorderableListView>(find.byType(ReorderableListView)).toList();
      expect(listViews.isNotEmpty, isTrue);
      final outerReorderable = listViews.first;
      
      // Move index 0 (group1) to the end (index 3 passed by flutter drag framework)
      // ignore: invalid_null_aware_operator
      outerReorderable.onReorder?.call(0, 3);
      await tester.pump();

      expect(fakeMatchAppService.savedMatches, isNotNull);
      expect(fakeMatchAppService.savedMatches!.first.id, 'm1_1');
      // newOrder = 30.0 + 100 = 130.0
      expect(fakeMatchAppService.savedMatches!.first.order, 130.0);
    });

    testWidgets('3. リーグ個人戦の並び替え (_onReorderInnerTimeline)', (WidgetTester tester) async {
      final matches = [
        createMockMatch(id: 'm1', category: '一般', groupName: 'league1', matchType: '選手', note: '[リーグ戦]', order: 10.0, redName: '赤', whiteName: '白1'),
        createMockMatch(id: 'm2', category: '一般', groupName: 'league1', matchType: '選手', note: '[リーグ戦]', order: 20.0, redName: '赤', whiteName: '白2'),
        createMockMatch(id: 'm3', category: '一般', groupName: 'league1', matchType: '選手', note: '[リーグ戦]', order: 30.0, redName: '赤', whiteName: '白3'),
      ];

      await tester.pumpWidget(buildTestableWidget(matches));
      await tester.pumpAndSettle();

      // ExpansionTile を展開する
      final expansionTile = find.byType(ExpansionTile).first;
      await tester.ensureVisible(expansionTile);
      await tester.tap(expansionTile);
      await tester.pumpAndSettle();

      final innerListViewFinder = find.descendant(
        of: find.byType(ExpansionTile),
        matching: find.byType(ReorderableListView),
      ).first;
      final innerReorderable = tester.widget<ReorderableListView>(innerListViewFinder);
      
      // Move index 1 (m2) to index 0
      // ignore: invalid_null_aware_operator
      innerReorderable.onReorder?.call(1, 0);
      await tester.pump();

      expect(fakeMatchAppService.savedMatches, isNotNull);
      expect(fakeMatchAppService.savedMatches!.first.id, 'm2');
      expect(fakeMatchAppService.savedMatches!.first.order, 10.0 - 100.0);
    });

    testWidgets('4. リーグ団体戦の並び替え不可仕様の確認 (Column固定)', (WidgetTester tester) async {
      final matches = [
        createMockMatch(id: 'm1_1', category: '一般', groupName: 'league1', matchType: '先鋒', note: '[リーグ戦]', order: 10.0, redName: 'Aチーム: 赤', whiteName: 'Bチーム: 白'),
        createMockMatch(id: 'm1_2', category: '一般', groupName: 'league1', matchType: '大将', note: '[リーグ戦]', order: 11.0, redName: 'Aチーム: 赤', whiteName: 'Bチーム: 白'),
        createMockMatch(id: 'm2_1', category: '一般', groupName: 'league1', matchType: '先鋒', note: '[リーグ戦]', order: 20.0, redName: 'Cチーム: 赤', whiteName: 'Dチーム: 白'),
        createMockMatch(id: 'm2_2', category: '一般', groupName: 'league1', matchType: '大将', note: '[リーグ戦]', order: 21.0, redName: 'Cチーム: 赤', whiteName: 'Dチーム: 白'),
        createMockMatch(id: 'm3_1', category: '一般', groupName: 'league1', matchType: '先鋒', note: '[リーグ戦]', order: 30.0, redName: 'Eチーム: 赤', whiteName: 'Fチーム: 白'),
        createMockMatch(id: 'm3_2', category: '一般', groupName: 'league1', matchType: '大将', note: '[リーグ戦]', order: 31.0, redName: 'Eチーム: 赤', whiteName: 'Fチーム: 白'),
      ];

      // Aチームを自チームとして登録することで、同じleague1グループとして1つのタイムラインにまとめられる
      await tester.pumpWidget(buildTestableWidget(matches, customTeamNames: ['Aチーム']));
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
}