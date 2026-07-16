import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';

void main() {
  group('🛡️ MatchScreen Web Fallback & Render Tests', () {
    test(
      '✅ 1. MatchScreen に Web環境用フォールバック (kIsWeb && tournamentId) のパッチが確実に存在すること',
      () {
        // Dart VMテスト環境では kIsWeb=false となるため、ソースコードレベルの静的検証でパッチの存在を証明する
        final file = File(
          'lib/features/tournament/presentation/operate/match_screen.dart',
        );
        expect(
          file.existsSync(),
          isTrue,
          reason: 'match_screen.dart が存在する必要があります',
        );

        final content = file.readAsStringSync();
        expect(
          content.contains('kIsWeb'),
          isTrue,
          reason: 'kIsWeb による環境判定が誤って削除されています',
        );
        expect(
          content.contains('uri.queryParameters[\'tournamentId\']'),
          isTrue,
          reason: 'GoRouterState から tournamentId を取得するロジックが誤って削除されています',
        );
        expect(
          content.contains('matchListByTournamentProvider'),
          isTrue,
          reason: 'Web用フォールバックの matchListByTournamentProvider への参照が誤って削除されています',
        );
      },
    );

    testWidgets(
      '✅ 2. 試合データが存在する場合、無限ロード(ProgressIndicator)にならず正常にレンダリングされること',
      (WidgetTester tester) async {
        // ★ 依存する SharedPreferences をモック化して UnimplementedError を回避
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        const mockMatch = MatchModel(
          id: 'test_match_1',
          tournamentId: 'tourney_1',
          matchType: '個人戦',
          redName: '赤選手',
          whiteName: '白選手',
          status: 'waiting',
        );

        final router = GoRouter(
          initialLocation: '/match/test_match_1',
          routes: [
            GoRoute(
              path: '/match/:id',
              builder: (context, state) =>
                  MatchScreen(matchId: state.pathParameters['id']!),
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            matchListProvider.overrideWith((ref) => [mockMatch]),
            matchViewStateProvider('test_match_1').overrideWith(
              (ref) => MatchViewState(
                scoreText: '0 - 0',
                redScore: 0,
                whiteScore: 0,
                isEncho: false,
                winner: null,
                lastEventText: '',
                canUndo: false,
                statusText: '待機中',
                syncStatus: SyncStatus.synced,
                isViewOnly: false,
                isInputLocked: false,
                isAllDone: false,
                isTie: false,
                redCleanName: '赤選手',
                whiteCleanName: '白選手',
              ),
            ),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
            isarProvider.overrideWithValue(null),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              theme: ThemeData.light(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // MatchScreen が正常にレンダリングされ、無限ロード(クルクル) が表示されないこと
        expect(find.byType(CircularProgressIndicator), findsNothing);
        // ヘッダーやテキストが正しく抽出・表示されていることを確認
        expect(find.text('赤選手 vs 白選手'), findsOneWidget);

        // テストが終わる前に別のWidgetをPumpし、現在の画面をdisposeさせる。
        // ProviderContainer は UncontrolledProviderScope の外で管理しているため破棄されない。
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        // テスト終了前に手動でコンテナを破棄し、内部のTimer(SyncEngineなど)を確実にキャンセルする
        container.dispose();
      },
    );

    testWidgets('✅ 3. 「観戦URLを共有」ボタンが表示され、タップできること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const mockMatch = MatchModel(
        id: 'test_match_share_1',
        tournamentId: 'tourney_1',
        matchType: '個人戦',
        redName: '佐々木 武',
        whiteName: '選手',
        status: 'waiting',
      );

      final router = GoRouter(
        initialLocation: '/match/test_match_share_1',
        routes: [
          GoRoute(
            path: '/match/:id',
            builder: (context, state) =>
                MatchScreen(matchId: state.pathParameters['id']!),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          matchListProvider.overrideWith((ref) => [mockMatch]),
          matchViewStateProvider('test_match_share_1').overrideWith(
            (ref) => MatchViewState(
              scoreText: '0 - 0',
              redScore: 0,
              whiteScore: 0,
              isEncho: false,
              winner: null,
              lastEventText: '',
              canUndo: false,
              statusText: '待機中',
              syncStatus: SyncStatus.synced,
              isViewOnly: false,
              isInputLocked: false,
              isAllDone: false,
              isTie: false,
              redCleanName: '佐々木 武',
              whiteCleanName: '選手',
            ),
          ),
          permissionProvider.overrideWith(
            (ref) => const AppPermissions(
              isReadOnly: false,
              canManageTournament: true,
              canCreateMatch: true,
              canChangeSettings: true,
              canDeleteData: true,
            ),
          ),
          isarProvider.overrideWithValue(null),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData.light(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 観戦URLを共有ボタンが表示されていることを検証
      final shareBtnFinder = find.text('観戦URLを共有');
      expect(shareBtnFinder, findsOneWidget);

      // タップしてもエラーにならず正常終了することを検証
      await tester.tap(shareBtnFinder);
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      container.dispose();
    });

    testWidgets('✅ 4. 選手名タップによるボトムシート表示と、控え（緑）/出場中（オレンジ）の色分け表示、およびスワップ保存のテスト', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeAppService = FakeMatchApplicationService();

      final mockMatch1 = MatchModel(
        id: 'match_1',
        tournamentId: 't1',
        matchType: '先鋒',
        redName: 'チームA : 出場 次郎',
        whiteName: 'チームB : 相手先鋒',
        groupName: 'チームA vs チームB',
        category: '小学生高学年の部',
        status: 'waiting',
      );

      final mockMatch2 = MatchModel(
        id: 'match_2',
        tournamentId: 't1',
        matchType: '中堅',
        redName: 'チームA : 元中堅',
        whiteName: 'チームB : 相手中堅',
        groupName: 'チームA vs チームB',
        category: '小学生高学年の部',
        status: 'waiting',
      );

      final p1 = PlayerModel(
        id: 'p1',
        lastName: '控え',
        firstName: '太郎',
        lastNameKana: 'ひかえ',
        firstNameKana: 'たろう',
        grade: 5, // 小学生高学年
        gender: '男子',
        organization: 'チームA',
        isBeginner: false,
      );

      final p2 = PlayerModel(
        id: 'p2',
        lastName: '出場',
        firstName: '次郎',
        lastNameKana: 'しゅつじょう',
        firstNameKana: 'じろう',
        grade: 6, // 小学生高学年
        gender: '男子',
        organization: 'チームA',
        isBeginner: false,
      );

      final p3 = PlayerModel(
        id: 'p3',
        lastName: '他カテゴリ',
        firstName: '三郎',
        lastNameKana: 'たかてごり',
        firstNameKana: 'さぶろう',
        grade: 8, // 中学生の部
        gender: '男子',
        organization: 'チームA',
        isBeginner: false,
      );

      final team = TeamModel(
        id: 'team_a',
        teamName: 'チームA',
        tournamentId: 't1',
        category: '小学生高学年の部',
        playerNames: const ['出場 次郎', '元中堅', '控え 太郎'],
      );

      final router = GoRouter(
        initialLocation: '/match/match_2',
        routes: [
          GoRoute(
            path: '/match/:id',
            builder: (context, state) =>
                MatchScreen(matchId: state.pathParameters['id']!),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          matchListProvider.overrideWith((ref) => [mockMatch1, mockMatch2]),
          matchViewStateProvider('match_2').overrideWith(
            (ref) => MatchViewState(
              scoreText: '0 - 0',
              redScore: 0,
              whiteScore: 0,
              isEncho: false,
              winner: null,
              lastEventText: '',
              canUndo: false,
              statusText: '待機中',
              syncStatus: SyncStatus.synced,
              isViewOnly: false,
              isInputLocked: false,
              isAllDone: false,
              isTie: false,
              redCleanName: '元中堅',
              whiteCleanName: '相手中堅',
            ),
          ),
          permissionProvider.overrideWith(
            (ref) => const AppPermissions(
              isReadOnly: false,
              canManageTournament: true,
              canCreateMatch: true,
              canChangeSettings: true,
              canDeleteData: true,
            ),
          ),
          playerListProvider.overrideWith((ref) => Stream.value([p1, p2, p3])),
          registeredTeamsProvider(
            't1',
          ).overrideWith((ref) => Stream.value([team])),
          matchApplicationServiceProvider.overrideWithValue(fakeAppService),
          isarProvider.overrideWithValue(null),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData.light(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 赤チーム（自チーム）の選手名をタップしてボトムシートを開く
      final redNameFinder = find.text('元中堅');
      expect(redNameFinder, findsOneWidget);
      await tester.tap(redNameFinder);
      await tester.pumpAndSettle();

      // ボトムシートが開き、名簿が表示されていることを確認
      expect(find.text('選手名の変更'), findsOneWidget);
      expect(find.text('補欠登録の選手（タップで交代）'), findsOneWidget);
      expect(find.text('控え 太郎'), findsOneWidget);
      expect(find.text('出場中の選手 (交代・スワップ)'), findsOneWidget);
      expect(find.text('出場 次郎'), findsOneWidget);

      // 他のカテゴリの選手が表示されていない（折りたたまれている）ことを確認
      expect(find.text('他カテゴリ 三郎'), findsNothing);

      // 控え 太郎 をタップして保存するテスト
      await tester.tap(find.text('控え 太郎'));
      await tester.pumpAndSettle();

      // ボトムシートが閉じ、saveMatch が呼び出されたことを確認
      expect(fakeAppService.savedMatches.length, 1);
      expect(fakeAppService.savedMatches.first.redName, 'チームA : 控え 太郎');

      // クリアして次のスワップのテスト
      fakeAppService.savedMatches.clear();

      // 再度ボトムシートを開く
      await tester.tap(redNameFinder);
      await tester.pumpAndSettle();

      // 出場 次郎 をタップしてスマートスワップのテスト
      await tester.tap(find.text('出場 次郎'));
      await tester.pumpAndSettle();

      // ボトムシートが閉じ、saveMatchesBulk が呼び出され、2つの試合（先鋒と中堅）がスワップされたことを確認
      expect(fakeAppService.savedMatches.length, 2);

      // 中堅(match_2)には 出場 次郎 が設定される
      final updatedMatch2 = fakeAppService.savedMatches.firstWhere(
        (m) => m.id == 'match_2',
      );
      expect(updatedMatch2.redName, 'チームA : 出場 次郎');

      // 先鋒(match_1)には 元中堅 が設定される
      final updatedMatch1 = fakeAppService.savedMatches.firstWhere(
        (m) => m.id == 'match_1',
      );
      expect(updatedMatch1.redName, 'チームA : 元中堅');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      container.dispose();
    });

    testWidgets('✅ 5. 補欠登録選手・同カテゴリ控え選手リストの機能性およびコンパクトデザイン整合性検証のテスト', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeAppService = FakeMatchApplicationService();

      final mockMatch1 = MatchModel(
        id: 'match_1',
        tournamentId: 't1',
        matchType: '先鋒',
        redName: 'チームA : 出場 次郎',
        whiteName: 'チームB : 相手先鋒',
        groupName: 'チームA vs チームB',
        category: '小学生高学年の部',
        status: 'waiting',
      );

      final mockMatch2 = MatchModel(
        id: 'match_2',
        tournamentId: 't1',
        matchType: '中堅',
        redName: 'チームA : 元中堅',
        whiteName: 'チームB : 相手中堅',
        groupName: 'チームA vs チームB',
        category: '小学生高学年の部',
        status: 'waiting',
      );

      final p1 = PlayerModel(
        id: 'p1',
        lastName: '控え',
        firstName: '太郎',
        lastNameKana: 'ひかえ',
        firstNameKana: 'たろう',
        grade: 5, // 小学生高学年
        gender: '男子',
        organization: 'チームA',
        isBeginner: false,
      );

      final p2 = PlayerModel(
        id: 'p2',
        lastName: '出場',
        firstName: '次郎',
        lastNameKana: 'しゅつじょう',
        firstNameKana: 'じろう',
        grade: 6, // 小学生高学年
        gender: '男子',
        organization: 'チームA',
        isBeginner: false,
      );

      final p4 = PlayerModel(
        id: 'p4',
        lastName: '同カテゴリ',
        firstName: '四郎',
        lastNameKana: 'どうかてごり',
        firstNameKana: 'しろう',
        grade: 5, // 小学生高学年
        gender: '男子',
        organization: 'チームA',
        isBeginner: false,
      );

      final team = TeamModel(
        id: 'team_a',
        teamName: 'チームA',
        tournamentId: 't1',
        category: '小学生高学年の部',
        playerNames: const ['出場 次郎', '元中堅', '控え 太郎'],
      );

      final router = GoRouter(
        initialLocation: '/match/match_2',
        routes: [
          GoRoute(
            path: '/match/:id',
            builder: (context, state) =>
                MatchScreen(matchId: state.pathParameters['id']!),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          matchListProvider.overrideWith((ref) => [mockMatch1, mockMatch2]),
          matchViewStateProvider('match_2').overrideWith(
            (ref) => MatchViewState(
              scoreText: '0 - 0',
              redScore: 0,
              whiteScore: 0,
              isEncho: false,
              winner: null,
              lastEventText: '',
              canUndo: false,
              statusText: '待機中',
              syncStatus: SyncStatus.synced,
              isViewOnly: false,
              isInputLocked: false,
              isAllDone: false,
              isTie: false,
              redCleanName: '元中堅',
              whiteCleanName: '相手中堅',
            ),
          ),
          permissionProvider.overrideWith(
            (ref) => const AppPermissions(
              isReadOnly: false,
              canManageTournament: true,
              canCreateMatch: true,
              canChangeSettings: true,
              canDeleteData: true,
            ),
          ),
          playerListProvider.overrideWith((ref) => Stream.value([p1, p2, p4])),
          registeredTeamsProvider(
            't1',
          ).overrideWith((ref) => Stream.value([team])),
          matchApplicationServiceProvider.overrideWithValue(fakeAppService),
          isarProvider.overrideWithValue(null),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData.light(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ボトムシートを開く
      final redNameFinder = find.text('元中堅');
      await tester.tap(redNameFinder);
      await tester.pumpAndSettle();

      // 同カテゴリの控え選手（同カテゴリ 四郎）が表示されていることを検証
      expect(find.text('同カテゴリの控え選手'), findsOneWidget);
      expect(find.text('同カテゴリ 四郎'), findsOneWidget);

      // デザイン整合性（コンパクトさ）の検証

      // 1. 各カードのサイズ・余白・形状の検証
      final cardFinder = find.byType(Card).first;
      final cardWidget = tester.widget<Card>(cardFinder);
      expect(cardWidget.margin, const EdgeInsets.only(bottom: 6));
      expect(cardWidget.shape, isA<RoundedRectangleBorder>());
      expect(
        ((cardWidget.shape as RoundedRectangleBorder).borderRadius
                as BorderRadius)
            .topRight,
        const Radius.circular(10),
      );

      // 2. ListTile の dense 設定と contentPadding の検証
      final listTileFinder = find
          .descendant(of: cardFinder, matching: find.byType(ListTile))
          .first;
      final listTileWidget = tester.widget<ListTile>(listTileFinder);
      expect(listTileWidget.dense, isTrue);
      expect(
        listTileWidget.contentPadding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      );

      // 3. CircleAvatar のサイズ（半径14dp）の検証
      final avatarFinder = find
          .descendant(of: listTileFinder, matching: find.byType(CircleAvatar))
          .first;
      final avatarWidget = tester.widget<CircleAvatar>(avatarFinder);
      expect(avatarWidget.radius, 14);

      // 4. 「欠員」ボタンの高さ（縦パディング 10dp）の検証
      final btnFinder = find.widgetWithText(OutlinedButton, 'このポジションを「欠員」にする');
      expect(btnFinder, findsOneWidget);
      final btnWidget = tester.widget<OutlinedButton>(btnFinder);
      final padding = btnWidget.style?.padding?.resolve({});
      expect(padding, const EdgeInsets.symmetric(vertical: 10));

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      container.dispose();
    });
  });
}

// テスト用モッククラス
class FakeMatchApplicationService implements MatchApplicationService {
  final List<MatchModel> savedMatches = [];

  @override
  Future<void> saveMatch(MatchModel match) async {
    savedMatches.add(match);
  }

  @override
  Future<void> saveMatchesBulk(List<MatchModel> matches) async {
    savedMatches.addAll(matches);
  }

  @override
  Future<bool> claimScorer(String matchId, String userId) async => true;

  @override
  Future<void> releaseScorer(String matchId, String userId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
