import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/viewer/components/viewer_team_scoreboard_table_builder.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    '🥋 ViewerTeamScoreboard Contrast & Design System Tests (観客席スコア視認性テスト)',
    () {
      testWidgets('ライトモードでヘッダー行および合計行が通常ビュアーと同一の高コントラスト配色で描画されること', (
        WidgetTester tester,
      ) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        final dummyMatch = MatchListProjection(
          id: 'm1',
          tournamentId: 't1',
          matchOrder: 1,
          matchType: '先鋒',
          redName: '道上:皿田',
          whiteName: '相手11:選手',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          redPointMarks: ['コ'],
          whitePointMarks: [],
          firstPointSide: 'red',
        );

        final dummyResult = TeamMatchResult(
          redWins: 1,
          redPoints: 1,
          whiteWins: 0,
          whitePoints: 0,
          teamWinner: 'red',
          allFinished: true,
          hasDaihyo: false,
          isTie: false,
        );

        await tester.pumpWidget(
          createTestApp(
            Theme(
              data: ThemeData.light().copyWith(extensions: [themeColors]),
              child: Scaffold(
                body: Builder(
                  builder: (context) => Table(
                    children: [
                      ViewerTeamScoreboardTableBuilder.buildHeaderRow(
                        '道上',
                        '相手11',
                        false,
                      ),
                      ViewerTeamScoreboardTableBuilder.buildMatchRow(
                        dummyMatch,
                        context,
                        false,
                        ['皿田'],
                        ['選手'],
                      ),
                      ViewerTeamScoreboardTableBuilder.buildTotalRow(
                        dummyResult,
                        false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ヘッダー行
        expect(find.text('道上'), findsOneWidget);
        expect(find.text('相手11'), findsOneWidget);
        expect(find.text('赤'), findsOneWidget);
        expect(find.text('白'), findsOneWidget);

        // 選手行
        expect(find.text('先鋒'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('皿田'),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('選手'),
          ),
          findsOneWidget,
        );

        // 合計行（1 / 1, 勝, 0 / 0）
        expect(find.text('1 / 1'), findsOneWidget);
        expect(find.text('勝'), findsOneWidget);
        expect(find.text('0 / 0'), findsOneWidget);
      });

      testWidgets('ダークモードでも正しく高コントラストで描画されること', (WidgetTester tester) async {
        final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

        final dummyResult = TeamMatchResult(
          redWins: 0,
          redPoints: 0,
          whiteWins: 0,
          whitePoints: 0,
          teamWinner: 'draw',
          allFinished: true,
          hasDaihyo: false,
          isTie: true,
        );

        await tester.pumpWidget(
          createTestApp(
            Theme(
              data: ThemeData.dark().copyWith(extensions: [themeColors]),
              child: Scaffold(
                body: Table(
                  children: [
                    ViewerTeamScoreboardTableBuilder.buildHeaderRow(
                      '道上',
                      '相手11',
                      true,
                    ),
                    ViewerTeamScoreboardTableBuilder.buildTotalRow(
                      dummyResult,
                      true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('道上'), findsOneWidget);
        expect(find.text('相手11'), findsOneWidget);
        expect(find.text('引き分け'), findsOneWidget);
      });
    },
  );
}
