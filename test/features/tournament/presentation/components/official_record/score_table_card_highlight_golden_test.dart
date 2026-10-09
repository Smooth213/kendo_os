import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/score_table_card.dart';

void main() {
  group('[Golden] 公式記録スコアテーブル カードハイライト描画検証', () {
    testWidgets('スコアテーブルカードにおいて選手名セルがハイライトされた状態が視覚的に正しく描画されること', (
      WidgetTester tester,
    ) async {
      const info = ScoreTableGroupInfo(
        groupName: 'team_group_1',
        headerTitle: '【団体戦】 福山道場 vs 廿日市剣連',
        scenePrefix: '第1試合場',
        sideLabelRed: '福山道場',
        sideLabelWhite: '廿日市剣連',
        isSummary: false,
        teamWinner: 'red',
        redWins: 1,
        whiteWins: 0,
        redTotalPoints: 1,
        whiteTotalPoints: 0,
        allFinished: true,
      );

      final matches = [
        const ScoreTableMatchItem(
          id: 'm1',
          matchType: '先鋒',
          redName: '福山道場: 岡田',
          whiteName: '廿日市剣連: 木場',
          redScore: 1,
          whiteScore: 0,
          isFinished: true,
          redPoints: [],
          whitePoints: [],
        ),
      ];

      final testWidget = MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
        ),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              child: ScoreTableCard(
                info: info,
                matches: matches,
                cardColor: Colors.white,
                isDark: false,
                highlightQuery: '岡田',
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ScoreTableCard),
        matchesGoldenFile('goldens/score_table_card_highlight.png'),
      );
    });
  });
}
