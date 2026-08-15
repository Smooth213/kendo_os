import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_players_score_row.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

void main() {
  group('🛡️ MatchPlayersScoreRow Widget Tests', () {
    testWidgets('Renders player names and score line correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchPlayersScoreRow(
              redName: '塚本 大道',
              whiteName: '久安 智也',
              isRedOwn: true,
              isWhiteOwn: false,
              redPoints: [PointMark(mark: 'メ', isFirst: true)],
              whitePoints: [PointMark(mark: 'コ', isFirst: false)],
              isDraw: false,
              textColor: Colors.white,
              subTextColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('塚本 大道'), findsOneWidget);
      expect(find.text('久安 智也'), findsOneWidget);
      expect(find.text('メ'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget);
      expect(find.text('ー'), findsOneWidget);
    });
  });
}
