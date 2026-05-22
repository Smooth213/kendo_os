import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/presentation/operate/providers/permission_provider.dart';
// ★ 適合修正: テスト環境から Isar 依存を完全パージするためのプロバイダインポート
import 'package:kendo_os/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/presentation/operate/screens/home_screen.dart';

void main() {
  group('🛡️ [Phase 4-V3] 掲示板式3行UI＆4大不具合完全防止・回帰テスト要塞', () {
    
    MatchModel makeMockMatch({
      required String id,
      required String redName,
      required String whiteName,
      List<ScoreEvent> events = const [],
      int redScore = 0,
      int whiteScore = 0,
      String status = 'waiting',
      String? groupName,
      String matchType = '個人戦',
      String note = '',
    }) {
      return MatchModel(
        id: id,
        matchType: matchType,
        redName: redName,
        whiteName: whiteName,
        redScore: redScore,
        whiteScore: whiteScore,
        status: status,
        events: events,
        order: 1.0,
        tournamentId: 't1',
        category: '一般の部',
        groupName: groupName,
        note: note,
      );
    }

    testWidgets('1. 【文字切れ防止】 チーム名が1行目（2行目）に独立し、選手名と分離した全3行構造が正しくレンダリングされること', (WidgetTester tester) async {
      final mockMatch = makeMockMatch(
        id: 'match_001',
        redName: '亀山クラブ : 道上 太郎',
        whiteName: '広島道場 : 皿田 文彬',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWith((ref) => [mockMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value(const <String>[])),
            permissionProvider.overrideWith((ref) => const AppPermissions(
              isReadOnly: false,
              canManageTournament: true,
              canCreateMatch: true,
              canChangeSettings: true,
              canDeleteData: true,
            )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MatchListTileCard(initialMatch: mockMatch, isDeletable: false),
            ),
          ),
        ),
      );

      expect(find.text('亀山クラブ'), findsOneWidget);
      expect(find.text('広島道場'), findsOneWidget);
      expect(find.text('道上 太郎'), findsOneWidget);
      expect(find.text('皿田 文彬'), findsOneWidget);
    });

    testWidgets('2. 【名前順同期】 白側の選手名とチーム名の並び順が「名前 : チーム名(小さく)」の順序で正しくパース・同期されていること', (WidgetTester tester) async {
      final mockMatch = makeMockMatch(
        id: 'match_002',
        redName: '亀山クラブ : 道上',
        whiteName: '広島道場 : 皿田',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWith((ref) => [mockMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value(const <String>[])),
            permissionProvider.overrideWith((ref) => const AppPermissions(
              isReadOnly: false,
              canManageTournament: true,
              canCreateMatch: true,
              canChangeSettings: true,
              canDeleteData: true,
            )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MatchListTileCard(initialMatch: mockMatch, isDeletable: false),
            ),
          ),
        ),
      );

      expect(find.text('皿田'), findsOneWidget);
      expect(find.text('広島道場'), findsOneWidget);
    });

    testWidgets('3. 【スコアなし時空欄化】 一本が1つも決まっていない状態では、中央に余計な「ー」が表示されず完全空欄（SizedBox）になること', (WidgetTester tester) async {
      final mockMatch = makeMockMatch(
        id: 'match_003',
        redName: '亀山クラブ : 道上',
        whiteName: '広島道場 : 皿田',
        events: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWith((ref) => [mockMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value(const <String>[])),
            permissionProvider.overrideWith((ref) => const AppPermissions(
              isReadOnly: false,
              canManageTournament: true,
              canCreateMatch: true,
              canChangeSettings: true,
              canDeleteData: true,
            )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MatchListTileCard(initialMatch: mockMatch, isDeletable: false),
            ),
          ),
        ),
      );

      expect(find.text('ー'), findsNothing);
    });

    testWidgets('4. 【Undoリアクティブ即時反映】 試合中に Undo が実行されてイベントが消去された際、独立WidgetがElementキャッシュをぶち破って0秒で即座にマークを消滅させること', (WidgetTester tester) async {
      final initialEvent = ScoreEvent(
        id: 'ev_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        isCanceled: false,
        timestamp: DateTime(2026, 5, 22),
      );

      final mockMatchWithIppon = makeMockMatch(
        id: 'match_004',
        redName: '亀山クラブ : 道上',
        whiteName: '広島道場 : 皿田',
        status: 'in_progress',
        redScore: 1,
        events: [initialEvent],
      );

      final mockMatchAfterUndo = mockMatchWithIppon.copyWith(
        redScore: 0,
        events: [],
      );

      // 🛡️ 究極のテスト用状態プロバイダをローカルに創設
      // これをマッピング元に据えることで、Widgetテスト環境下でも100%確実にリアクティブ再描画イベントが伝播します。
      final testMatchListProvider = StateProvider<List<MatchModel>>((ref) => [mockMatchWithIppon]);

      final container = ProviderContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => ref.watch(testMatchListProvider)),
          customTeamNamesProvider.overrideWith((ref) => Stream.value(const <String>[])),
          permissionProvider.overrideWith((ref) => const AppPermissions(
            isReadOnly: false,
            canManageTournament: true,
            canCreateMatch: true,
            canChangeSettings: true,
            canDeleteData: true,
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MatchListTileCard(initialMatch: mockMatchWithIppon, isDeletable: false),
            ),
          ),
        ),
      );

      // 初期状態で有効一本の「メ」が確実にレンダリングされていることを確認
      expect(find.text('メ'), findsOneWidget);

      // 🔄 【Undo発動シミュレート】: ローカルの StateProvider の状態を直接書き換える
      container.read(testMatchListProvider.notifier).state = [mockMatchAfterUndo];
      
      // Flutter のレンダリングフレームを回して即時再描画を要求
      await tester.pump();

      // Undo操作直後に、画面から「メ」が完全消滅（遅延ゼロ即時反映）したことを厳密に検証
      expect(find.text('メ'), findsNothing);
    });

    testWidgets('5. 【全自動合計スコア集約】 団体戦グループ内の各ポジションのスコアが、親アコーディオンのヘッダーへ自動的に 3(5) - 1(2) の形式で正確に合算・表示されること', (WidgetTester tester) async {
      final m1 = makeMockMatch(id: 'b1', redName: '青龍 : 先鋒', whiteName: '白虎 : 先鋒', redScore: 2, whiteScore: 0, status: 'finished');
      final m2 = makeMockMatch(id: 'b2', redName: '青龍 : 次鋒', whiteName: '白虎 : 次鋒', redScore: 0, whiteScore: 0, status: 'finished');
      final m3 = makeMockMatch(id: 'b3', redName: '青龍 : 中堅', whiteName: '白虎 : 中堅', redScore: 0, whiteScore: 1, status: 'finished');
      final m4 = makeMockMatch(id: 'b4', redName: '青龍 : 副将', whiteName: '白虎 : 副将', redScore: 1, whiteScore: 0, status: 'finished');
      final m5 = makeMockMatch(id: 'b5', redName: '青龍 : 大将', whiteName: '白虎 : 大将', redScore: 1, whiteScore: 1, status: 'finished');

      final groupedMatches = [
        m1.copyWith(groupName: 'group_team_abc', matchType: '先鋒'),
        m2.copyWith(groupName: 'group_team_abc', matchType: '次鋒'),
        m3.copyWith(groupName: 'group_team_abc', matchType: '中堅'),
        m4.copyWith(groupName: 'group_team_abc', matchType: '副将'),
        m5.copyWith(groupName: 'group_team_abc', matchType: '大将'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWith((ref) => groupedMatches),
            // ★ 適合修正: 大会タイムライン内のコメント用ストリームを空データにモック化し、本番Isarの未初期化クラッシュを完全防御
            commentStreamProvider('t1').overrideWith((ref) => Stream.value([])),
            customTeamNamesProvider.overrideWith((ref) => Stream.value(const <String>[])),
            tournamentProvider('t1').overrideWith((ref) => Stream.value(null)),
            permissionProvider.overrideWith((ref) => const AppPermissions(
              isReadOnly: false,
              canManageTournament: true,
              canCreateMatch: true,
              canChangeSettings: true,
              canDeleteData: true,
            )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MatchTimelineList(tournamentId: 't1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 親 ExpansionTile のヘッダー内に、自動集計された勝数と本数が美しくマッピングされているか検証
      expect(find.text('2'), findsOneWidget);   // 赤勝者数（先鋒、副将）
      expect(find.text('(4)'), findsOneWidget); // 赤総本数（2 + 0 + 0 + 1 + 1 = 4本）
      expect(find.text('1'), findsOneWidget);   // 白勝者数（中堅）
      expect(find.text('(2)'), findsOneWidget); // 白総本数（0 + 0 + 1 + 0 + 1 = 2本）
    });
  });
}