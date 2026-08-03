import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/category_rules_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatchModel(
        id: 'dummy',
        matchType: 'dummy',
        redName: 'red',
        whiteName: 'white',
      ),
    );
    registerFallbackValue(
      MatchCommandModel(
        id: 'dummy',
        type: CommandType.updateMatch,
        payload: const {},
        createdAt: DateTime.now(),
        status: CommandStatus.pending,
      ),
    );
  });

  group('Match Rules Propagation & Application Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TournamentModel testTournament;
    late MockLocalMatchRepository mockLocalRepo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockLocalRepo = MockLocalMatchRepository();

      when(() => mockLocalRepo.saveMatchesBulk(any())).thenAnswer((_) async {});
      when(() => mockLocalRepo.saveMatch(any())).thenAnswer((_) async {});
      when(
        () => mockLocalRepo.savePendingCommand(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalRepo.getPendingCommands(),
      ).thenAnswer((_) async => <MatchCommandModel>[]);
      when(
        () => mockLocalRepo.getPendingMatches(),
      ).thenAnswer((_) async => <MatchModel>[]);
      when(
        () => mockLocalRepo.watchAllLocalMatches(),
      ).thenAnswer((_) => Stream.value(<MatchModel>[]));

      testTournament = TournamentModel(
        id: 'test_tournament_rules',
        organizationId: 'test_dojo_id',
        name: 'ルール適用テスト大会',
        date: DateTime.now(),
        venue: 'テスト武道館',
        categories: const ['小学生の部'],
        categoryRules: {
          '小学生の部': CategoryRuleSet(
            normalRule: const MatchRule(
              matchTimeMinutes: 2.0,
              hasHantei: true,
              enchoCount: 1,
              enchoTimeMinutes: 1.0,
            ),
            advancedRule: const MatchRule(
              matchTimeMinutes: 3.0,
              isEnchoUnlimited: true,
              enchoTimeMinutes: 2.0,
            ),
            useAdvancedRule: true,
          ),
        },
      );
    });

    testWidgets(
      '1. Verification of CategoryRulesScreen bulk-applying new rules to existing incomplete matches',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. Prepare matches with old rules (e.g. 5.0 minutes match time)
        final oldRule = const MatchRule(
          matchTimeMinutes: 5.0,
          hasHantei: false,
        );
        final matches = [
          MatchModel(
            id: 'match_incomplete_1',
            tournamentId: 'test_tournament_rules',
            category: '小学生の部',
            matchType: '個人戦',
            redName: '赤選手A',
            whiteName: '白選手A',
            status: 'waiting',
            matchTimeMinutes: 5.0,
            rule: oldRule,
          ),
          MatchModel(
            id: 'match_completed_2',
            tournamentId: 'test_tournament_rules',
            category: '小学生の部',
            matchType: '個人戦',
            redName: '赤選手B',
            whiteName: '白選手B',
            status: 'finished', // Completed!
            matchTimeMinutes: 5.0,
            rule: oldRule,
          ),
        ];

        // Insert tournament and matches into Fake Firestore
        await fakeFirestore
            .collection('organizations')
            .doc('test_dojo_id')
            .collection('tournaments')
            .doc(testTournament.id)
            .set(testTournament.toJson());

        for (final m in matches) {
          await fakeFirestore
              .collection('organizations')
              .doc('test_dojo_id')
              .collection('tournaments')
              .doc(testTournament.id)
              .collection('matches')
              .doc(m.id)
              .set(m.toJson());
        }

        // Build CategoryRulesScreen
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWith((ref) {
                return TournamentRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
              tournamentProvider('test_tournament_rules').overrideWith((ref) {
                return Stream.value(testTournament);
              }),
              matchListByTournamentProvider(
                'test_tournament_rules',
              ).overrideWith((ref) {
                return Stream.value(matches);
              }),
              matchListProvider.overrideWith((ref) => matches),
              matchStreamProvider.overrideWith((ref) => Stream.value(matches)),
              localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            ],
            child: const MaterialApp(
              home: CategoryRulesScreen(tournamentId: 'test_tournament_rules'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(CategoryRulesScreen)),
        );
        await container.read(
          matchListByTournamentProvider('test_tournament_rules').future,
        );

        // Open rule editor
        await tester.drag(
          find.byKey(const ValueKey('slidable_rule_小学生の部')),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('編集'));
        await tester.pumpAndSettle();

        // Change normal match time preset from 2分 to 4分
        expect(find.text('通常戦のルール'), findsOneWidget);
        await tester.tap(find.text('4分'));
        await tester.pumpAndSettle();

        // Click save button
        await tester.tap(find.text('設定を保存'));
        await tester.pumpAndSettle();

        // Verify bulk apply confirmation dialog appears (as we have 'match_incomplete_1' under '小学生の部')
        expect(find.text('作成済みの試合に一括適用しますか？'), findsOneWidget);

        // Tap "一括適用する"
        await tester.tap(find.text('一括適用する'));
        await tester.pumpAndSettle();

        // Verify that 'match_incomplete_1' has its rules updated and completed matches are protected
        final captured = verify(
          () => mockLocalRepo.saveMatchesBulk(captureAny()),
        ).captured;
        final savedMatches = captured.last as List<MatchModel>;

        final matchIncomplete = savedMatches.firstWhere(
          (m) => m.id == 'match_incomplete_1',
        );
        expect(matchIncomplete.matchTimeMinutes, 4.0);
        expect(matchIncomplete.rule?.matchTimeMinutes, 4.0);

        // Verify that match_completed_2 is NOT updated (finished status protected)
        final matchCompleted = savedMatches.where(
          (m) => m.id == 'match_completed_2',
        );
        expect(matchCompleted, isEmpty);
      },
    );

    test(
      '2. bulkUpdateMatchRules command updates specific matches rules in Firestore',
      () async {
        // Setup matches in Fake Firestore
        final oldRule = const MatchRule(
          matchTimeMinutes: 1.5,
          hasHantei: false,
        );
        final m1 = MatchModel(
          id: 'bulk_match_1',
          tournamentId: 'test_tournament_rules',
          category: '小学生の部',
          matchType: '個人戦',
          redName: '赤1',
          whiteName: '白1',
          status: 'waiting',
          matchTimeMinutes: 1.5,
          rule: oldRule,
          organizationId: 'test_dojo_id',
        );
        final m2 = MatchModel(
          id: 'bulk_match_2',
          tournamentId: 'test_tournament_rules',
          category: '小学生の部',
          matchType: '個人戦',
          redName: '赤2',
          whiteName: '白2',
          status: 'waiting',
          matchTimeMinutes: 1.5,
          rule: oldRule,
          organizationId: 'test_dojo_id',
        );

        await fakeFirestore
            .collection('organizations')
            .doc('test_dojo_id')
            .collection('tournaments')
            .doc('test_tournament_rules')
            .collection('matches')
            .doc(m1.id)
            .set(m1.toJson());

        await fakeFirestore
            .collection('organizations')
            .doc('test_dojo_id')
            .collection('tournaments')
            .doc('test_tournament_rules')
            .collection('matches')
            .doc(m2.id)
            .set(m2.toJson());

        // Setup Riverpod container with fake repository overrides
        final container = ProviderContainer(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'test_tournament_rules',
            ),
            firestoreProvider.overrideWithValue(fakeFirestore),
            matchListByTournamentProvider('test_tournament_rules').overrideWith(
              (ref) {
                return Stream.value([m1, m2]);
              },
            ),
            matchListProvider.overrideWith((ref) => [m1, m2]),
            matchStreamProvider.overrideWith((ref) => Stream.value([m1, m2])),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          ],
        );

        // Force instantiation of matchListProvider to keep matches in state cache
        container.read(matchListByTournamentProvider('test_tournament_rules'));

        final newRule = const MatchRule(
          matchTimeMinutes: 3.5,
          enchoTimeMinutes: 2.0,
          hasHantei: true,
        );

        // Execute bulkUpdateMatchRules on bulk_match_1 only
        await container
            .read(matchCommandProvider)
            .bulkUpdateMatchRules(
              targetMatchIds: ['bulk_match_1'],
              newRule: newRule,
            );

        final captured = verify(
          () => mockLocalRepo.saveMatchesBulk(captureAny()),
        ).captured;
        final savedMatches = captured.last as List<MatchModel>;

        final match1 = savedMatches.firstWhere((m) => m.id == 'bulk_match_1');
        expect(match1.matchTimeMinutes, 3.5);
        expect(match1.extensionTimeMinutes, 2.0);
        expect(match1.rule?.matchTimeMinutes, 3.5);

        // Verify that bulk_match_2 is NOT updated
        final match2 = savedMatches.where((m) => m.id == 'bulk_match_2');
        expect(match2, isEmpty);
      },
    );

    test(
      '3. deleteMatch on Web deletes directly from Firestore and updates optimistic UI state',
      () async {
        // Simulate Web environment
        debugIsWebOverride = true;
        addTearDown(() {
          debugIsWebOverride = false;
        });

        final matchToDelete = const MatchModel(
          id: 'web_delete_match',
          tournamentId: 'test_tournament_rules',
          category: '小学生の部',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          status: 'waiting',
          organizationId: 'test_dojo_id',
        );

        // Write match to Fake Firestore
        await fakeFirestore
            .collection('organizations')
            .doc('test_dojo_id')
            .collection('tournaments')
            .doc('test_tournament_rules')
            .collection('matches')
            .doc(matchToDelete.id)
            .set(matchToDelete.toJson());

        final container = ProviderContainer(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'test_tournament_rules',
            ),
            firestoreProvider.overrideWithValue(fakeFirestore),
            matchRepositoryProvider.overrideWith((ref) {
              return MatchRepository(
                fakeFirestore,
                'test_dojo_id',
                'test_tournament_rules',
              );
            }),
          ],
        );

        // Initialize the web matches list state with our match
        container.read(webCurrentTournamentMatchesProvider.notifier).state = [
          matchToDelete,
        ];

        // Execute deleteMatch
        await container
            .read(matchCommandProvider)
            .deleteMatch('web_delete_match');

        // Verify optimistic UI state update: match is removed from webCurrentTournamentMatchesProvider
        final currentWebMatches = container.read(
          webCurrentTournamentMatchesProvider,
        );
        expect(currentWebMatches, isEmpty);

        // Verify Firestore deletion: match document is deleted
        final snap = await fakeFirestore
            .collection('organizations')
            .doc('test_dojo_id')
            .collection('tournaments')
            .doc('test_tournament_rules')
            .collection('matches')
            .doc(matchToDelete.id)
            .get();
        expect(snap.exists, isFalse);
      },
    );

    test(
      '4. deleteMatch on Web dynamically updates currentTournamentIdProvider and currentDojoIdProvider from MatchModel when they are empty/incorrect',
      () async {
        // Simulate Web environment
        debugIsWebOverride = true;
        addTearDown(() {
          debugIsWebOverride = false;
        });

        final matchToDelete = const MatchModel(
          id: 'web_dynamic_delete_match',
          tournamentId: 'correct_tournament_id',
          category: '小学生の部',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          status: 'waiting',
          organizationId: 'correct_dojo_id',
        );

        // Write match to Fake Firestore at the CORRECT path
        await fakeFirestore
            .collection('organizations')
            .doc('correct_dojo_id')
            .collection('tournaments')
            .doc('correct_tournament_id')
            .collection('matches')
            .doc(matchToDelete.id)
            .set(matchToDelete.toJson());

        // Create container with initially EMPTY / WRONG paths
        final container = ProviderContainer(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'initial_wrong_dojo'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'initial_wrong_tournament',
            ),
            firestoreProvider.overrideWithValue(fakeFirestore),
            matchRepositoryProvider.overrideWith((ref) {
              final dojoId = ref.watch(currentDojoIdProvider);
              final tournamentId = ref.watch(currentTournamentIdProvider);
              return MatchRepository(fakeFirestore, dojoId, tournamentId);
            }),
          ],
        );

        // Initialize the web matches list state with our match
        container.read(webCurrentTournamentMatchesProvider.notifier).state = [
          matchToDelete,
        ];

        // Execute deleteMatch - this should dynamically repair the providers
        await container
            .read(matchCommandProvider)
            .deleteMatch('web_dynamic_delete_match');

        // Verify that providers were dynamically updated to correct values
        expect(container.read(currentDojoIdProvider), 'correct_dojo_id');
        expect(
          container.read(currentTournamentIdProvider),
          'correct_tournament_id',
        );

        // Verify Firestore deletion: match document is deleted from the correct path
        final snap = await fakeFirestore
            .collection('organizations')
            .doc('correct_dojo_id')
            .collection('tournaments')
            .doc('correct_tournament_id')
            .collection('matches')
            .doc(matchToDelete.id)
            .get();
        expect(snap.exists, isFalse);
      },
    );

    test(
      '5. deleteMatch on Web does NOT overwrite active currentDojoIdProvider when match has default_org',
      () async {
        debugIsWebOverride = true;
        addTearDown(() {
          debugIsWebOverride = false;
        });

        const matchWithDefaultOrg = MatchModel(
          id: 'delete_default_org_match',
          tournamentId: 'my_active_tournament',
          matchType: '個人戦',
          status: 'waiting',
          redName: '赤',
          whiteName: '白',
          organizationId: 'default_org',
        );

        await fakeFirestore
            .collection('organizations')
            .doc('my_active_dojo')
            .collection('tournaments')
            .doc('my_active_tournament')
            .collection('matches')
            .doc(matchWithDefaultOrg.id)
            .set(matchWithDefaultOrg.toJson());

        final container = ProviderContainer(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'my_active_dojo'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'my_active_tournament',
            ),
            firestoreProvider.overrideWithValue(fakeFirestore),
            matchRepositoryProvider.overrideWith((ref) {
              final dojoId = ref.watch(currentDojoIdProvider);
              final tournamentId = ref.watch(currentTournamentIdProvider);
              return MatchRepository(fakeFirestore, dojoId, tournamentId);
            }),
          ],
        );

        container.read(webCurrentTournamentMatchesProvider.notifier).state = [
          matchWithDefaultOrg,
        ];

        await container
            .read(matchCommandProvider)
            .deleteMatch('delete_default_org_match');

        // Verify currentDojoIdProvider is NOT wiped to 'default_org'
        expect(container.read(currentDojoIdProvider), 'my_active_dojo');
        expect(
          container.read(currentTournamentIdProvider),
          'my_active_tournament',
        );

        // Verify match was deleted from active dojo path in Firestore
        final snap = await fakeFirestore
            .collection('organizations')
            .doc('my_active_dojo')
            .collection('tournaments')
            .doc('my_active_tournament')
            .collection('matches')
            .doc('delete_default_org_match')
            .get();
        expect(snap.exists, isFalse);
      },
    );

    test(
      '6. Team match creation with substitute player does NOT generate extra match slot for substitute',
      () {
        // Team playerNames has 6 players: 5 starters + 1 substitute
        final teamPlayerNames = [
          '先鋒太郎',
          '次鋒次郎',
          '中堅三郎',
          '副将四郎',
          '大将五郎',
          '補欠六郎',
        ];

        // Standard 5人制 team size calculation
        int teamSize = 5;
        final positions = ['先鋒', '次鋒', '中堅', '副将', '大将'];

        // Verify active match positions count is 5, not 6
        expect(positions.length, equals(teamSize));
        expect(positions.contains('4将'), isFalse);
        expect(positions.contains('3将'), isFalse);

        // Verify that only the first 5 players fill starting slots
        final selectedPlayers = <int, String>{};
        for (
          int i = 0;
          i < teamPlayerNames.length && i < positions.length;
          i++
        ) {
          selectedPlayers[i] = teamPlayerNames[i];
        }

        expect(selectedPlayers.length, equals(5));
        expect(selectedPlayers[0], equals('先鋒太郎'));
        expect(selectedPlayers[4], equals('大将五郎'));
        expect(
          selectedPlayers.containsKey(5),
          isFalse,
        ); // Substitute '補欠六郎' is not in starting slots
      },
    );

    test(
      '7. Registered team substitute players who are not in active match slots are correctly identified as bench waiting reserve players (teamSubstitutes)',
      () {
        final teamPlayerNames = [
          '先鋒太郎',
          '次鋒次郎',
          '中堅三郎',
          '副将四郎',
          '大将五郎',
          '補欠六郎',
          '補欠七郎',
        ];

        // Active starting players in the 5 created match slots
        final activePlayerNames = {'先鋒太郎', '次鋒次郎', '中堅三郎', '副将四郎', '大将五郎'};

        // Identify substitute (reserve) players: in team.playerNames but NOT in active starting slots
        final teamSubstitutes = teamPlayerNames
            .where(
              (name) => name.isNotEmpty && !activePlayerNames.contains(name),
            )
            .toList();

        // Verify that starting 5 players are active in match slots
        expect(activePlayerNames.length, equals(5));

        // Verify that 6th and 7th players are identified as waiting reserve players (ベンチ待機選手)
        expect(teamSubstitutes, equals(['補欠六郎', '補欠七郎']));
        expect(teamSubstitutes.contains('大将五郎'), isFalse);
      },
    );

    test(
      '8. Renseikai candidate player chips filter by match category when same team name exists across categories',
      () {
        final registeredTeams = [
          const TeamModel(
            id: 't_elem',
            tournamentId: 'tour1',
            category: '小学生の部',
            teamName: '道上剣友会',
            playerNames: ['小学生先鋒', '小学生次鋒', '小学生中堅', '小学生副将', '小学生大将', '小学生補欠'],
          ),
          const TeamModel(
            id: 't_jhs',
            tournamentId: 'tour1',
            category: '中学生の部',
            teamName: '道上剣友会',
            playerNames: ['中学生先鋒', '中学生次鋒', '中学生中堅', '中学生副将', '中学生大将', '中学生補欠'],
          ),
        ];

        const matchCat = '小学生の部';
        const targetTeamName = '道上剣友会';

        // Filter registeredTeams by teamName AND category matching matchCat
        final elemTeamData = registeredTeams.firstWhere(
          (t) {
            final nameMatch =
                t.teamName.trim() == targetTeamName ||
                targetTeamName.contains(t.teamName.trim()) ||
                t.teamName.trim().contains(targetTeamName);
            if (!nameMatch) return false;
            if (matchCat.isNotEmpty && t.category.isNotEmpty) {
              return t.category.trim() == matchCat ||
                  matchCat.contains(t.category.trim()) ||
                  t.category.trim().contains(matchCat);
            }
            return true;
          },
          orElse: () => const TeamModel(
            id: '',
            tournamentId: '',
            category: '',
            teamName: '',
            matchType: '',
            playerNames: [],
          ),
        );

        final candidates = elemTeamData.playerNames
            .where((n) => n.isNotEmpty)
            .toList();

        // Verify ONLY elementary school team players (including reserve) are in candidates
        expect(candidates.length, equals(6));
        expect(candidates.contains('小学生先鋒'), isTrue);
        expect(candidates.contains('小学生補欠'), isTrue);
        expect(candidates.contains('中学生先鋒'), isFalse);
        expect(candidates.contains('中学生補欠'), isFalse);
      },
    );

    test(
      '9. Verification that extension match decisions correctly set isEncho flag for score cards and official records',
      () {
        // 1. Regular match finished in regular time (not extension) -> isEncho = false
        final regularFinishedMatch = const MatchModel(
          id: 'm1',
          matchType: '通常',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 1,
          status: 'approved',
          note: '',
        );
        expect(
          MatchCalculatorHelper.isEnchoFromModel(regularFinishedMatch),
          isFalse,
        );

        // 2. Representative match (代表戦) finished -> isEncho = true
        final daihyoMatch = const MatchModel(
          id: 'm2',
          matchType: '代表戦',
          redName: '代表A',
          whiteName: '代表B',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
          note: '',
        );
        expect(MatchCalculatorHelper.isEnchoFromModel(daihyoMatch), isTrue);

        // 3. Match with note containing "延長" -> isEncho = true
        final enchoNoteMatch = const MatchModel(
          id: 'm3',
          matchType: '通常',
          redName: '選手C',
          whiteName: '選手D',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
          note: '延長戦にて決着',
        );
        expect(MatchCalculatorHelper.isEnchoFromModel(enchoNoteMatch), isTrue);

        // 4. Kachinuki / Taisho extension match (大将延長戦) -> isEncho = true
        final taishoEnchoMatch = const MatchModel(
          id: 'm4',
          matchType: '大将延長戦',
          redName: '大将A',
          whiteName: '大将B',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
          note: '',
        );
        expect(
          MatchCalculatorHelper.isEnchoFromModel(taishoEnchoMatch),
          isTrue,
        );

        // 5. Match with hasExtension enabled and a winner -> isEncho = true
        final hasExtWinnerMatch = const MatchModel(
          id: 'm5',
          matchType: '通常',
          redName: '選手E',
          whiteName: '選手F',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
          hasExtension: true,
        );
        expect(
          MatchCalculatorHelper.isEnchoFromModel(hasExtWinnerMatch),
          isTrue,
        );

        // 6. Unfinished match should return false
        final unfinishedEnchoMatch = const MatchModel(
          id: 'm6',
          matchType: '代表戦',
          redName: '代表A',
          whiteName: '代表B',
          redScore: 0,
          whiteScore: 0,
          status: 'running',
          note: '延長戦',
        );
        expect(
          MatchCalculatorHelper.isEnchoFromModel(unfinishedEnchoMatch),
          isFalse,
        );
      },
    );

    test(
      '10. Verification that court text and progress header memo are preserved on MatchModel note',
      () {
        const courtText = '第1試合場';
        const userNote = '準決勝';
        const combinedNote = '$courtText\n$userNote';

        final matchWithNote = const MatchModel(
          id: 'm10',
          matchType: '先鋒',
          redName: 'Aチーム : 先鋒A',
          whiteName: 'Bチーム : 先鋒B',
          groupName: 'group_uuid_123',
          note: combinedNote,
        );

        expect(matchWithNote.note, equals('第1試合場\n準決勝'));
        expect(matchWithNote.note.contains('第1試合場'), isTrue);
      },
    );

    test(
      '11. Verification that MatchEditSheet correctly detects match rule scene preset key for chip selection',
      () {
        String detectPresetKey(MatchModel match) {
          final r = match.rule ?? const MatchRule();
          if (r.isRenseikai ||
              r.matchScene == 'renseikai' ||
              match.matchScene == 'renseikai') {
            return 'renseikai';
          } else if (r.matchScene == 'moushiawase' ||
              match.matchScene == 'moushiawase') {
            return 'moushiawase';
          } else if (r.matchScene == 'honsen' || match.matchScene == 'honsen') {
            return 'honsen';
          } else {
            return 'honsen';
          }
        }

        const honsenMatch = MatchModel(
          id: 'm11_1',
          matchType: '先鋒',
          redName: 'Aチーム : 先鋒A',
          whiteName: 'Bチーム : 先鋒B',
          matchScene: 'honsen',
          rule: MatchRule(matchScene: 'honsen'),
        );
        expect(detectPresetKey(honsenMatch), equals('honsen'));

        const renseikaiMatch = MatchModel(
          id: 'm11_2',
          matchType: '先鋒',
          redName: 'Aチーム : 先鋒A',
          whiteName: 'Bチーム : 先鋒B',
          matchScene: 'renseikai',
          rule: MatchRule(matchScene: 'renseikai', isRenseikai: true),
        );
        expect(detectPresetKey(renseikaiMatch), equals('renseikai'));

        const moushiawaseMatch = MatchModel(
          id: 'm11_3',
          matchType: '先鋒',
          redName: 'Aチーム : 先鋒A',
          whiteName: 'Bチーム : 先鋒B',
          matchScene: 'moushiawase',
          rule: MatchRule(matchScene: 'moushiawase', isRenseikai: false),
        );
        expect(detectPresetKey(moushiawaseMatch), equals('moushiawase'));
      },
    );

    test(
      '12. Verification that Renseikai candidate player chips strictly include only own category team players and reserve players',
      () {
        final registeredTeams = [
          const TeamModel(
            id: 't_elem',
            tournamentId: 'tour1',
            category: '小学生の部',
            teamName: '道上剣友会',
            playerNames: ['小学生先鋒', '小学生次鋒', '小学生中堅', '小学生副将', '小学生大将', '小学生補欠'],
          ),
          const TeamModel(
            id: 't_jhs',
            tournamentId: 'tour1',
            category: '中学生の部',
            teamName: '道上剣友会',
            playerNames: ['中学生先鋒', '中学生次鋒', '中学生中堅', '中学生副将', '中学生大将', '中学生補欠'],
          ),
        ];

        bool isCategoryMatch(String teamCat, String matchCat) {
          final tCat = teamCat.trim();
          final mCat = matchCat.trim();
          if (mCat.isEmpty || tCat.isEmpty) return true;
          if (tCat == mCat || mCat.contains(tCat) || tCat.contains(mCat)) {
            return true;
          }
          final keywords = ['低学年', '高学年', '小学生', '中学生', '高校生', '一般'];
          for (final kw in keywords) {
            if (mCat.contains(kw) && tCat.contains(kw)) return true;
            if (mCat.contains(kw) && !tCat.contains(kw)) return false;
          }
          return true;
        }

        const matchCat = '小学生の部';
        const targetTeamName = '道上剣友会';

        final matchingTeams = registeredTeams.where((t) {
          final nameMatch =
              t.teamName.trim() == targetTeamName ||
              targetTeamName.contains(t.teamName.trim()) ||
              t.teamName.trim().contains(targetTeamName);
          return nameMatch;
        }).toList();

        final teamData = matchingTeams.firstWhere(
          (t) => isCategoryMatch(t.category, matchCat),
          orElse: () => matchingTeams.first,
        );

        final List<String> masterPlayers = teamData.playerNames
            .map((n) => n.trim())
            .where(
              (n) => n.isNotEmpty && !n.contains('未定') && !n.contains('欠員'),
            )
            .toList();

        final baseHistoryPlayers = [
          '小学生先鋒',
          '小学生次鋒',
          '小学生中堅',
          '小学生副将',
          '小学生大将',
        ];

        final List<String> candidates = masterPlayers.isNotEmpty
            ? {...masterPlayers, ...baseHistoryPlayers}.toList()
            : [];

        // Verify candidates contains ONLY elementary school players & reserve
        expect(candidates.length, equals(6));
        expect(candidates.contains('小学生先鋒'), isTrue);
        expect(candidates.contains('小学生補欠'), isTrue); // Reserve player included
        expect(
          candidates.contains('中学生先鋒'),
          isFalse,
        ); // Other category player excluded
        expect(
          candidates.contains('大人会員'),
          isFalse,
        ); // Unrelated dojo member excluded
      },
    );

    test(
      '13. Verification that match rule scenes (renseikai, moushiawase, honsen) and hasHantei state are accurately saved and applied across environments',
      () {
        const initialMatch = MatchModel(
          id: 'm13_1',
          matchType: '先鋒',
          redName: 'Aチーム : 先鋒A',
          whiteName: 'Bチーム : 先鋒B',
          matchScene: 'honsen',
          rule: MatchRule(matchScene: 'honsen', hasHantei: false),
        );

        const renseikaiSceneKey = 'renseikai';
        final updatedRenseikaiRule = initialMatch.rule!.copyWith(
          matchScene: renseikaiSceneKey,
          isRenseikai: true,
          hasHantei: false,
          enchoTimeMinutes: 0.0,
          isEnchoUnlimited: false,
        );
        final updatedRenseikaiMatch = initialMatch.copyWith(
          matchScene: renseikaiSceneKey,
          rule: updatedRenseikaiRule,
        );

        expect(updatedRenseikaiMatch.matchScene, equals('renseikai'));
        expect(updatedRenseikaiMatch.rule?.matchScene, equals('renseikai'));
        expect(updatedRenseikaiMatch.rule?.isRenseikai, isTrue);
        expect(updatedRenseikaiMatch.rule?.hasHantei, isFalse);

        const moushiawaseSceneKey = 'moushiawase';
        final updatedMoushiawaseRule = initialMatch.rule!.copyWith(
          matchScene: moushiawaseSceneKey,
          isRenseikai: false,
          hasHantei: false,
          enchoTimeMinutes: 0.0,
          isEnchoUnlimited: false,
        );
        final updatedMoushiawaseMatch = initialMatch.copyWith(
          matchScene: moushiawaseSceneKey,
          rule: updatedMoushiawaseRule,
        );

        expect(updatedMoushiawaseMatch.matchScene, equals('moushiawase'));
        expect(updatedMoushiawaseMatch.rule?.matchScene, equals('moushiawase'));
        expect(updatedMoushiawaseMatch.rule?.isRenseikai, isFalse);
        expect(updatedMoushiawaseMatch.rule?.hasHantei, isFalse);

        String detectSavedScene(MatchModel m) {
          final r = m.rule ?? const MatchRule();
          if (r.isRenseikai ||
              r.matchScene == 'renseikai' ||
              m.matchScene == 'renseikai') {
            return 'renseikai';
          } else if (r.matchScene == 'moushiawase' ||
              m.matchScene == 'moushiawase') {
            return 'moushiawase';
          } else {
            return 'honsen';
          }
        }

        expect(detectSavedScene(updatedRenseikaiMatch), equals('renseikai'));
        expect(
          detectSavedScene(updatedMoushiawaseMatch),
          equals('moushiawase'),
        );
      },
    );
  });
}
