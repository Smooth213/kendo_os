import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/viewer/components/viewer_team_scoreboard_table_builder.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ ViewerTeamScoreboard Extracted Components Tests', () {
    testWidgets('1. ViewerTeamScoreboardTableBuilder builds rows correctly', (
      tester,
    ) async {
      final headerRow = ViewerTeamScoreboardTableBuilder.buildHeaderRow(
        '赤チーム',
        '白チーム',
        false,
      );
      final totalRow = ViewerTeamScoreboardTableBuilder.buildTotalRow(
        TeamMatchResult(
          redPoints: 4,
          whitePoints: 1,
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
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('2. 観戦側 1本勝ちの公式記録表記テスト（左上に丸囲み技マーク＋全体勝者円）', (tester) async {
      final matchRow = ViewerTeamScoreboardTableBuilder.buildMatchRow(
        const MatchListProjection(
          id: 'm1',
          tournamentId: 't1',
          matchOrder: 1,
          matchType: '先鋒',
          status: 'finished',
          redName: 'A道場 : 皿田',
          whiteName: 'B道場 : 選手',
          redScore: 1,
          whiteScore: 0,
          redPointMarks: ['コ'],
          firstPointSide: 'red',
        ),
        tester.element(find.byType(Container)),
        false,
        ['皿田'],
        ['選手'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Table(children: [matchRow])),
        ),
      );

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget);

      final positionedWidgets = tester.widgetList<Positioned>(
        find.byType(Positioned),
      );
      expect(positionedWidgets.any((p) => p.top == 2 && p.left == 2), isTrue);
    });
  });
}
