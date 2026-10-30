import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_summary_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_finished_navigation_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/corrupted_match_banner.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 試合UIダイアログ・バナー・インジケーター統合テスト', () {
    // =========================================================================
    // 1. 緊急データ破損バナー（ライト＆ダークモード）
    // =========================================================================
    testWidgets('緊急データ破損バナーがライト＆ダークモードで正常に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final isDark in [false, true]) {
        final themeColors = AppThemeColors.ofMode(
          isDark: isDark,
          mode: isDark ? 'dark' : 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: isDark
                  ? ThemeData.dark().copyWith(extensions: [themeColors])
                  : ThemeData.light().copyWith(extensions: [themeColors]),
              home: const Scaffold(
                body: Center(
                  child: CorruptedMatchBanner(matchId: 'corrupted-match-001'),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(CorruptedMatchBanner), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    // =========================================================================
    // 2. 試合確定・承認ダイアログ
    // =========================================================================
    testWidgets('試合確定・承認ダイアログのピクセル配置と文言が正しく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: Center(
              child: MatchFinishedNavigationDialog(
                isRenseikai: true,
                hasGroupName: true,
                isKachinuki: false,
                isDark: false,
                onAddNextRenseikaiMatch: () {},
                onGoToNextMatch: () {},
                onGoHome: () {},
                onShowScoreboard: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(MatchFinishedNavigationDialog), findsOneWidget);
      expect(find.text('対戦終了'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // 3. 試合時間電卓サマリーカード
    // =========================================================================
    testWidgets('試合時間電卓サマリーカードの所要時間およびコート配分が明瞭に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const settings = CalculatorSettings(
        courtCount: 2,
        matchDurationMinutes: 3.0,
        intervalDurationMinutes: 1.0,
      );

      final now = DateTime(2026, 10, 1, 9, 0);
      final dummyMatch1 = AllocatedMatch(
        courtNumber: 1,
        matchOrder: 1,
        categoryName: 'Aリーグ',
        matchTitle: '第1試合',
        pairDescription: '選手1 vs 選手2',
        estimatedStart: now,
        estimatedEnd: now.add(const Duration(minutes: 3)),
      );
      final dummyMatch2 = AllocatedMatch(
        courtNumber: 2,
        matchOrder: 1,
        categoryName: 'Bリーグ',
        matchTitle: '第1試合',
        pairDescription: '選手3 vs 選手4',
        estimatedStart: now,
        estimatedEnd: now.add(const Duration(minutes: 3)),
      );

      final result = AllocationResult(
        totalMatches: 12,
        courtMatches: {
          1: [dummyMatch1],
          2: [dummyMatch2],
        },
        maxCourtMatches: 6,
        totalEstimatedMinutes: 48,
        estimatedEndTime: now.add(const Duration(minutes: 48)),
        matchesPerCategory: {'Aリーグ': 6, 'Bリーグ': 6},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchCalculatorSummaryCard(
                result: result,
                settings: settings,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('12'), findsWidgets);
      expect(find.textContaining('48分'), findsWidgets);
      expect(find.byType(MatchCalculatorSummaryCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // 4. 反則累積インジケーター表示
    // =========================================================================
    testWidgets('反則累積時のスコアボード上表示レイアウトが検証されること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime(2026, 10, 1, 10, 0);
      final matchWithHansoku = MatchModel(
        id: 'hansoku_match_01',
        tournamentId: 't_hansoku',
        category: '個人選手権',
        matchType: '個人戦',
        status: 'in_progress',
        redName: '赤選手',
        whiteName: '白選手',
        redScore: 1,
        whiteScore: 0,
        events: [
          ScoreEvent(
            id: 'h1',
            side: Side.white,
            isHansoku: true,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'h2',
            side: Side.white,
            isHansoku: true,
            timestamp: now.add(const Duration(seconds: 30)),
          ),
          ScoreEvent(
            id: 'h3',
            side: Side.white,
            isHansoku: true,
            timestamp: now.add(const Duration(seconds: 60)),
          ),
        ],
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_1'),
            matchListProvider.overrideWithValue([matchWithHansoku]),
            scoreboardMatchIdProvider.overrideWithValue('hansoku_match_01'),
            scoreboardMatchProvider.overrideWithValue(matchWithHansoku),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 900,
                  height: 350,
                  child: MatchScoreboard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(MatchScoreboard), findsOneWidget);
      expect(find.text('赤選手'), findsOneWidget);
      expect(find.text('白選手'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
