import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_timer_section.dart';
import 'package:kendo_os/features/viewer/components/large_viewer_scoreboard.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testMatch = MatchModel(
    id: 'test_m1',
    tournamentId: 't1',
    category: '一般',
    redName: '選手A',
    whiteName: '選手B',
    matchType: '個人戦',
    status: 'ongoing',
  );

  group('🎨 [Phase 3 Performance Governance] RepaintBoundary 描画境界分離テスト', () {
    testWidgets('MatchScoreboard が RepaintBoundary を持ち、画面全体の再描画を遮断していること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'test_user_id'),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            matchListProvider.overrideWith((ref) => [testMatch]),
            scoreboardMatchIdProvider.overrideWithValue('test_m1'),
            scoreboardMatchProvider.overrideWithValue(testMatch),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: const MaterialApp(home: Scaffold(body: MatchScoreboard())),
        ),
      );

      await tester.pumpAndSettle();

      // MatchScoreboard の内部ツリーに RepaintBoundary が存在することを検証
      final scoreboardFinder = find.byType(MatchScoreboard);
      expect(scoreboardFinder, findsOneWidget);

      final repaintBoundaryFinder = find.descendant(
        of: scoreboardFinder,
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundaryFinder, findsWidgets);
    });

    testWidgets('MatchTimerSection が RepaintBoundary を持ち、毎秒タイマー再描画を隔離していること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchListProvider.overrideWith((ref) => [testMatch]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MatchTimerSection(
                match: testMatch,
                rule: const MatchRule(),
                isInputLocked: false,
              ),
            ),
          ),
        ),
      );

      final timerSectionFinder = find.byType(MatchTimerSection);
      expect(timerSectionFinder, findsOneWidget);

      final repaintBoundaryFinder = find.descendant(
        of: timerSectionFinder,
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundaryFinder, findsWidgets);
    });

    testWidgets(
      'LargeViewerScoreboard が RepaintBoundary を持ち、観戦描画負荷を最小化していること',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const projection = MatchProjection(
          id: 'p1',
          tournamentId: 't1',
          matchOrder: 1,
          matchType: '個人戦',
          status: 'ongoing',
          groupName: 'A',
          isKachinuki: false,
          redName: '選手A',
          whiteName: '選手B',
          redScore: 1,
          whiteScore: 0,
          remainingSeconds: 180,
          timerIsRunning: false,
          note: '',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LargeViewerScoreboard(
                projection: projection,
                activeMatch: null,
                isDark: false,
              ),
            ),
          ),
        );

        final viewerScoreboardFinder = find.byType(LargeViewerScoreboard);
        expect(viewerScoreboardFinder, findsOneWidget);

        final repaintBoundaryFinder = find.descendant(
          of: viewerScoreboardFinder,
          matching: find.byType(RepaintBoundary),
        );
        expect(repaintBoundaryFinder, findsWidgets);
      },
    );
  });
}
