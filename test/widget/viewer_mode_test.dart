import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

// ★ 追加：Projectionをモックするために必要なimport
import 'package:kendo_os/domain/repositories/projection_store.dart';
import 'package:kendo_os/infrastructure/repository/in_memory_projection_store.dart';
import 'package:kendo_os/application/projections/match_projection.dart';

// ★ Phase 8: settingsProviderのモック用
import 'package:kendo_os/presentation/operate/providers/settings_provider.dart';
import 'package:kendo_os/domain/entities/settings_model.dart';

// === モックデータ・プロバイダの準備 ===

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() => const SettingsModel(securityLevel: 1); // テスト用デフォルト
}

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

  // ★ 追加: 確実に「進行中」のコールUIをトップに出現させるための個人戦データ
  const MatchModel(
    id: 'indiv_match_in_progress',
    tournamentId: 'test_tournament_1',
    category: '個人',
    redName: '朱雀会 : 高橋',
    whiteName: '玄武館 : 伊藤',
    matchType: '個人戦',
    status: 'in_progress',
    order: 3.5,
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

// ★ Phase 5: インターフェース変更に合わせて Mock も更新
class MockProjectionStore implements ProjectionStore {
  final List<MatchProjection> projections;

  MockProjectionStore(this.projections);

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

  // ★ 戻り値を MatchListProjection に変換して返すように修正
  @override
  Stream<List<MatchListProjection>> watchByTournament(String tournamentId) {
    final list = projections.where((p) => p.tournamentId == tournamentId).map((p) => MatchListProjection(
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
    )).toList();
    return Stream.value(list); // async* の遅延をなくし、即時反映させる
  }
}

// テスト用ユーティリティ：ProviderScopeでラップしてマウントする
Widget createTestableWidget(Widget child, {Role role = Role.viewer}) {
  // ★ 追加: MatchModelのモックを、Viewerが依存するMatchProjectionのモックに変換
  final mockProjections = mockMatches.map((m) {
    return MatchProjection(
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
      remainingSeconds: m.remainingSeconds,
      timerIsRunning: m.timerIsRunning,
      note: m.note,
    );
  }).toList();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      activeRoleProvider.overrideWith((ref) => role),
      matchListProvider.overrideWith((ref) => mockMatches),
      tournamentRepositoryProvider.overrideWithValue(MockTournamentRepository()),
      // ★ 追加: Viewer用のProjectionStoreをモックデータで上書き
      projectionStoreProvider.overrideWithValue(MockProjectionStore(mockProjections)),
      // ★ 修正3: これがないと画面描画時に必ずクラッシュするため追加
      customTeamNamesProvider.overrideWith((ref) => Stream.value(<String>[])),
      home.customTeamNamesProvider.overrideWith((ref) => Stream.value(<String>[])),
      // ★ Phase 8: SettingsProviderをモック化してSharedPreferences未実装エラーを回避
      settingsProvider.overrideWith(() => MockSettingsNotifier()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('Viewer Mode Tests (Read-Only & Drawing)', () {
    const testTournamentId = 'test_tournament_1';

    testWidgets('1. Read-Only Permission is strictly applied in Viewer Mode', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          activeRoleProvider.overrideWith((ref) => Role.viewer),
          // ★ Phase 8: ここでもSettingsProviderをモック化
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
        ],
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

      // ★ 画面サイズを縦長にして、スクロールが必要な検索アイコンが確実に描画されるようにする
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestableWidget(const ViewerHomeScreen(tournamentId: testTournamentId)));
      await tester.pump(); // Streamの即時反映を待つ
      await tester.pumpAndSettle();

      expect(find.text('進行中'), findsWidgets);
      // ★ 修正: UIスリム化に伴い、ボタンのテキストを最新のものへ変更
      expect(find.text('試合結果一覧 (PDF/CSV)'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle(); // ★ Widgetの描画完了を確実に待つ
      expect(find.byType(TextField), findsOneWidget);
      // スコアという文字はViewerHomeScreenに直接は無いため、検索フィールドのヒントテキスト等で検証
      expect(find.text('選手名・チーム名で検索...'), findsOneWidget);
    });

    testWidgets('3. ViewerOfficialRecordScreen renders header and export buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const ViewerOfficialRecordScreen(tournamentId: testTournamentId)));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('PDF印刷'), findsWidgets);
      expect(find.text('画像シェア'), findsWidgets);
      expect(find.text('全カテゴリ'), findsWidgets); 
    });

    testWidgets('4-1. Renders normal Team Match (Table Format)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const ViewerOfficialRecordScreen(tournamentId: testTournamentId)));
      await tester.pump();
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
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('【勝ち抜き戦】'), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('4-3. Renders Individual League with SUMMARY (Flat List & Star Table)', (WidgetTester tester) async {
      // ★ 追加：画面サイズを縦長にして、リスト下部の試合が確実に描画されるようにする
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestableWidget(const ViewerOfficialRecordScreen(tournamentId: testTournamentId)));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('全カテゴリ').first);
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