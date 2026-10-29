import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/category_rules_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockTeamRepository extends Mock implements TeamRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('[Widget] 参加チーム管理およびルール設定 画面遷移回帰検証テスト', () {
    late MockTournamentRepository mockTournamentRepo;
    late MockTeamRepository mockTeamRepo;
    late MockPlayerRepository mockPlayerRepo;
    late TournamentModel mockTournament;

    setUp(() {
      mockTournamentRepo = MockTournamentRepository();
      mockTeamRepo = MockTeamRepository();
      mockPlayerRepo = MockPlayerRepository();

      mockTournament = TournamentModel(
        id: 'test_tournament_123',
        organizationId: 'test_dojo_id',
        name: '回帰検証テスト大会',
        date: DateTime.now(),
        venue: 'テスト武道館',
        categories: const ['小学生の部'],
        categoryRules: const {},
      );

      when(
        () => mockTournamentRepo.getTournamentStream(any()),
      ).thenAnswer((_) => Stream.value(mockTournament));
      when(
        () => mockTeamRepo.watchTeamsByTournament(any()),
      ).thenAnswer((_) => Stream.value(<TeamModel>[]));
      when(
        () => mockPlayerRepo.getPlayers(),
      ).thenAnswer((_) => Stream.value(<PlayerModel>[]));
      when(
        () => mockPlayerRepo.watchCustomTeamNames(),
      ).thenAnswer((_) => Stream.value(<String>[]));
    });

    testWidgets('参加チーム管理モードにおいて 左下戻るボタンが非表示かつ大会ホームへ戻るボタンで正常復帰すること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
        initialLocation: '/home/test_tournament_123',
        routes: [
          GoRoute(
            path: '/home/:id',
            builder: (context, state) => Scaffold(
              body: Column(
                children: [
                  Text('大会ホーム画面: ${state.pathParameters['id']}'),
                  ElevatedButton(
                    onPressed: () => context.push(
                      '/team-registration/${state.pathParameters['id']}?initialPage=2&management=true',
                    ),
                    child: const Text('参加チーム管理を開く'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/team-registration/:id',
            builder: (context, state) {
              final initialPageStr = state.uri.queryParameters['initialPage'];
              final initialPage = initialPageStr != null
                  ? int.tryParse(initialPageStr)
                  : null;
              final isManagement =
                  state.uri.queryParameters['management'] == 'true' ||
                  initialPage == 2;
              return TeamRegistrationScreen(
                tournamentId: state.pathParameters['id']!,
                initialPage: initialPage,
                isManagementMode: isManagement,
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            tournamentProvider(
              'test_tournament_123',
            ).overrideWith((ref) => Stream.value(mockTournament)),
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            matchListByTournamentProvider(
              'test_tournament_123',
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.safePumpAndSettle();

      // 1. ホーム画面から参加チーム管理へ遷移
      expect(find.text('大会ホーム画面: test_tournament_123'), findsOneWidget);
      await tester.tap(find.text('参加チーム管理を開く'));
      await tester.safePumpAndSettle();

      // 2. 参加チーム管理画面（Page 2）が表示されていることを確認
      expect(find.text('登録済みチーム (0)'), findsOneWidget);
      expect(find.text('新しいチームを追加'), findsOneWidget);
      expect(find.text('大会ホームへ戻る'), findsOneWidget);

      // 3. 過去のウィザード用ボタン「登録を完了してルール設定へ」は非表示であること
      expect(find.text('登録を完了してルール設定へ'), findsNothing);

      // 4. 左下の丸い戻るボタン（OutlinedButton with CircleBorder）は非表示であること
      expect(
        find.byWidgetPredicate(
          (w) => w is OutlinedButton && w.style?.shape is CircleBorder,
        ),
        findsNothing,
      );

      // 5. 下部の「大会ホームへ戻る」ボタンを押下してホーム画面へ正常復帰すること
      await tester.tap(find.text('大会ホームへ戻る'));
      await tester.safePumpAndSettle();

      expect(find.text('大会ホーム画面: test_tournament_123'), findsOneWidget);
    });

    testWidgets('試合ルール設定画面において 履歴喪失状態でも戻るボタン押下で大会ホームへ正常復帰すること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // スタックが存在しない直接URL起動（context.go 相当）をシミュレート
      final router = GoRouter(
        initialLocation: '/tournament/test_tournament_123/category-rules',
        routes: [
          GoRoute(
            path: '/home/:id',
            builder: (context, state) =>
                Scaffold(body: Text('大会ホーム画面: ${state.pathParameters['id']}')),
          ),
          GoRoute(
            path: '/tournament/:id/category-rules',
            builder: (context, state) => CategoryRulesScreen(
              tournamentId: state.pathParameters['id']!,
              isFromSetup: false,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            tournamentProvider(
              'test_tournament_123',
            ).overrideWith((ref) => Stream.value(mockTournament)),
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            matchListByTournamentProvider(
              'test_tournament_123',
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.safePumpAndSettle();

      // 1. ルール設定画面が表示されていること
      expect(find.text('試合ルール設定'), findsOneWidget);

      // 2. 左上の戻るアイコンボタンを押下
      final backButton = find.byIcon(Icons.arrow_back_ios_new);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.safePumpAndSettle();

      // 3. 履歴がない場合でもフォールバックにより大会ホームへ正常復帰すること
      expect(find.text('大会ホーム画面: test_tournament_123'), findsOneWidget);
    });
  });
}
