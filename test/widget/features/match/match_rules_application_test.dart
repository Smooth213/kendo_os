import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
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

  group('[Widget] Match Rules Propagation & Application テスト', () {
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
        () => mockLocalRepo.savePendingCommandsBulk(any()),
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

    testWidgets('部門ルール画面において未終了試合に対して新しいルールが一括適用されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Prepare matches with old rules (e.g. 5.0 minutes match time)
      final oldRule = const MatchRule(matchTimeMinutes: 5.0, hasHantei: false);
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
            matchListByTournamentProvider('test_tournament_rules').overrideWith(
              (ref) {
                return Stream.value(matches);
              },
            ),
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
      await tester.safePumpAndSettle();

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
      await tester.safePumpAndSettle();
      await tester.tap(find.text('編集'));
      await tester.safePumpAndSettle();

      // Change normal match time preset from 2分 to 4分
      expect(find.text('通常戦のルール'), findsOneWidget);
      await tester.tap(find.text('4分'));
      await tester.safePumpAndSettle();

      // Click save button
      await tester.tap(find.text('設定を保存'));
      await tester.safePumpAndSettle();

      // Verify bulk apply confirmation dialog appears (as we have 'match_incomplete_1' under '小学生の部')
      expect(find.text('作成済みの試合に一括適用しますか？'), findsOneWidget);

      // Tap "一括適用する"
      await tester.tap(find.text('一括適用する'));
      await tester.safePumpAndSettle();

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
    });
  });
}
