import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_card_action_buttons.dart';

void main() {
  group('🛡️ MatchCardActionButtons Widget Tests', () {
    testWidgets('Renders all buttons and responds to taps', (
      WidgetTester tester,
    ) async {
      bool summaryPressed = false;
      bool infoPressed = false;
      bool scorePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCardActionButtons(
              showSummaryButton: true,
              showInfoButton: true,
              showScoreButton: true,
              textColor: Colors.white,
              subTextColor: Colors.grey,
              onSummaryPressed: () => summaryPressed = true,
              onInfoPressed: () => infoPressed = true,
              onScorePressed: () => scorePressed = true,
            ),
          ),
        ),
      );

      expect(find.text('簡易'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('スコア'), findsOneWidget);

      await tester.tap(find.text('簡易'));
      expect(summaryPressed, isTrue);

      await tester.tap(find.byIcon(Icons.info_outline));
      expect(infoPressed, isTrue);

      await tester.tap(find.text('スコア'));
      expect(scorePressed, isTrue);
    });

    testWidgets('Hides buttons when flags are false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchCardActionButtons(
              showSummaryButton: false,
              showInfoButton: false,
              showScoreButton: false,
              textColor: Colors.white,
              subTextColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('簡易'), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.text('スコア'), findsNothing);
    });
  });
}
