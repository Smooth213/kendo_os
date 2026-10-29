import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_player_stats_section.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_strike_stat_row.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_summary_toolbar.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

void main() {
  group('[Widget] 遠征統計コンポーネント・計算統合テスト', () {
    // ----------------------------------------------------------
    // 統計計算ロジック
    // ----------------------------------------------------------
    group('ExpeditionStatsCalculator計算テスト', () {
      test('calculateにおいて 勝敗および有効打突の内訳が正しく計算されること', () {
        final matches = [
          MatchModel(
            id: 'm1',
            matchType: '団体戦',
            groupName: 'group1',
            redName: '青龍館: 山田',
            whiteName: '白虎館: 佐藤',
            redScore: 2,
            whiteScore: 0,
            status: 'finished',
            matchScene: 'honsen',
            events: [
              ScoreEvent(
                id: 'e1',
                timestamp: DateTime.now(),
                side: Side.red,
                strikeType: StrikeType.men,
                isIppon: true,
              ),
              ScoreEvent(
                id: 'e2',
                timestamp: DateTime.now(),
                side: Side.red,
                strikeType: StrikeType.kote,
                isIppon: true,
              ),
            ],
          ),
        ];

        final summary = ExpeditionStatsCalculator.calculate(
          matches: matches,
          registeredTeamNames: {'青龍館'},
          registeredPlayerNames: {'山田'},
          selectedSummaryTeam: '青龍館',
        );

        expect(summary.honsenWin, 1);
        expect(summary.honsenLoss, 0);
        expect(summary.teamMen, 1);
        expect(summary.teamKote, 1);
        expect(summary.teamTotalScored, 2);
        expect(summary.teamTotalConceded, 0);
        expect(summary.playerStatsMap['山田']?.win, 1);
        expect(summary.playerStatsMap['山田']?.men, 1);
        expect(summary.playerStatsMap['山田']?.kote, 1);
      });
    });

    // ----------------------------------------------------------
    // 打突統計行
    // ----------------------------------------------------------
    group('ExpeditionStrikeStatRow打突統計行テスト', () {
      testWidgets('遠征打突統計行に打突バッジが正しく描画されること', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ExpeditionStrikeStatRow(
                men: 5,
                kote: 3,
                dou: 2,
                tsuki: 0,
                hansoku: 1,
              ),
            ),
          ),
        );

        expect(find.text('面 (メ)'), findsOneWidget);
        expect(find.text('5本'), findsOneWidget);
        expect(find.text('小手 (コ)'), findsOneWidget);
        expect(find.text('3本'), findsOneWidget);
        expect(find.text('胴 (ド)'), findsOneWidget);
        expect(find.text('2本'), findsOneWidget);
        expect(find.text('突き (ツ)'), findsOneWidget);
        expect(find.text('0本'), findsOneWidget);
        expect(find.text('反則 (反)'), findsOneWidget);
        expect(find.text('1本'), findsOneWidget);
      });
    });

    // ----------------------------------------------------------
    // ツールバー
    // ----------------------------------------------------------
    group('ExpeditionSummaryToolbarツールバーテスト', () {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      final summaryData = ExpeditionSummaryData(
        teamsList: const ['チームA'],
        renseikaiWin: 2,
        renseikaiLoss: 1,
        renseikaiDraw: 0,
        honsenWin: 1,
        honsenLoss: 0,
        honsenDraw: 1,
        moushiawaseWin: 0,
        moushiawaseLoss: 0,
        moushiawaseDraw: 0,
        teamMen: 4,
        teamKote: 2,
        teamDou: 1,
        teamTsuki: 0,
        teamHansoku: 1,
        teamOther: 0,
        teamTotalScored: 8,
        teamTotalConceded: 4,
        playerStatsMap: const {},
        cardResults: const [],
      );

      testWidgets('詳細分析ボタンが表示され、teamsListが1個以下のときはチームドロップダウンが非表示こと', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: ExpeditionSummaryToolbar(
                isDark: false,
                themeColors: themeColors,
                selectedSummaryTeam: 'チームA',
                teamsList: const ['チームA'],
                summaryData: summaryData,
                onTeamChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('詳細分析 ›'), findsOneWidget);
        expect(find.byIcon(Icons.bar_chart), findsOneWidget);
        expect(find.byType(DropdownButton<String>), findsNothing);
      });

      testWidgets('teamsListが2個以上のときドロップダウンが表示され、選択変更時にonTeamChangedが発火すること', (
        tester,
      ) async {
        String? changedTeam;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: ExpeditionSummaryToolbar(
                isDark: false,
                themeColors: themeColors,
                selectedSummaryTeam: '全体',
                teamsList: const ['チームA', 'チームB'],
                summaryData: summaryData,
                onTeamChanged: (val) {
                  changedTeam = val;
                },
              ),
            ),
          ),
        );

        expect(find.byType(DropdownButton<String>), findsOneWidget);

        await tester.tap(find.byType(DropdownButton<String>));
        await tester.safePumpAndSettle();

        final itemFinder = find.text('チームA').last;
        await tester.tap(itemFinder);
        await tester.safePumpAndSettle();

        expect(changedTeam, 'チームA');
      });
    });

    // ----------------------------------------------------------
    // 選手別統計セクション（視認性）
    // ----------------------------------------------------------
    group('ExpeditionPlayerStatsSection視認性テスト', () {
      final Map<String, DetailedPlayerStats> sampleStats = {
        '恵木 春陽': DetailedPlayerStats()
          ..win = 1
          ..loss = 1
          ..draw = 3
          ..totalPoints = 4
          ..teamWin = 0
          ..teamLoss = 0
          ..teamDraw = 2
          ..teamPoints = 1
          ..individualWin = 1
          ..individualLoss = 1
          ..individualDraw = 1
          ..individualPoints = 3
          ..men = 2
          ..kote = 1
          ..dou = 1
          ..tsuki = 0
          ..hansoku = 0,
        '皿田 唯人': DetailedPlayerStats()
          ..win = 6
          ..loss = 1
          ..draw = 1
          ..totalPoints = 9
          ..teamWin = 2
          ..teamLoss = 0
          ..teamDraw = 0
          ..teamPoints = 3
          ..individualWin = 4
          ..individualLoss = 1
          ..individualDraw = 1
          ..individualPoints = 6
          ..men = 5
          ..kote = 3
          ..dou = 1
          ..tsuki = 0
          ..hansoku = 0,
      };

      testWidgets('ダークモードでの選択タブと取得本数の視認性が正常に機能すること', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: ExpeditionPlayerStatsSection(
                playerStatsMap: sampleStats,
                isDark: true,
              ),
            ),
          ),
        );

        await tester.safePumpAndSettle();

        final selectedChipFinder = find.byWidgetPredicate((widget) {
          if (widget is AppChoiceChip && widget.selected) {
            return true;
          }
          return false;
        });
        expect(selectedChipFinder, findsOneWidget);

        final selectedChip = tester.widget<AppChoiceChip>(selectedChipFinder);
        expect(selectedChip.customTextColor, equals(AppKendoColors.pureWhite));

        final points4Finder = find.text('(4本)');
        expect(points4Finder, findsOneWidget);
        final points4Text = tester.widget<Text>(points4Finder);
        expect(points4Text.style?.color, equals(const Color(0xFF60A5FA)));

        final points9Finder = find.text('(9本)');
        expect(points9Finder, findsOneWidget);
        final points9Text = tester.widget<Text>(points9Finder);
        expect(points9Text.style?.color, equals(const Color(0xFF60A5FA)));
      });

      testWidgets('ライトモードでの取得本数の視認性が正常に機能すること', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ExpeditionPlayerStatsSection(
                playerStatsMap: sampleStats,
                isDark: false,
              ),
            ),
          ),
        );

        await tester.safePumpAndSettle();

        final points4Finder = find.text('(4本)');
        expect(points4Finder, findsOneWidget);
        final points4Text = tester.widget<Text>(points4Finder);
        expect(points4Text.style?.color, equals(const Color(0xFF1D4ED8)));
      });
    });
  });
}
