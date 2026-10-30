import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_table_builder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] スコアボード表示・解像度・多人数レイアウト統合テスト', () {
    // =========================================================================
    // 1. カラーユニバーサルデザイン（色覚多様性配慮）
    // =========================================================================
    testWidgets('色覚多様性配慮下において赤白記号と打突表示が明瞭に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime(2026, 10, 3, 14, 0);
      final match = MatchModel(
        id: 'golden_cud_pixel_01',
        tournamentId: 't_cud',
        category: '全国選抜選手権',
        matchType: '個人戦',
        status: 'in_progress',
        redName: '佐々木小次郎',
        whiteName: '宮本武蔵',
        redScore: 2,
        whiteScore: 1,
        events: [
          ScoreEvent(
            id: 'e_cud_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'e_cud_2',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 40)),
          ),
          ScoreEvent(
            id: 'e_cud_3',
            side: Side.white,
            strikeType: StrikeType.dou,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 80)),
          ),
        ],
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'light');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_cud'),
            matchListProvider.overrideWithValue([match]),
            scoreboardMatchIdProvider.overrideWithValue('golden_cud_pixel_01'),
            scoreboardMatchProvider.overrideWithValue(match),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 900,
                  height: 380,
                  child: MatchScoreboard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(MatchScoreboard), findsOneWidget);
      expect(find.text('佐々木小次郎'), findsOneWidget);
      expect(find.text('宮本武蔵'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // 2. 21:9 ウルトラワイド画面（2560x1080）中央最適化アスペクト比維持
    // =========================================================================
    testWidgets('2560x1080ウルトラワイド画面においてスコアボードが中央最適化され破綻なく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2560, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final match = MatchModel(
        id: 'match_ultrawide_01',
        tournamentId: 't_uw_01',
        category: '一般団体の部',
        matchType: '団体戦',
        status: 'in_progress',
        redName: '東京代表 剣道',
        whiteName: '大阪代表 武道',
        redScore: 1,
        whiteScore: 0,
        matchTimeMinutes: 4.0,
      );

      final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'dark');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_uw'),
            matchListProvider.overrideWithValue([match]),
            scoreboardMatchIdProvider.overrideWithValue('match_ultrawide_01'),
            scoreboardMatchProvider.overrideWithValue(match),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 1400,
                  height: 480,
                  child: MatchScoreboard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(MatchScoreboard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // 3. 多人数団体戦（7人制・8人制・9人制）星取表・合計行の整合性
    // =========================================================================
    List<MatchModel> generateTeamMatches({
      required int playerCount,
      required String redTeam,
      required String whiteTeam,
    }) {
      final posNames = MatchFormatSetupHelper.generatePositions(playerCount);
      final now = DateTime(2026, 9, 27, 10, 0);

      return List.generate(playerCount, (i) {
        final pos = posNames[i];
        final events = <ScoreEvent>[];

        if (i == 0) {
          events.add(
            ScoreEvent(
              id: 'e_r1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: now,
            ),
          );
          events.add(
            ScoreEvent(
              id: 'e_r2',
              side: Side.red,
              strikeType: StrikeType.kote,
              isIppon: true,
              timestamp: now.add(const Duration(seconds: 30)),
            ),
          );
        } else if (i == 1) {
          events.add(
            ScoreEvent(
              id: 'e_w1',
              side: Side.white,
              strikeType: StrikeType.dou,
              isIppon: true,
              timestamp: now,
            ),
          );
        }

        return MatchModel(
          id: 'match_p${playerCount}_$i',
          tournamentId: 't1',
          matchType: pos,
          order: i.toDouble(),
          redName: '$redTeam: 赤選手$i',
          whiteName: '$whiteTeam: 白選手$i',
          redScore: i == 0 ? 2 : 0,
          whiteScore: i == 1 ? 1 : 0,
          events: events,
          status: 'finished',
        );
      });
    }

    Widget buildScoreboardWidget({
      required List<MatchModel> matches,
      required String redTeam,
      required String whiteTeam,
      required bool isDark,
    }) {
      final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
      final teamMatchResult = TeamMatchCalculator.calculate(matches);

      return MaterialApp(
        theme: ThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          extensions: [themeColors],
        ),
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Builder(
                  builder: (ctx) {
                    return Table(
                      border: TableBorder.all(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(3.0),
                        2: FlexColumnWidth(1.6),
                        3: FlexColumnWidth(1.6),
                        4: FlexColumnWidth(3.0),
                      },
                      children: [
                        TeamScoreboardTableBuilder.buildHeaderRow(
                          redTeam,
                          whiteTeam,
                          isDark,
                        ),
                        ...matches.map(
                          (m) => TeamScoreboardTableBuilder.buildMatchRow(
                            m,
                            ctx,
                            isDark,
                            [],
                            [],
                          ),
                        ),
                        TeamScoreboardTableBuilder.buildTotalRow(
                          teamMatchResult,
                          isDark,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('7人制（中堅あり）スコアボード: スマホ縦 (390x844) レイアウト整合性が正しく検証されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final matches = generateTeamMatches(
        playerCount: 7,
        redTeam: '神武館',
        whiteTeam: '修道館',
      );

      await tester.pumpWidget(
        buildScoreboardWidget(
          matches: matches,
          redTeam: '神武館',
          whiteTeam: '修道館',
          isDark: true,
        ),
      );
      await tester.pump();

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('中堅'), findsOneWidget);
      expect(find.text('大将'), findsOneWidget);
      expect(find.text('神武館'), findsWidgets);
      expect(find.text('修道館'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('8人制（偶数・中堅なし）スコアボード: タブレット縦 (768x1024) レイアウト整合性が正しく検証されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final matches = generateTeamMatches(
        playerCount: 8,
        redTeam: '赤心館',
        whiteTeam: '青藍館',
      );

      await tester.pumpWidget(
        buildScoreboardWidget(
          matches: matches,
          redTeam: '赤心館',
          whiteTeam: '青藍館',
          isDark: true,
        ),
      );
      await tester.pump();

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('中堅'), findsNothing);
      expect(find.text('大将'), findsOneWidget);
      expect(find.text('赤心館'), findsWidgets);
      expect(find.text('青藍館'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('9人制（中堅あり）スコアボード: タブレット横 (1024x768) レイアウト整合性が正しく検証されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final matches = generateTeamMatches(
        playerCount: 9,
        redTeam: '東軍',
        whiteTeam: '西軍',
      );

      await tester.pumpWidget(
        buildScoreboardWidget(
          matches: matches,
          redTeam: '東軍',
          whiteTeam: '西軍',
          isDark: false,
        ),
      );
      await tester.pump();

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('中堅'), findsOneWidget);
      expect(find.text('大将'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
