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
  });
}
