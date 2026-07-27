import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late MockTournamentRepository mockTournamentRepo;
  late MockPlayerRepository mockPlayerRepo;
  late MockLocalMatchRepository mockLocalRepo;
  late MockSyncEngine mockSyncEngine;
  late TournamentModel mockTournament;

  setUpAll(() {
    registerFallbackValue(<MatchModel>[]);
  });

  setUp(() {
    mockTournamentRepo = MockTournamentRepository();
    mockPlayerRepo = MockPlayerRepository();
    mockLocalRepo = MockLocalMatchRepository();
    mockSyncEngine = MockSyncEngine();

    mockTournament = TournamentModel(
      id: 'test_tournament_123',
      name: 'オンボーディングテスト大会',
      date: DateTime.now(),
      venue: 'テニスコート',
      categories: const ['小学生の部'],
      organizationId: 'dojo_123',
      categoryRules: const {}, // 最初はルール設定なし
    );

    when(
      () => mockTournamentRepo.getTournamentStream(any()),
    ).thenAnswer((_) => Stream.value(mockTournament));
    when(
      () => mockPlayerRepo.watchCustomTeamNames(),
    ).thenAnswer((_) => Stream.value(<String>[]));
    when(
      () => mockLocalRepo.watchAllLocalMatches(),
    ).thenAnswer((_) => Stream.value(<MatchModel>[]));
  });

  testWidgets(
    '1. HomeScreen onboarding checklist rendering and state verification',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // 準備フェーズ: 試合が0件、チームも0件
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            dojoRoomSyncProvider.overrideWithValue(null),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
            currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'test_tournament_123',
            ),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(<MatchModel>[]),
            ),
            registeredTeamsProvider.overrideWith(
              (ref, id) => Stream.value(<TeamModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(tournamentId: 'test_tournament_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. チェックリストが表示されていること
      expect(find.text('大会準備ステップ'), findsOneWidget);
      expect(find.text('25% 完了'), findsOneWidget); // 大会作成(25%)のみ完了

      // 2. 「出場チーム・選手の登録」と「部門別ルールの設定」が未完了（打ち消し線なし）
      final teamText = find.text('出場チーム・選手の登録');
      expect(teamText, findsOneWidget);

      final ruleText = find.text('部門別ルールの設定');
      expect(ruleText, findsOneWidget);
    },
  );

  testWidgets(
    '2. Onboarding checklist dynamic checks update when teams and rules are set',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final populatedTournament = mockTournament.copyWith(
        categoryRules: {'小学生の部': const CategoryRuleSet()},
      );
      when(
        () => mockTournamentRepo.getTournamentStream(any()),
      ).thenAnswer((_) => Stream.value(populatedTournament));

      final mockTeams = <TeamModel>[
        TeamModel(
          id: 'team1',
          teamName: '少年剣道A',
          category: '小学生の部',
          tournamentId: 'test_tournament_123',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            dojoRoomSyncProvider.overrideWithValue(null),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
            currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'test_tournament_123',
            ),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(<MatchModel>[]),
            ),
            registeredTeamsProvider.overrideWith(
              (ref, id) => Stream.value(mockTeams),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(tournamentId: 'test_tournament_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. チーム(25%) + ルール(25%) + 作成(25%) = 75% 完了 になっていること
      expect(find.text('大会準備ステップ'), findsOneWidget);
      expect(find.text('75% 完了'), findsOneWidget);
    },
  );

  testWidgets('3. Checklist is completely hidden when matches exist', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final activeMatches = <MatchModel>[
      const MatchModel(
        id: 'match1',
        tournamentId: 'test_tournament_123',
        category: '小学生の部',
        redName: '剣道太郎',
        whiteName: '剣道花子',
        status: 'waiting',
        matchType: '個人戦',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
          playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          syncEngineProvider.overrideWithValue(mockSyncEngine),
          dojoRoomSyncProvider.overrideWithValue(null),
          commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
          permissionProvider.overrideWith(
            (ref) => const AppPermissions(
              isReadOnly: false,
              canManageTournament: true,
              canCreateMatch: true,
              canChangeSettings: true,
              canDeleteData: true,
            ),
          ),
          currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
          currentTournamentIdProvider.overrideWith(
            (ref) => 'test_tournament_123',
          ),
          matchListByTournamentProvider.overrideWith(
            (ref, id) => Stream.value(activeMatches),
          ),
          registeredTeamsProvider.overrideWith(
            (ref, id) => Stream.value(<TeamModel>[]),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(tournamentId: 'test_tournament_123'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. 試合がすでに作成されているため、チェックリストが表示されないこと
    expect(find.text('大会準備ステップ'), findsNothing);
  });
}
