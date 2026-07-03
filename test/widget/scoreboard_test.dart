import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('🛡️ MatchScoreboard Design & Layout Verification Tests', () {
    testWidgets(
      'Scoreboard maintains size parameters, name font sizes, and point badge dimensions',
      (WidgetTester tester) async {
        // Set physical size to guarantee full layout rendering
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Setup a mock match with points to check scoreboard display
        final testMatch = MatchModel(
          id: 'test_scoreboard_match',
          tournamentId: 'tour_1',
          category: '一般',
          redName: '青龍道場 : 山田 太郎',
          whiteName: '白虎剣友会 : 山田 のりこ',
          matchType: '個人戦',
          status: 'finished',
          redScore: 2,
          whiteScore: 1,
          events: [
            ScoreEvent(
              id: 'ev1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: DateTime.now(),
            ),
            ScoreEvent(
              id: 'ev2',
              side: Side.red,
              strikeType: StrikeType.kote,
              isIppon: true,
              timestamp: DateTime.now(),
            ),
            ScoreEvent(
              id: 'ev3',
              side: Side.white,
              strikeType: StrikeType.dou,
              isIppon: true,
              timestamp: DateTime.now(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              matchViewStateUserIdProvider.overrideWith(
                (ref) => 'test_user_id',
              ),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              matchListProvider.overrideWithValue([testMatch]),
              scoreboardMatchIdProvider.overrideWithValue(
                'test_scoreboard_match',
              ),
              scoreboardMatchProvider.overrideWithValue(testMatch),
              scoreboardNameTapProvider.overrideWithValue((side) {}),
            ],
            child: const MaterialApp(home: Scaffold(body: MatchScoreboard())),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verify scoreboard row dimensions (width: 800, height: 320)
        final rowFinder = find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox && widget.width == 800 && widget.height == 320,
        );
        expect(rowFinder, findsOneWidget);

        // 2. Verify player name container height (54) and text style font size (40)
        // Red side name container
        final redNameContainerFinder = find
            .ancestor(of: find.text('山田 太郎'), matching: find.byType(Container))
            .first;
        final redContainer = tester.widget<Container>(redNameContainerFinder);
        expect(redContainer.constraints?.maxHeight, 54);

        // White side name container
        final whiteNameContainerFinder = find
            .ancestor(of: find.text('山田 のりこ'), matching: find.byType(Container))
            .first;
        final whiteContainer = tester.widget<Container>(
          whiteNameContainerFinder,
        );
        expect(whiteContainer.constraints?.maxHeight, 54);

        // Name text styles
        final redText = tester.widget<Text>(find.text('山田 太郎'));
        expect(redText.style?.fontSize, 40);
        expect(redText.style?.fontWeight, FontWeight.w900);

        final whiteText = tester.widget<Text>(find.text('山田 のりこ'));
        expect(whiteText.style?.fontSize, 40);
        expect(whiteText.style?.fontWeight, FontWeight.w900);

        // 3. Verify point badge dimensions (width: 60, height: 60, fontSize: 38)
        // Point text styles
        final menText = tester.widget<Text>(find.text('メ'));
        expect(menText.style?.fontSize, 38);

        final koteText = tester.widget<Text>(find.text('コ'));
        expect(koteText.style?.fontSize, 38);

        final doText = tester.widget<Text>(find.text('ド'));
        expect(doText.style?.fontSize, 38);

        // Point container bounds (circle shape decoration for first match point)
        final menContainerFinder = find
            .ancestor(of: find.text('メ'), matching: find.byType(Container))
            .first;
        final menContainer = tester.widget<Container>(menContainerFinder);
        expect(menContainer.constraints?.maxWidth, 60);
        expect(menContainer.constraints?.maxHeight, 60);

        // 4. Verify win/loss badge dimensions (height: 60, fontSize: 28)
        expect(find.text('赤 の勝ち'), findsOneWidget);
        final resultText = tester.widget<Text>(find.text('赤 の勝ち'));
        expect(resultText.style?.fontSize, 28);
        expect(resultText.style?.fontWeight, FontWeight.w900);

        final resultContainerFinder = find
            .ancestor(of: find.text('赤 の勝ち'), matching: find.byType(Container))
            .first;
        final resultContainer = tester.widget<Container>(resultContainerFinder);
        expect(resultContainer.constraints?.maxHeight, 60);
      },
    );

    testWidgets(
      'Scoreboard does not show Draw/Tie badge when the match is in progress, but shows it when finished as a tie',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. In-progress match
        final inProgressMatch = MatchModel(
          id: 'match_in_progress',
          tournamentId: 'bunaiksen_20260703',
          groupName: 'infinite_20260703',
          redName: '選手A',
          whiteName: '選手B',
          matchType: '無限勝ち抜き',
          status: 'in_progress',
          isKachinuki: true,
          redScore: 0,
          whiteScore: 0,
          events: const [],
          redRemaining: const [],
          whiteRemaining: const [],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              matchViewStateUserIdProvider.overrideWith(
                (ref) => 'test_user_id',
              ),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              matchListProvider.overrideWithValue([inProgressMatch]),
              scoreboardMatchIdProvider.overrideWithValue('match_in_progress'),
              scoreboardMatchProvider.overrideWithValue(inProgressMatch),
              scoreboardNameTapProvider.overrideWithValue((side) {}),
            ],
            child: const MaterialApp(home: Scaffold(body: MatchScoreboard())),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that the "引き分け" text overlay is NOT present in the tree
        expect(find.text('引き分け'), findsNothing);

        // 2. Finished tie match
        final finishedTieMatch = inProgressMatch.copyWith(status: 'finished');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              matchViewStateUserIdProvider.overrideWith(
                (ref) => 'test_user_id',
              ),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              matchListProvider.overrideWithValue([finishedTieMatch]),
              scoreboardMatchIdProvider.overrideWithValue('match_in_progress'),
              scoreboardMatchProvider.overrideWithValue(finishedTieMatch),
              scoreboardNameTapProvider.overrideWithValue((side) {}),
            ],
            child: const MaterialApp(home: Scaffold(body: MatchScoreboard())),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that the "引き分け" text overlay IS present in the tree
        expect(find.text('引き分け'), findsOneWidget);
      },
    );
  });
}
