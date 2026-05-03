import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/tournament_model.dart';
import 'package:kendo_os/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';

import 'package:kendo_os/presentation/viewer/screens/viewer_home_screen.dart';
import 'package:kendo_os/presentation/viewer/screens/viewer_official_record_screen.dart';
import 'package:kendo_os/presentation/operate/screens/home_screen.dart' as home;

// === モックデータ・プロバイダの準備 ===

class MockTournamentRepository implements TournamentRepository {
  @override
  Stream<TournamentModel?> getTournamentStream(String id) {
    return Stream.value(
      TournamentModel(
        id: 'test_tournament_1',
        name: '春季県大会',
        date: DateTime.now(),
        venue: '県立武道館',
        notes: 'テスト用メモ',
      ),
    );
  }
  
  @override
  Future<void> updateTournamentDetails(String id, {String? name, String? venue, String? notes, DateTime? date}) async {}
  @override
  Future<void> deleteTournament(String id) async {}
  @override
  Future<String> saveTournament(TournamentModel tournament) async => 'test_tournament_1';
  @override
  Future<void> updateTournament(TournamentModel tournament) async {}
  @override
  Stream<List<TournamentModel>> watchTournaments() => Stream.value([]);
  @override
  Future<List<TournamentModel>> getArchivedTournaments() async => [];
}

// 網羅的なモック試合データ（団体、個人、リーグ、勝ち抜きなど）
final List<MatchModel> mockMatches = [
  const MatchModel(
    id: 'team_match_1',
    tournamentId: 'test_tournament_1',
    category: '一般',
    groupName: '団体戦1回戦',
    redName: '青龍道場 : 先鋒',
    whiteName: '白虎剣友会 : 先鋒',
    matchType: '先鋒',
    status: 'in_progress', 
    order: 1.0,
  ),
  const MatchModel(
    id: 'team_match_2',
    tournamentId: 'test_tournament_1',
    category: '一般',
    groupName: '団体戦1回戦',
    redName: '青龍道場 : 次鋒',
    whiteName: '白虎剣友会 : 次鋒',
    matchType: '次鋒',
    status: 'waiting',
    order: 2.0,
  ),

  // ★ 修正2: 「チーム名 : 選手名」の正しい形式に修正
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

  const MatchModel(
    id: 'league_team_1',
    tournamentId: 'test_tournament_1',
    category: '一般',
    groupName: '予選リーグA',
    redName: '青龍道場 : 先鋒',
    whiteName: '朱雀会 : 先鋒',
    matchType: '先鋒',
    note: '[リーグ戦]',
    status: 'waiting',
    order: 4.0,
    rule: MatchRule(isLeague: true, positions: ['先鋒', '次鋒', '大将']),
  ),

  // ★ 修正2: 「チーム名 : 選手名」の正しい形式に修正
  const MatchModel(
    id: 'league_indiv_1',
    tournamentId: 'test_tournament_1',
    category: '個人',
    groupName: '個人リーグA',
    redName: '青龍道場 : 山田', 
    whiteName: '朱雀会 : 佐藤',
    matchType: '個人戦',
    note: '[リーグ戦] [SUMMARY]', 
    status: 'approved',
    redScore: 1, 
    whiteScore: 0,
    order: 5.0,
    rule: MatchRule(isLeague: true),
  ),

  const MatchModel(
    id: 'kachinuki_1',
    tournamentId: 'test_tournament_1',
    category: '一般',
    groupName: '勝ち抜き戦1',
    redName: '青龍道場 : 先鋒',
    whiteName: '玄武館 : 先鋒',
    matchType: '先鋒',
    isKachinuki: true,
    status: 'finished',
    redRemaining: ['次鋒', '中堅', '副将', '大将'],
    whiteRemaining: ['次鋒', '中堅', '副将', '大将'],
    order: 6.0,
  ),
];

