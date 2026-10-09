import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/score_table_card.dart';
import 'package:kendo_os/shared/widgets/vertical_name_text.dart';

void main() {
  group('[Widget] 公式記録スコアテーブル カードハイライト描画検証', () {
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

    testWidgets('スコアテーブルカードにおいて選手名セルがハイライトされた状態が視覚的スタイルとして正しく反映されること', (
      WidgetTester tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
        ),
        home: Scaffold(
          body: Center(
            child: ScoreTableCard(
              info: info,
              matches: matches,
              cardColor: Colors.white,
              isDark: false,
              highlightQuery: '岡田',
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // '岡田' と '木場' の VerticalNameText が存在することを検証
      final okadaFinder = find.byWidgetPredicate(
        (w) => w is VerticalNameText && w.text == '岡田',
      );
      final kibaFinder = find.byWidgetPredicate(
        (w) => w is VerticalNameText && w.text == '木場',
      );

      expect(okadaFinder, findsOneWidget);
      expect(kibaFinder, findsOneWidget);

      // '岡田' を内包する AnimatedContainer を取得してハイライト装飾を検証
      final okadaAnimatedContainers = tester.widgetList<AnimatedContainer>(
        find.ancestor(
          of: okadaFinder,
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(okadaAnimatedContainers, isNotEmpty);
      final okadaContainer = okadaAnimatedContainers.first;
      final okadaDecoration = okadaContainer.decoration as BoxDecoration?;
      expect(okadaDecoration, isNotNull);
      expect(okadaDecoration!.color, equals(const Color(0xFFFFF59D)));
      expect(
        okadaDecoration.border,
        equals(Border.all(color: AppKendoColors.amber, width: 1.5)),
      );

      // '木場' を内包する AnimatedContainer はハイライトされていないことを検証
      final kibaAnimatedContainers = tester.widgetList<AnimatedContainer>(
        find.ancestor(of: kibaFinder, matching: find.byType(AnimatedContainer)),
      );
      expect(kibaAnimatedContainers, isNotEmpty);
      final kibaContainer = kibaAnimatedContainers.first;
      final kibaDecoration = kibaContainer.decoration as BoxDecoration?;
      expect(kibaDecoration, isNotNull);
      expect(kibaDecoration!.color, equals(Colors.transparent));
      expect(kibaDecoration.border, isNull);
    });

    testWidgets('スコアテーブルカードにおいてチーム名検索時にチーム名セルがハイライトされること', (
      WidgetTester tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
        ),
        home: Scaffold(
          body: Center(
            child: ScoreTableCard(
              info: info,
              matches: matches,
              cardColor: Colors.white,
              isDark: false,
              highlightQuery: '福山',
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      final fukuyamaTeamFinder = find.text('福山道場');
      expect(fukuyamaTeamFinder, findsOneWidget);

      final fukuyamaContainers = tester.widgetList<AnimatedContainer>(
        find.ancestor(
          of: fukuyamaTeamFinder,
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(fukuyamaContainers, isNotEmpty);
      final fukuyamaDecoration =
          fukuyamaContainers.first.decoration as BoxDecoration?;
      expect(fukuyamaDecoration, isNotNull);
      expect(fukuyamaDecoration!.color, equals(const Color(0xFFFFF59D)));
      expect(
        fukuyamaDecoration.border,
        equals(Border.all(color: AppKendoColors.amber, width: 1.5)),
      );
    });
  });
}
