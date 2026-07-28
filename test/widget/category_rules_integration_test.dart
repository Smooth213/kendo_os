import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/category_rules_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('CategoryRules & SetupMatchFormat Integration Widget Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TournamentModel testTournament;
    late TeamModel testTeam;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();

      testTournament = TournamentModel(
        id: 'test_tournament',
        organizationId: 'test_dojo_id',
        name: '千葉テスト大会',
        date: DateTime(2026, 7, 25),
        venue: 'テスト体育館',
        categories: ['小学生の部'],
        categoryRules: {
          '小学生の部': CategoryRuleSet(
            normalRule: const MatchRule(matchTimeMinutes: 2.0, hasHantei: true),
            advancedRule: const MatchRule(
              matchTimeMinutes: 3.0,
              isEnchoUnlimited: true,
            ),
            useAdvancedRule: true,
          ),
        },
      );

      testTeam = const TeamModel(
        id: 'team_1',
        tournamentId: 'test_tournament',
        category: '小学生の部',
        teamName: '千代田チーム',
        matchType: '個人戦',
        playerNames: ['山田'],
      );
    });

    testWidgets('1. CategoryRulesScreen list and edit rules flow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
            tournamentProvider('test_tournament').overrideWith((ref) {
              return Stream.value(testTournament);
            }),
            matchListByTournamentProvider('test_tournament').overrideWith((
              ref,
            ) {
              return Stream.value([]);
            }),
          ],
          child: const MaterialApp(
            home: CategoryRulesScreen(tournamentId: 'test_tournament'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Check category card is rendered
      expect(find.text('小学生の部'), findsAtLeast(1));
      expect(find.textContaining('通常戦: 2分'), findsOneWidget);
      expect(find.textContaining('上位戦: 3分'), findsOneWidget);

      // Swipe left on the card to reveal edit action
      await tester.drag(
        find.byKey(const ValueKey('slidable_rule_小学生の部')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();

      // Inside rule editor
      expect(find.text('準決勝・決勝は別ルールにする'), findsOneWidget);
      expect(find.text('通常戦のルール'), findsOneWidget);
      expect(find.text('上位戦（準決勝・決勝）'), findsOneWidget);

      // Tap "通常戦のルール" to verify editing page
      expect(find.text('試合時間'), findsOneWidget);
      expect(find.text('2分'), findsAtLeast(1));

      // Verify Match Format dynamic form visibility
      expect(find.text('試合方式'), findsOneWidget);
      // "代表戦あり（団体戦用）" is hidden for Individual matches by default
      expect(find.text('代表戦あり（団体戦用）'), findsNothing);

      // Change Match Format to Team Match
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('団体戦 (トーナメント)').last);
      await tester.pumpAndSettle();

      // Representative Match setting should now be visible!
      expect(find.text('代表戦あり（団体戦用）'), findsOneWidget);
    });

    testWidgets(
      '2. SetupMatchFormatScreen dynamic category rules load and auto/manual round toggle',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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
              tournamentProvider('test_tournament').overrideWith((ref) {
                return Stream.value(testTournament);
              }),
              registeredTeamsProvider('test_tournament').overrideWith((ref) {
                return Stream.value([testTeam]);
              }),
              teamRepositoryProvider.overrideWith((ref) {
                return TeamRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
              playerRepositoryProvider.overrideWith((ref) {
                return PlayerRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
            ],
            child: const MaterialApp(
              home: SetupMatchFormatScreen(tournamentId: 'test_tournament'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Page 1: Select "小学生" (Major) + "全体" (Minor) -> "小学生の部"
        expect(find.text('小学生'), findsOneWidget);
        await tester.tap(
          find.widgetWithText(ChoiceChip, '小学生'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.text('全体'), findsOneWidget);
        await tester.tap(
          find.widgetWithText(ChoiceChip, '全体'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Select "千代田チーム"
        expect(find.text('千代田チーム'), findsOneWidget);
        await tester.tap(find.text('千代田チーム'));
        await tester.pumpAndSettle();

        // Tap Next to go to Page 2 (Summary & Details Page)
        await tester.tap(find.text('次へ進む'));
        await tester.pumpAndSettle();

        // Enter "準決勝" in the note field to trigger auto advanced rules toggle
        final noteField = find.widgetWithText(TextField, '試合詳細（任意）');
        expect(noteField, findsOneWidget);
        await tester.enterText(noteField, 'Aコート 準決勝 第1試合');
        await tester.pumpAndSettle();

        // Verify rule switcher toggle appeared and "上位戦のルール" is selected
        expect(find.text('適用ルール（自動判別・手動切替）'), findsOneWidget);
        expect(find.text('上位戦のルール'), findsOneWidget);

        // Tap "通常戦のルール" to manually override
        await tester.tap(find.text('通常戦のルール'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('3. CategoryRulesScreen detailed rule sheet popup on tap', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
            tournamentProvider('test_tournament').overrideWith((ref) {
              return Stream.value(testTournament);
            }),
            matchListByTournamentProvider('test_tournament').overrideWith((
              ref,
            ) {
              return Stream.value([]);
            }),
          ],
          child: const MaterialApp(
            home: CategoryRulesScreen(tournamentId: 'test_tournament'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Check category card is rendered
      expect(find.text('小学生の部'), findsAtLeast(1));

      // Tap on the category card
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('slidable_rule_小学生の部')),
          matching: find.text('小学生の部'),
        ),
      );
      await tester.pumpAndSettle();

      // Bottom sheet should open with detailed rules
      expect(find.text('小学生の部 のルール設定'), findsOneWidget);
      expect(find.text('通常戦ルール'), findsOneWidget);
      expect(find.text('上位戦（準決勝・決勝等）ルール'), findsOneWidget);
      expect(find.text('上位戦 適用ワード'), findsOneWidget);

      // We should see a close button
      expect(find.text('閉じる'), findsOneWidget);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      // Bottom sheet should be closed
      expect(find.text('小学生の部 のルール設定'), findsNothing);
    });
  });
}
