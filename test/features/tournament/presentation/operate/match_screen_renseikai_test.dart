import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/last_used_settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_timer_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';

class MockMatchRuleNotifier extends MatchRuleNotifier {
  final MatchRule initialRule;
  MockMatchRuleNotifier(this.initialRule);

  @override
  MatchRule build() => initialRule;
}

class MockSettingsNotifier extends SettingsNotifier {
  final SettingsModel initialSettings;
  MockSettingsNotifier(this.initialSettings);

  @override
  SettingsModel build() => initialSettings;
}

class MockRenseikaiMasterTimerNotifier extends RenseikaiMasterTimerNotifier {
  final int initialValue;
  MockRenseikaiMasterTimerNotifier(this.initialValue);

  @override
  int build(String arg) {
    state = initialValue;
    return initialValue;
  }

  @override
  void initialize(int initialSeconds) {
    state = initialValue;
  }

  @override
  void start() {}

  @override
  void pause() {}

  @override
  void toggleTimer() {}
}

void main() {
  group('🛡️ MatchScreen Renseikai ChoiceChips Player Selection Widget Tests', () {
    testWidgets(
      '1. Dialog should present own-team players as ChoiceChips and update TextField on tap',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        const mockMatch = MatchModel(
          id: 'test_match_renseikai',
          tournamentId: 'tourney_1',
          matchType: '錬成会',
          redName: '自チーム : 武田 修二',
          whiteName: '相手 : 選手A',
          status: 'finished',
          groupName: '団体A',
          order: 1.0,
        );

        const mockMatch2 = MatchModel(
          id: 'test_match_renseikai_2',
          tournamentId: 'tourney_1',
          matchType: '錬成会',
          redName: '自チーム : 佐藤 健',
          whiteName: '相手 : 選手B',
          status: 'waiting',
          groupName: '団体A',
          order: 2.0,
        );

        final router = GoRouter(
          initialLocation: '/match/test_match_renseikai',
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
            matchListProvider.overrideWith((ref) => [mockMatch, mockMatch2]),
            matchRuleProvider.overrideWith(
              () => MockMatchRuleNotifier(
                const MatchRule(
                  teamName: '自チーム',
                  isRenseikai: true,
                  renseikaiType: '時間制',
                  positions: ['先鋒', '大将'],
                ),
              ),
            ),
            lastUsedSettingsProvider.overrideWith((ref) => {'matchTime': 3.0}),
            renseikaiMasterTimerProvider.overrideWith(
              () => MockRenseikaiMasterTimerNotifier(1800),
            ),
            matchViewStateProvider('test_match_renseikai').overrideWith(
              (ref) => MatchViewState(
                scoreText: '2 - 0',
                redScore: 2,
                whiteScore: 0,
                isEncho: false,
                winner: 'red',
                lastEventText: '',
                canUndo: false,
                statusText: '対戦終了',
                syncStatus: SyncStatus.synced,
                isViewOnly: false,
                isInputLocked: false,
                isAllDone: true,
                isTie: false,
                redCleanName: '武田 修二',
                whiteCleanName: '選手A',
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

        // Find the "追加して継続" GlassButton
        final nextBtnFinder = find.widgetWithText(GlassButton, '追加して継続');
        expect(nextBtnFinder, findsOneWidget);

        // Tap the button to launch the Renseikai match popup dialog
        await tester.tap(nextBtnFinder);
        await tester.pumpAndSettle();

        // Verify the dialog is displayed
        expect(find.text('次の試合を追加 (錬成会)'), findsOneWidget);

        // Verify that Red team players (武田 修二, 佐藤 健) are presented as ChoiceChips
        final chipTakedafinder = find.widgetWithText(ChoiceChip, '武田 修二');
        final chipSatofinder = find.widgetWithText(ChoiceChip, '佐藤 健');
        expect(chipTakedafinder, findsOneWidget);
        expect(chipSatofinder, findsOneWidget);

        // Verify that White team players (選手A, 選手B) are presented as ChoiceChips
        final chipAFinder = find.widgetWithText(ChoiceChip, '選手A');
        final chipBFinder = find.widgetWithText(ChoiceChip, '選手B');
        expect(chipAFinder, findsOneWidget);
        expect(chipBFinder, findsOneWidget);

        // Initially, the text fields are empty
        final textFields = find.byType(TextField);
        expect(textFields, findsNWidgets(2));

        final redTextField = tester.widget<TextField>(textFields.first);
        final whiteTextField = tester.widget<TextField>(textFields.last);
        expect(redTextField.controller?.text, isEmpty);
        expect(whiteTextField.controller?.text, isEmpty);

        // Tap the '佐藤 健' chip to select that player for Red
        await tester.tap(chipSatofinder);
        await tester.pumpAndSettle();

        // Verify that the red team TextField has been populated with '佐藤 健'
        expect(redTextField.controller?.text, '佐藤 健');

        // Tap the '選手B' chip to select that player for White
        await tester.tap(chipBFinder);
        await tester.pumpAndSettle();

        // Verify that the white team TextField has been populated with '選手B'
        expect(whiteTextField.controller?.text, '選手B');

        // Clean up
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        container.dispose();
      },
    );

    testWidgets(
      '2. Bottom sheet should present "確定して終了" button and transition to Match Finished dialog on tap',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        const mockMatch = MatchModel(
          id: 'test_match_renseikai_finish',
          tournamentId: 'tourney_1',
          matchType: '錬成会',
          redName: '自チーム : 武田 修二',
          whiteName: '相手 : 選手A',
          status: 'finished',
          groupName: '団体A',
          order: 1.0,
        );

        final router = GoRouter(
          initialLocation: '/match/test_match_renseikai_finish',
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
            matchRuleProvider.overrideWith(
              () => MockMatchRuleNotifier(
                const MatchRule(
                  teamName: '自チーム',
                  isRenseikai: true,
                  renseikaiType: '時間制',
                  positions: ['先鋒', '大将'],
                ),
              ),
            ),
            lastUsedSettingsProvider.overrideWith((ref) => {'matchTime': 3.0}),
            renseikaiMasterTimerProvider.overrideWith(
              () => MockRenseikaiMasterTimerNotifier(1800),
            ),
            settingsProvider.overrideWith(
              () => MockSettingsNotifier(
                const SettingsModel(
                  confirmBehavior: 'single',
                  showConfirmDialog: false,
                ),
              ),
            ),
            matchViewStateProvider('test_match_renseikai_finish').overrideWith(
              (ref) => MatchViewState(
                scoreText: '2 - 0',
                redScore: 2,
                whiteScore: 0,
                isEncho: false,
                winner: 'red',
                lastEventText: '',
                canUndo: false,
                statusText: '対戦終了',
                syncStatus: SyncStatus.synced,
                isViewOnly: false,
                isInputLocked: false,
                isAllDone: true,
                isTie: false,
                redCleanName: '武田 修二',
                whiteCleanName: '選手A',
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

        // Verify the "確定して終了" button is displayed on the bottom bar of match screen
        final finishBtnFinder = find.widgetWithText(ElevatedButton, '確定して終了');
        expect(finishBtnFinder, findsOneWidget);

        // Tap the "確定して終了" button
        await tester.tap(finishBtnFinder);
        await tester.pumpAndSettle();

        // Verify the final "対戦終了" dialog pops up
        expect(find.text('対戦終了'), findsOneWidget);

        // Clean up
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        container.dispose();
      },
    );
  });
}
