import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('League Representative Match Rules Integration & Domain Tests', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test(
      '1. Domain Layer - Timer resolution count-up / count-down for representative matches',
      () {
        final now = DateTime(2026, 7, 1, 12, 0, 0);

        // A: 1-ippon representative match (unlimited time, matchTimeMinutes = 0.0) -> should count up
        final unlimitedMatch = MatchModel(
          id: 'daihyo_unlimited',
          matchType: '代表戦',
          matchTimeMinutes: 0.0,
          status: 'ready',
          redName: 'Red',
          whiteName: 'White',
          events: [],
        );
        final remainingUnlimited = unlimitedMatch
            .copyWith(timerStartedAt: now.subtract(const Duration(seconds: 45)))
            .calculateRemainingSeconds(now);
        expect(remainingUnlimited, 45); // Counts up to 45 seconds

        // B: 3-ippon representative match (limited time, matchTimeMinutes = 3.0) -> should count down
        final limitedMatch = MatchModel(
          id: 'daihyo_limited',
          matchType: '代表戦',
          matchTimeMinutes: 3.0,
          status: 'ready',
          redName: 'Red',
          whiteName: 'White',
          events: [],
        );
        final remainingLimited = limitedMatch
            .copyWith(timerStartedAt: now.subtract(const Duration(seconds: 45)))
            .calculateRemainingSeconds(now);
        expect(
          remainingLimited,
          135,
        ); // 180 - 45 = 135 seconds remaining (counts down)
      },
    );

    testWidgets(
      '2. UI Layer - setup_match_format_screen renders detailed representative settings under league mode',
      (WidgetTester tester) async {
        // Set large size to build all lazy ListView items
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final testTeam = const TeamModel(
          id: 'team_1',
          tournamentId: 'test_tournament',
          category: '小学生の部',
          teamName: '千代田チーム',
          matchType: 'リーグ団体戦',
          playerNames: ['山田', '佐藤', '鈴木'],
        );

        // Render setup screen with Riverpod overrides
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              playerRepositoryProvider.overrideWith((ref) {
                final dojoId = ref.watch(currentDojoIdProvider);
                return PlayerRepository(
                  dojoId: dojoId,
                  firestore: fakeFirestore,
                );
              }),
              teamRepositoryProvider.overrideWith((ref) {
                final dojoId = ref.watch(currentDojoIdProvider);
                return TeamRepository(dojoId: dojoId, firestore: fakeFirestore);
              }),
              // Direct override of the family provider
              registeredTeamsProvider('test_tournament').overrideWith((ref) {
                return Stream.value([testTeam]);
              }),
            ],
            child: const MaterialApp(
              home: SetupMatchFormatScreen(tournamentId: 'test_tournament'),
            ),
          ),
        );

        // Wait for stream to emit value and rebuild UI
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Page 0 should display the team "千代田チーム"
        expect(find.text('千代田チーム'), findsOneWidget);

        // Select the team "千代田チーム"
        await tester.tap(find.text('千代田チーム'));
        await tester.pumpAndSettle();

        // Tap '次へ進む' to go to Page 1
        expect(find.text('次へ進む'), findsOneWidget);
        await tester.tap(find.text('次へ進む'));
        await tester.pumpAndSettle();

        // Page 1 should display match formats (confirming "リーグ団体戦" is selected/applied)
        expect(find.text('リーグ団体戦'), findsOneWidget);

        // Tap '次へ進む' to go to Page 2 (rules configuration page)
        await tester.tap(find.text('次へ進む'));
        await tester.pumpAndSettle();

        // We should be on Page 2 rules page, which should display '代表戦あり' switch
        final switchFinder = find.widgetWithText(SwitchListTile, '代表戦あり');
        expect(switchFinder, findsOneWidget);

        // Initially, detailed representative settings should NOT be visible
        expect(find.text('代表戦の勝敗数'), findsNothing);

        // Toggle '代表戦あり' to true
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        // Detailed settings should now appear in the UI
        expect(find.text('代表戦の勝敗数'), findsOneWidget);
        expect(find.text('1本'), findsOneWidget);
        expect(find.text('3本'), findsOneWidget);
        expect(find.text('延長戦を行う'), findsOneWidget);
      },
    );
  });
}
