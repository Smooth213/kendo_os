import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_table_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ TeamScoreboard Extracted Components Tests', () {
    testWidgets('1. TeamScoreboardTableBuilder builds table rows correctly', (
      tester,
    ) async {
      final headerRow = TeamScoreboardTableBuilder.buildHeaderRow(
        '赤チーム',
        '白チーム',
        false,
      );
      final totalRow = TeamScoreboardTableBuilder.buildTotalRow(
        TeamMatchResult(
          redPoints: 3,
          whitePoints: 2,
          redWins: 2,
          whiteWins: 1,
          allFinished: true,
          hasDaihyo: false,
          isTie: false,
          teamWinner: 'red',
        ),
        false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Table(children: [headerRow, totalRow])),
        ),
      );

      expect(find.text('赤チーム'), findsOneWidget);
      expect(find.text('白チーム'), findsOneWidget);
      expect(find.text('3 / 2'), findsOneWidget);
      expect(find.text('2 / 1'), findsOneWidget);
    });

    test('2. TeamScoreboardTableBuilder calcPts parses points correctly', () {
      final match = MatchModel(
        id: 'm1',
        matchOrder: 1,
        redName: 'A道場 : 佐藤',
        whiteName: 'B道場 : 鈴木',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        matchType: '先鋒',
        events: [],
      );

      final pts = TeamScoreboardTableBuilder.calcPts(match);
      expect(pts.containsKey('red'), isTrue);
      expect(pts.containsKey('white'), isTrue);
    });

    testWidgets('3. 1本勝ちの公式記録表記テスト（左上に丸囲み技マーク＋全体勝者円）', (tester) async {
      final scoreBox = TeamScoreboardTableBuilder.buildMatchScoreBox(
        [TeamPointDisplay('コ', true)],
        true, // isWinner
        false, // isDraw
        true, // isRed
        false, // isDark
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: scoreBox)),
        ),
      );

      // 技マーク「コ」が表示されていること
      expect(find.text('コ'), findsOneWidget);

      // 左上に配置されていること（Positioned top: 2, left: 2）
      final positionedWidgets = tester.widgetList<Positioned>(
        find.byType(Positioned),
      );
      final topLeftPoint = positionedWidgets.firstWhere(
        (p) => p.top == 2 && p.left == 2,
      );
      expect(topLeftPoint, isNotNull);

      // 全体を囲む勝者円（width: 62, height: 62）が存在すること
      final containers = tester.widgetList<Container>(find.byType(Container));
      final winnerCircle = containers.firstWhere(
        (c) =>
            c.constraints?.minWidth == 62 ||
            (c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).shape == BoxShape.circle &&
                (c.decoration as BoxDecoration).border != null),
      );
      expect(winnerCircle, isNotNull);
    });

    testWidgets('4. 2本勝ちの公式記録表記テスト（左上1本目＋右下2本目＋全体勝者円）', (tester) async {
      final scoreBox = TeamScoreboardTableBuilder.buildMatchScoreBox(
        [TeamPointDisplay('メ', true), TeamPointDisplay('ド', false)],
        true, // isWinner
        false, // isDraw
        true, // isRed
        false, // isDark
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: scoreBox)),
        ),
      );

      expect(find.text('メ'), findsOneWidget);
      expect(find.text('ド'), findsOneWidget);

      final positionedWidgets = tester.widgetList<Positioned>(
        find.byType(Positioned),
      );
      expect(positionedWidgets.any((p) => p.top == 2 && p.left == 2), isTrue);
      expect(
        positionedWidgets.any((p) => p.bottom == 2 && p.right == 2),
        isTrue,
      );
    });

    testWidgets('5. 不戦勝の公式記録表記テスト（左上◯＋右下◯＋全体勝者円）', (tester) async {
      final scoreBox = TeamScoreboardTableBuilder.buildMatchScoreBox(
        [TeamPointDisplay('◯', false), TeamPointDisplay('◯', false)],
        true, // isWinner
        false, // isDraw
        false, // isRed
        false, // isDark
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: scoreBox)),
        ),
      );

      expect(find.text('◯'), findsNWidgets(2));
      final positionedWidgets = tester.widgetList<Positioned>(
        find.byType(Positioned),
      );
      expect(positionedWidgets.any((p) => p.top == 2 && p.left == 2), isTrue);
      expect(
        positionedWidgets.any((p) => p.bottom == 2 && p.right == 2),
        isTrue,
      );
    });

    testWidgets('6. 引き分けの公式記録表記テスト（中央に✕＋勝者円なし）', (tester) async {
      final scoreBox = TeamScoreboardTableBuilder.buildMatchScoreBox(
        [TeamPointDisplay('メ', true)],
        false, // isWinner
        true, // isDraw
        true, // isRed
        false, // isDark
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: scoreBox)),
        ),
      );

      expect(find.text('✕'), findsOneWidget);
      expect(find.text('メ'), findsOneWidget);
    });
  });
}
