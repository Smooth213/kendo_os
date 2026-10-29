import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_highlight_text.dart';
import 'package:kendo_os/shared/widgets/app_search_header.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  group('[Widget] Search Header 統合テスト (HomeScreen & ViewerHomeScreen)', () {
    late MockTournamentRepository mockTournamentRepo;
    late MockPlayerRepository mockPlayerRepo;
    late MockSyncEngine mockSyncEngine;
    late MockLocalMatchRepository mockLocalRepo;
    late SharedPreferences prefs;

    const testTournamentId = 'test_tournament_1';
    final dummyTournament = TournamentModel(
      id: testTournamentId,
      name: 'テスト大会',
      date: DateTime.now(),
      venue: '道場',
      categories: ['一般の部'],
      organizationId: 'dojo_123',
    );

    final mockMatches = [
      const MatchModel(
        id: 'm1',
        tournamentId: testTournamentId,
        matchType: '個人戦',
        redName: '亀山クラブ : 選手A',
        whiteName: '広島道場 : 選手B',
        status: 'waiting',
        order: 1.0,
      ),
      const MatchModel(
        id: 'm2',
        tournamentId: testTournamentId,
        matchType: '個人戦',
        redName: '岡山館 : 選手C',
        whiteName: '鳥取倶楽部 : 選手D',
        status: 'waiting',
        order: 2.0,
      ),
    ];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockTournamentRepo = MockTournamentRepository();
      mockPlayerRepo = MockPlayerRepository();
      mockSyncEngine = MockSyncEngine();
      mockLocalRepo = MockLocalMatchRepository();

      when(
        () => mockTournamentRepo.getTournamentStream(any()),
      ).thenAnswer((_) => Stream.value(dummyTournament));
      when(
        () => mockPlayerRepo.watchCustomTeamNames(
          organization: any(named: 'organization'),
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockLocalRepo.watchLocalMatches(any()),
      ).thenAnswer((_) => Stream.value(mockMatches));
      when(
        () => mockLocalRepo.watchAllLocalMatches(),
      ).thenAnswer((_) => Stream.value(mockMatches));
    });

    Widget buildTestApp({
      required Widget child,
      List<Override> overrides = const [],
    }) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [GoRoute(path: '/', builder: (context, state) => child)],
      );

      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
          currentTournamentIdProvider.overrideWith((ref) => testTournamentId),
          tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
          playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
          syncEngineProvider.overrideWithValue(mockSyncEngine),
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
          dojoRoomSyncProvider.overrideWithValue(null),
          matchListByTournamentProvider.overrideWith(
            (ref, id) => Stream.value(mockMatches),
          ),
          ...overrides,
        ],
        child: MaterialApp.router(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          routerConfig: router,
        ),
      );
    }

    testWidgets(
      'HomeScreen（運営）: 検索ボタン押下でAppSearchHeaderが開き、入力・キャンセルで正常に閉じること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestApp(
            overrides: [
              currentUserRoleProvider.overrideWith((ref) => UserRole.operator),
              permissionProvider.overrideWith(
                (ref) => const AppPermissions(
                  isReadOnly: false,
                  canManageTournament: true,
                  canCreateMatch: true,
                  canChangeSettings: true,
                  canDeleteData: true,
                ),
              ),
            ],
            child: const HomeScreen(tournamentId: testTournamentId),
          ),
        );

        await tester.pump();
        await tester.safePumpAndSettle();

        // 初期状態: 通常の「大会ホーム」ヘッダーが表示されていること
        expect(find.text('大会ホーム'), findsOneWidget);
        expect(find.byType(AppSearchHeader), findsNothing);

        // 試合リスト内の検索アイコンボタン（tooltip: '試合を検索'）をタップ
        final searchButton = find.byTooltip('試合を検索');
        expect(searchButton, findsOneWidget);
        await tester.tap(searchButton);
        await tester.safePumpAndSettle();

        // 検索モード: AppSearchHeader が AppBar に表示されていること
        expect(find.byType(AppSearchHeader), findsOneWidget);
        expect(find.text('大会ホーム'), findsNothing);
        expect(find.text('選手名・チーム名で検索...'), findsOneWidget);
        expect(find.text('キャンセル'), findsOneWidget);

        // 検索ワードを入力
        await tester.enterText(find.byType(AppTextField), '選手A');
        await tester.safePumpAndSettle();

        // 「キャンセル」ボタンを押下して検索を終了
        await tester.tap(find.text('キャンセル'));
        await tester.safePumpAndSettle();

        // 検索終了: 通常の「大会ホーム」ヘッダーに復帰すること
        expect(find.text('大会ホーム'), findsOneWidget);
        expect(find.byType(AppSearchHeader), findsNothing);
      },
    );

    testWidgets(
      'ViewerHomeScreen（観客）: 検索ボタン押下でAppSearchHeaderが開き、入力・キャンセルで正常に閉じること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestApp(
            overrides: [
              currentUserRoleProvider.overrideWith((ref) => UserRole.viewer),
              permissionProvider.overrideWith(
                (ref) => const AppPermissions(
                  isReadOnly: true,
                  canManageTournament: false,
                  canCreateMatch: false,
                  canChangeSettings: false,
                  canDeleteData: false,
                ),
              ),
            ],
            child: const ViewerHomeScreen(tournamentId: testTournamentId),
          ),
        );

        await tester.pump();
        await tester.safePumpAndSettle();

        // 初期状態: 「大会ホーム (観客席)」ヘッダーが表示されていること
        expect(find.text('大会ホーム (観客席)'), findsOneWidget);
        expect(find.byType(AppSearchHeader), findsNothing);

        // 試合リスト内の検索アイコンボタンをタップ
        final searchButton = find.byTooltip('試合を検索');
        expect(searchButton, findsOneWidget);
        await tester.tap(searchButton);
        await tester.safePumpAndSettle();

        // 検索モード: AppSearchHeader が表示されること
        expect(find.byType(AppSearchHeader), findsOneWidget);
        expect(find.text('大会ホーム (観客席)'), findsNothing);
        expect(find.text('キャンセル'), findsOneWidget);

        // 「キャンセル」ボタンを押下して検索を終了
        await tester.tap(find.text('キャンセル'));
        await tester.safePumpAndSettle();

        // 検索終了: 「大会ホーム (観客席)」ヘッダーに復帰すること
        expect(find.text('大会ホーム (観客席)'), findsOneWidget);
        expect(find.byType(AppSearchHeader), findsNothing);
      },
    );

    testWidgets('AppHighlightText: 検索クエリと一致する部分がハイライトスタイルで描画されること', (
      tester,
    ) async {
      // 1. buildSpans の純粋ロジック検証
      final spans = AppHighlightText.buildSpans(
        text: '道上剣友会 vs テスト001-1',
        query: '道上',
      );
      expect(spans.length, 2);
      expect(spans[0].text, '道上');
      expect(spans[0].style?.backgroundColor, isNotNull);
      expect(spans[1].text, '剣友会 vs テスト001-1');

      // 2. ウィジェットレンダリング検証
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppHighlightText(text: '道上剣友会 vs テスト001-1', query: '道上'),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      final textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.textSpan, isNotNull);
      final rootSpan = textWidget.textSpan! as TextSpan;
      expect(rootSpan.children, isNotNull);
      expect(rootSpan.children!.length, 2);
      final childSpan = rootSpan.children![0] as TextSpan;
      expect(childSpan.text, '道上');
      expect(childSpan.style?.backgroundColor, isNotNull);
    });

    test('AppHighlightText: 空クエリ・不一致・大文字小文字のエッジケースが安全に処理されること', () {
      // 空文字クエリ: スパン分割されず単一テキストとして返ること
      final emptySpans = AppHighlightText.buildSpans(text: '道上剣友会', query: '');
      expect(emptySpans.length, 1);
      expect(emptySpans[0].text, '道上剣友会');
      expect(emptySpans[0].style?.backgroundColor, isNull);

      // 空白のみのクエリ: トリムされて単一テキストとして返ること
      final whitespaceSpans = AppHighlightText.buildSpans(
        text: '道上剣友会',
        query: '   ',
      );
      expect(whitespaceSpans.length, 1);
      expect(whitespaceSpans[0].text, '道上剣友会');
      expect(whitespaceSpans[0].style?.backgroundColor, isNull);

      // 一致しないクエリ: 分割されず単一テキストとして返ること
      final noMatchSpans = AppHighlightText.buildSpans(
        text: '道上剣友会',
        query: '東京',
      );
      expect(noMatchSpans.length, 1);
      expect(noMatchSpans[0].text, '道上剣友会');
      expect(noMatchSpans[0].style?.backgroundColor, isNull);

      // 大文字小文字の差異: 小文字クエリで大文字テキストが正しくハイライトされること
      final caseInsensitiveSpans = AppHighlightText.buildSpans(
        text: 'KENDO TEAM vs OPPONENT',
        query: 'team',
      );
      expect(caseInsensitiveSpans.length, 3);
      expect(caseInsensitiveSpans[0].text, 'KENDO ');
      expect(caseInsensitiveSpans[1].text, 'TEAM');
      expect(caseInsensitiveSpans[1].style?.backgroundColor, isNotNull);
      expect(caseInsensitiveSpans[2].text, ' vs OPPONENT');
    });
  });
}
