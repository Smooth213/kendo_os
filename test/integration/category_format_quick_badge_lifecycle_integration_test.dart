import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/category_format_history_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockTeamRepository extends Mock implements TeamRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTournamentRepository mockTournamentRepo;
  late MockTeamRepository mockTeamRepo;
  late MockPlayerRepository mockPlayerRepo;
  late TournamentModel mockTournament;

  setUpAll(() {
    registerFallbackValue(
      const TeamModel(
        id: 'fallback_team',
        tournamentId: 'fallback_tour',
        category: '小学生高学年の部',
        teamName: 'fallback',
        matchType: '団体戦（5人制）',
        playerNames: [],
      ),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockTournamentRepo = MockTournamentRepository();
    mockTeamRepo = MockTeamRepository();
    mockPlayerRepo = MockPlayerRepository();

    mockTournament = TournamentModel(
      id: 'tour_badge_lifecycle',
      organizationId: 'org_test',
      name: 'バッジライフサイクル統合大会',
      date: DateTime.now(),
      venue: '日本武道館',
      categories: const ['小学生高学年の部', '中学生男子の部'],
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
    when(
      () => mockTeamRepo.saveTeam(any()),
    ).thenAnswer((_) async => 'team_123');
  });

  Widget buildTestableScreen({
    required SharedPreferences prefs,
    required GoRouter router,
    required WidgetRefCallback onRef,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        settingsProvider.overrideWith(() => MockSettingsNotifier()),
        currentDojoIdProvider.overrideWith((ref) => 'org_test'),
        tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
        teamRepositoryProvider.overrideWithValue(mockTeamRepo),
        playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          onRef(ref);
          return MaterialApp.router(
            theme: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('[E2E] クイックバッジ ライフサイクル統合テスト', () {
    testWidgets('初期定番バッジタップで一括選択から新形式でチーム登録完了を経て履歴が昇格して次回バッジに即時反映されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prefs = await SharedPreferences.getInstance();
      late WidgetRef widgetRef;

      final router = GoRouter(
        initialLocation: '/team-registration/tour_badge_lifecycle',
        routes: [
          GoRoute(
            path: '/team-registration/:id',
            builder: (context, state) => TeamRegistrationScreen(
              tournamentId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/tournament/:id/category-rules',
            builder: (context, state) =>
                const Scaffold(body: Text('ルール設定画面へ遷移完了')),
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestableScreen(
          prefs: prefs,
          router: router,
          onRef: (ref) {
            widgetRef = ref;
          },
        ),
      );
      await tester.pumpAndSettle();

      // 1. 初期バッジの存在検証（定番プリセットが表示されていること）
      expect(find.text('よく使う組み合わせ（ワンタップ入力）'), findsOneWidget);
      expect(find.text('小学生高学年 / 団体 5人制'), findsOneWidget);

      // 2. クイックバッジの1タップ一括反映検証
      // 「中学生男子 / 団体 5人制」バッジをタップ
      expect(find.text('中学生男子 / 団体 5人制'), findsOneWidget);
      await tester.tap(find.text('中学生男子 / 団体 5人制'));
      await tester.pump(const Duration(milliseconds: 300));

      // サマリーカードの【部門】と【形式】が即時同期されていること
      expect(find.text('選択中の設定内容'), findsOneWidget);
      expect(find.text('中学生男子の部'), findsWidgets);
      expect(find.text('団体戦（5人制）'), findsWidgets);

      // 3. 試合形式を「勝ち抜き戦（3人制）」に変更
      await tester.tap(find.text('勝ち抜き戦'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('3人制'));
      await tester.pump(const Duration(milliseconds: 300));

      // サマリーカードが「中学生男子の部」「勝ち抜き戦（3人制）」に更新されたこと
      expect(find.text('勝ち抜き戦（3人制）'), findsWidgets);

      // 4. 次へ進んでチーム名・選手入力（Step 2）
      await tester.tap(find.text('次へ進む'));
      await tester.pumpAndSettle();

      final teamNameField = find.byType(TextField);
      expect(teamNameField, findsWidgets);
      await tester.enterText(teamNameField.first, 'ライフサイクル修道館');
      await tester.pumpAndSettle();

      // 5. 次へ進んで登録確認（Step 3）
      await tester.tap(find.text('次へ進む'));
      await tester.pumpAndSettle();

      // 6. 登録完了をタップ
      expect(find.text('登録を完了してルール設定へ'), findsOneWidget);
      await tester.tap(find.text('登録を完了してルール設定へ'));
      await tester.pumpAndSettle();

      // リポジトリに正しく保存が呼ばれたこと
      verify(() => mockTeamRepo.saveTeam(any())).called(1);

      // 7. 履歴プロバイダーに「中学生男子の部」×「勝ち抜き戦（3人制）」が記録され、
      //    最優先バッジとして昇格していることを検証
      final updatedHistory = widgetRef.read(categoryFormatHistoryProvider);
      expect(updatedHistory, isNotEmpty);
      expect(updatedHistory.first.category, equals('中学生男子の部'));
      expect(updatedHistory.first.matchType, equals('勝ち抜き戦（3人制）'));
    });
  });
}

typedef WidgetRefCallback = void Function(WidgetRef ref);