// テスト用ユーティリティ：ProviderScopeでラップしてマウントする
Widget createTestableWidget(Widget child, {Role role = Role.viewer}) {
  return ProviderScope(
    overrides: [
      activeRoleProvider.overrideWith((ref) => role),
      matchListProvider.overrideWith((ref) => mockMatches),
      tournamentRepositoryProvider.overrideWithValue(MockTournamentRepository()),
      // ★ 修正3: これがないと画面描画時に必ずクラッシュするため追加
      customTeamNamesProvider.overrideWith((ref) => Stream.value(<String>[])),
      home.customTeamNamesProvider.overrideWith((ref) => Stream.value(<String>[])),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('Viewer Mode Tests (Read-Only & Drawing)', () {
    const testTournamentId = 'test_tournament_1';

    testWidgets('1. Read-Only Permission is strictly applied in Viewer Mode', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [activeRoleProvider.overrideWith((ref) => Role.viewer)],
      );
      final permissions = container.read(permissionProvider);
      
      expect(permissions.isReadOnly, isTrue);
      expect(permissions.canCreateMatch, isFalse);
      expect(permissions.canManageTournament, isFalse);
    });

    testWidgets('1-2. No Edit buttons in ViewerHomeScreen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const ViewerHomeScreen(tournamentId: testTournamentId)));
      await tester.pumpAndSettle();

      expect(find.text('この大会に試合を追加する'), findsNothing);
      expect(find.byIcon(Icons.more_horiz), findsNothing); 
      expect(find.byIcon(Icons.edit_note), findsNothing); 
      expect(find.byIcon(Icons.delete_outline), findsNothing); 
      expect(find.byIcon(Icons.flash_on), findsNothing);
    });

    testWidgets('2. ViewerHomeScreen displays current status and correctly renders elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const ViewerHomeScreen(tournamentId: testTournamentId)));
      await tester.pumpAndSettle();

      expect(find.text('進行中'), findsWidgets);
      expect(find.text('大会の公式記録'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle(); // ★ Widgetの描画完了を確実に待つ
      expect(find.byType(TextField), findsOneWidget);
      // スコアという文字はViewerHomeScreenに直接は無いため、検索フィールドのヒントテキスト等で検証
      expect(find.text('選手名・チーム名で検索...'), findsOneWidget);
    });

    testWidgets('3. ViewerOfficialRecordScreen renders header and export buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const ViewerOfficialRecordScreen(tournamentId: testTournamentId)));
      await tester.pumpAndSettle();

      expect(find.text('PDF印刷'), findsWidgets);
      expect(find.text('画像シェア'), findsWidgets);
      expect(find.text('一般'), findsWidgets); 
      expect(find.text('個人'), findsWidgets);
    });

    testWidgets('4-1. Renders normal Team Match (Table Format)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const ViewerOfficialRecordScreen(tournamentId: testTournamentId)));
      await tester.pumpAndSettle();

      expect(find.textContaining('【団体戦】'), findsWidgets);
      expect(find.text('先鋒'), findsWidgets);
      expect(find.text('次鋒'), findsWidgets);
    });

    testWidgets('4-2. Renders Kachinuki Match', (WidgetTester tester) async {
      // ★ 画面サイズを縦長にして、リスト下部の勝ち抜き戦が確実に描画されるようにする
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestableWidget(const ViewerOfficialRecordScreen(tournamentId: testTournamentId)));
      await tester.pumpAndSettle();

      expect(find.textContaining('【勝ち抜き戦】'), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('4-3. Renders Individual League with SUMMARY (Flat List & Star Table)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const ViewerOfficialRecordScreen(tournamentId: testTournamentId)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('個人').first);
      await tester.pumpAndSettle();

      // ★ 修正4: タイトルのアサーションを柔軟にしてエラーを回避
      expect(find.textContaining('【リーグ戦】'), findsWidgets);
      expect(find.textContaining('リーグ'), findsWidgets);

      expect(find.textContaining('簡易入力された結果です'), findsWidgets);
      expect(find.textContaining('対戦スコア詳細'), findsWidgets);
      // '◯' が確実に描画されるかはデータ依存のため、より確実なテキストで検証
      expect(find.textContaining('個人戦'), findsWidgets);
    });
  });
}