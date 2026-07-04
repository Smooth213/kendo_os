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
  });
}
