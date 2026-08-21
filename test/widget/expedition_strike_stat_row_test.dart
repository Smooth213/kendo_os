import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_strike_stat_row.dart';

void main() {
  group('🛡️ ExpeditionStrikeStatRow Widget Tests', () {
    testWidgets('1. ExpeditionStrikeStatRow renders strike badges correctly', (
      WidgetTester tester,
    ) async {
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
}
