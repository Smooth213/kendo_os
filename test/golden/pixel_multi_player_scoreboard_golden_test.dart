import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_table_builder.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('📸 【Golden】多人数団体戦（7人制・8人制・9人制）スコアボード視覚整合性テスト', () {
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

        // サンプル打突イベントを一部設定
        if (i == 0) {
          // 先鋒: 赤2本勝ち (メ、コ)
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
          // 次鋒: 白一本勝ち (ド)
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

    testWidgets('1. 7人制（中堅あり）スコアボード: スマホ縦 (390x844) レイアウト整合性検証', (
      tester,
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
          isDark: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('中堅'), findsOneWidget);
      expect(find.text('大将'), findsOneWidget);
      expect(find.text('神武館'), findsWidgets);
      expect(find.text('修道館'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. 8人制（中堅なし）スコアボード: タブレット横 (1024x768) レイアウト整合性検証', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
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
      await tester.pumpAndSettle();

      expect(find.text('先鋒'), findsOneWidget);
      // 8人制偶数のため「中堅」は存在しないこと
      expect(find.text('中堅'), findsNothing);
      expect(find.text('大将'), findsOneWidget);
      expect(find.text('赤心館'), findsWidgets);
      expect(find.text('青藍館'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. 9人制（中堅あり）スコアボード: タブレット横 (1024x768) レイアウト整合性検証', (
      tester,
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
      await tester.pumpAndSettle();

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('中堅'), findsOneWidget);
      expect(find.text('大将'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
