import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/kata_score_action_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_table_builder.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('[Golden] 形・基本技スコアボード＆操作パネル ピクセル・視覚整合性テスト', () {
    const kataRule = MatchRule(
      isKataMatch: true,
      matchTimeMinutes: 0,
      isRunningTime: false,
      hasHantei: true,
    );

    testWidgets('形試合スコアボード（特大旗スコア表示「3 - 0」）がライト＆ダークモードで崩れなく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final match = MatchModel(
        id: 'golden_kata_scoreboard_01',
        tournamentId: 'tour_kata',
        category: '小学生の部',
        matchType: '決勝',
        status: 'finished',
        redName: '田中・山田',
        whiteName: '佐藤・高橋',
        rule: kataRule,
        redScore: 3,
        whiteScore: 0,
        events: [
          ScoreEvent(
            id: 'e1',
            side: Side.red,
            isHantei: true,
            redFlags: 3,
            whiteFlags: 0,
            timestamp: DateTime(2026, 10, 11, 10, 0),
          ),
        ],
      );

      for (final isDark in [false, true]) {
        final themeColors = AppThemeColors.ofMode(
          isDark: isDark,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => _MockSettingsNotifier()),
              matchViewStateUserIdProvider.overrideWith((ref) => 'user_1'),
              matchListProvider.overrideWithValue([match]),
              scoreboardMatchIdProvider.overrideWithValue(
                'golden_kata_scoreboard_01',
              ),
              scoreboardMatchProvider.overrideWithValue(match),
              scoreboardNameTapProvider.overrideWithValue((side) {}),
            ],
            child: MaterialApp(
              theme: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
                extensions: [themeColors],
              ),
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

        await tester.pumpAndSettle();

        expect(find.byType(MatchScoreboard), findsOneWidget);
        expect(find.text('田中・山田'), findsOneWidget);
        expect(find.text('佐藤・高橋'), findsOneWidget);
        // 特大旗判定スコアの描画確認
        expect(find.text('3'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
      'KataScoreActionSection（審判3名旗判定ボタン群 ＆ 不戦勝ボタン）がモバイル幅で崩れなく描画されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        for (final isDark in [false, true]) {
          final themeColors = AppThemeColors.ofMode(
            isDark: isDark,
            mode: 'normal',
          );

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
                  extensions: [themeColors],
                ),
                home: Scaffold(
                  body: Center(
                    child: KataScoreActionSection(
                      matchId: 'match_golden_action_01',
                      isInputLocked: false,
                      isDark: isDark,
                      hasEvents: false,
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.byType(KataScoreActionSection), findsOneWidget);
          expect(find.text('赤 3 - 0 白'), findsOneWidget);
          expect(find.text('赤 2 - 1 白'), findsOneWidget);
          expect(find.text('赤 1 - 2 白'), findsOneWidget);
          expect(find.text('赤 0 - 3 白'), findsOneWidget);
          expect(find.text('赤 不戦勝'), findsOneWidget);
          expect(find.text('白 不戦勝'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('形試合スコアボード（不戦勝表示「○ - ×」）がライト＆ダークモードで勝者丸枠なく崩れず描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final match = MatchModel(
        id: 'golden_kata_fusen_01',
        tournamentId: 'tour_kata',
        category: '一般の部',
        matchType: '1回戦',
        status: 'finished',
        redName: '皿田・塚本',
        whiteName: '欠員',
        rule: kataRule,
        redScore: 1,
        whiteScore: 0,
        events: [
          ScoreEvent(
            id: 'e_fusen_1',
            side: Side.red,
            isFusen: true,
            timestamp: DateTime(2026, 10, 14, 10, 0),
          ),
        ],
      );

      for (final isDark in [false, true]) {
        final themeColors = AppThemeColors.ofMode(
          isDark: isDark,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => _MockSettingsNotifier()),
              matchViewStateUserIdProvider.overrideWith((ref) => 'user_1'),
              matchListProvider.overrideWithValue([match]),
              scoreboardMatchIdProvider.overrideWithValue(
                'golden_kata_fusen_01',
              ),
              scoreboardMatchProvider.overrideWithValue(match),
              scoreboardNameTapProvider.overrideWithValue((side) {}),
            ],
            child: MaterialApp(
              theme: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
                extensions: [themeColors],
              ),
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

        await tester.pumpAndSettle();

        expect(find.byType(MatchScoreboard), findsOneWidget);
        // 不戦勝記号の描画確認
        expect(find.text('○'), findsOneWidget);
        expect(find.text('×'), findsOneWidget);

        // 形試合のため、勝者丸枠 (BoxShape.circle, width: 6) が描画されないこと
        final giantWinnerCircles = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(MatchScoreboard),
                matching: find.byType(Container),
              ),
            )
            .where((c) {
              final dec = c.decoration;
              if (dec is BoxDecoration && dec.shape == BoxShape.circle) {
                final border = dec.border;
                if (border is Border && border.top.width >= 5) {
                  return true;
                }
              }
              return false;
            })
            .toList();
        expect(giantWinnerCircles.isEmpty, isTrue);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('形競技団体戦スコアボードテーブルが各マスの旗数・不戦勝および合計行の勝数のみ表示で崩れなく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final result = TeamMatchResult(
        redWins: 2,
        whiteWins: 1,
        redPoints: 4,
        whitePoints: 2,
        allFinished: true,
        hasDaihyo: false,
        isTie: false,
        teamWinner: 'red',
      );

      for (final isDark in [false, true]) {
        final themeColors = AppThemeColors.ofMode(
          isDark: isDark,
          mode: 'normal',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
              extensions: [themeColors],
            ),
            home: Scaffold(
              body: Table(
                border: TableBorder.all(color: Colors.grey),
                children: [
                  TeamScoreboardTableBuilder.buildHeaderRow(
                    '道上剣友会',
                    '友道館',
                    isDark,
                  ),
                  TeamScoreboardTableBuilder.buildTotalRow(
                    result,
                    isDark,
                    isKata: true,
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 合計行に勝数のみが表示されていること
        expect(find.text('2勝'), findsOneWidget);
        expect(find.text('1勝'), findsOneWidget);
        // 「本」の文字が合計行に含まれないこと
        expect(find.textContaining('本'), findsNothing);
        // 勝敗判定マーク
        expect(find.text('勝'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
