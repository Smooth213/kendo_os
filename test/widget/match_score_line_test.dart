import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_score_line.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

void main() {
  group('🛡️ MatchScoreLine Widget Tests', () {
    testWidgets('Renders empty space when no points and not draw', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreLine(
              redPoints: [],
              whitePoints: [],
              isDraw: false,
              redColor: Colors.red,
              whiteTextColor: Colors.white,
              dividerTextColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('ー'), findsNothing);
      expect(find.text('×'), findsNothing);
    });

    testWidgets('Renders score marks with dash separator correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreLine(
              redPoints: [PointMark(mark: 'メ', isFirst: true)],
              whitePoints: [PointMark(mark: 'コ', isFirst: false)],
              isDraw: false,
              redColor: Colors.red,
              whiteTextColor: Colors.white,
              dividerTextColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('メ'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget);
      expect(find.text('ー'), findsOneWidget);
      expect(find.text('×'), findsNothing);
    });

    testWidgets('Renders draw mark × correctly when 0-0 finished', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreLine(
              redPoints: [],
              whitePoints: [],
              isDraw: true,
              redColor: Colors.red,
              whiteTextColor: Colors.white,
              dividerTextColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('×'), findsOneWidget);
      expect(find.text('ー'), findsNothing);
    });
  });
}
