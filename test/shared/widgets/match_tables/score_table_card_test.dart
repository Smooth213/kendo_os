import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/score_table_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableCard({
    required ScoreTableGroupInfo info,
    required List<ScoreTableMatchItem> matches,
    required bool isDark,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return MaterialApp(
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        extensions: [themeColors],
      ),
      home: Scaffold(
        body: ScoreTableCard(info: info, matches: matches, isDark: isDark),
      ),
    );
  }

  group('ScoreTableCard Position Name Visibility Tests', () {
    final sampleInfo = const ScoreTableGroupInfo(
      groupName: '道上剣友会A vs 相手チーム',
      headerTitle: '【団体戦】 道上剣友会A vs 相手チーム',
      sideLabelRed: '道上剣友会A',
      sideLabelWhite: '相手チーム',
      isSummary: false,
      teamWinner: 'draw',
      redWins: 0,
      whiteWins: 0,
      redTotalPoints: 0,
      whiteTotalPoints: 0,
      allFinished: false,
    );

    final sampleMatches = [
      const ScoreTableMatchItem(
        id: 'm1',
        matchType: '先鋒',
        redName: '皿田',
        whiteName: '選手',
        redScore: 0,
        whiteScore: 0,
        isFinished: false,
        redPoints: [],
        whitePoints: [],
      ),
      const ScoreTableMatchItem(
        id: 'm2',
        matchType: '中堅',
        redName: '塚本',
        whiteName: '選手',
        redScore: 0,
        whiteScore: 0,
        isFinished: false,
        redPoints: [],
        whitePoints: [],
      ),
      const ScoreTableMatchItem(
        id: 'm3',
        matchType: '大将',
        redName: '久安',
        whiteName: '選手',
        redScore: 0,
        whiteScore: 0,
        isFinished: false,
        redPoints: [],
        whitePoints: [],
      ),
      const ScoreTableMatchItem(
        id: 'm4',
        matchType: '代表戦',
        redName: '久安',
        whiteName: '選手',
        redScore: 0,
        whiteScore: 0,
        isFinished: false,
        redPoints: [],
        whitePoints: [],
      ),
    ];

    testWidgets(
      '1. ダークモード時: ポジション名（先鋒、中堅、大将）が separatorColor ではなく textColor で明瞭に表示されること',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableCard(
            info: sampleInfo,
            matches: sampleMatches,
            isDark: true,
          ),
        );
        await tester.pumpAndSettle();

        final expectedDarkTextColor = AppThemeColors.ofMode(
          isDark: true,
          mode: 'normal',
        ).textColor;
        final expectedDarkSeparatorColor = AppThemeColors.ofMode(
          isDark: true,
          mode: 'normal',
        ).separatorColor;

        // 「先鋒」「中堅」「大将」の Text widget を検索
        final senpoFinder = find.text('先鋒');
        final chukenFinder = find.text('中堅');
        final taishoFinder = find.text('大将');
        final daihyoFinder = find.text('代表戦');

        expect(senpoFinder, findsOneWidget);
        expect(chukenFinder, findsOneWidget);
        expect(taishoFinder, findsOneWidget);
        expect(daihyoFinder, findsOneWidget);

        final Text senpoText = tester.widget(senpoFinder);
        final Text chukenText = tester.widget(chukenFinder);
        final Text taishoText = tester.widget(taishoFinder);
        final Text daihyoText = tester.widget(daihyoFinder);

        // ★ 視認性不良（separatorColorの黒同化）が解消され、textColor（白）になっていることを検証
        expect(senpoText.style?.color, equals(expectedDarkTextColor));
        expect(
          senpoText.style?.color,
          isNot(equals(expectedDarkSeparatorColor)),
        );

        expect(chukenText.style?.color, equals(expectedDarkTextColor));
        expect(taishoText.style?.color, equals(expectedDarkTextColor));

        // 代表戦はハイライト赤色であること
        expect(daihyoText.style?.color, equals(const Color(0xFFFF6B6B)));
      },
    );

    testWidgets('2. ライトモード時: ポジション名が textColor (黒) で明瞭に表示されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableCard(
          info: sampleInfo,
          matches: sampleMatches,
          isDark: false,
        ),
      );
      await tester.pumpAndSettle();

      final expectedLightTextColor = AppThemeColors.ofMode(
        isDark: false,
        mode: 'normal',
      ).textColor;

      final Text senpoText = tester.widget(find.text('先鋒'));
      expect(senpoText.style?.color, equals(expectedLightTextColor));
    });

    testWidgets(
      '3. 5人制（先鋒・次鋒・中堅・副将・大将・代表戦）の完全な団体戦スコアテーブルにおける全ポジション名の文字色視認性検証',
      (WidgetTester tester) async {
        final fivePlayerMatches = [
          const ScoreTableMatchItem(
            id: 'm1',
            matchType: '先鋒',
            redName: '先鋒選手A',
            whiteName: '先鋒選手B',
            redScore: 0,
            whiteScore: 0,
            isFinished: true,
            redPoints: [],
            whitePoints: [],
          ),
          const ScoreTableMatchItem(
            id: 'm2',
            matchType: '次鋒',
            redName: '次鋒選手A',
            whiteName: '次鋒選手B',
            redScore: 0,
            whiteScore: 0,
            isFinished: true,
            redPoints: [],
            whitePoints: [],
          ),
          const ScoreTableMatchItem(
            id: 'm3',
            matchType: '中堅',
            redName: '中堅選手A',
            whiteName: '中堅選手B',
            redScore: 0,
            whiteScore: 0,
            isFinished: true,
            redPoints: [],
            whitePoints: [],
          ),
          const ScoreTableMatchItem(
            id: 'm4',
            matchType: '副将',
            redName: '副将選手A',
            whiteName: '副将選手B',
            redScore: 0,
            whiteScore: 0,
            isFinished: true,
            redPoints: [],
            whitePoints: [],
          ),
          const ScoreTableMatchItem(
            id: 'm5',
            matchType: '大将',
            redName: '大将選手A',
            whiteName: '大将選手B',
            redScore: 0,
            whiteScore: 0,
            isFinished: true,
            redPoints: [],
            whitePoints: [],
          ),
          const ScoreTableMatchItem(
            id: 'm6',
            matchType: '代表戦',
            redName: '大将選手A',
            whiteName: '大将選手B',
            redScore: 1,
            whiteScore: 0,
            isFinished: true,
            redPoints: [],
            whitePoints: [],
          ),
        ];

        await tester.pumpWidget(
          buildTestableCard(
            info: sampleInfo,
            matches: fivePlayerMatches,
            isDark: true,
          ),
        );
        await tester.pumpAndSettle();

        final expectedDarkTextColor = AppThemeColors.ofMode(
          isDark: true,
          mode: 'normal',
        ).textColor;
        final expectedDarkSeparatorColor = AppThemeColors.ofMode(
          isDark: true,
          mode: 'normal',
        ).separatorColor;

        for (final pos in ['先鋒', '次鋒', '中堅', '副将', '大将']) {
          final finder = find.text(pos);
          expect(finder, findsOneWidget);
          final Text textWidget = tester.widget(finder);
          expect(textWidget.style?.color, equals(expectedDarkTextColor));
          expect(
            textWidget.style?.color,
            isNot(equals(expectedDarkSeparatorColor)),
          );
        }

        final daihyoText = tester.widget<Text>(find.text('代表戦'));
        expect(daihyoText.style?.color, equals(const Color(0xFFFF6B6B)));
      },
    );
  });
}
