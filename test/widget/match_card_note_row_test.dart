import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_card_note_row.dart';

void main() {
  group('🛡️ MatchCardNoteRow Widget Tests', () {
    testWidgets('Renders note and matchType correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchCardNoteRow(
              displayNote: '第1試合',
              matchType: '先鋒',
              noteColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.textContaining('第1試合'), findsOneWidget);
      expect(find.textContaining('【先鋒】'), findsOneWidget);
    });

    testWidgets('Renders nothing when note and type are empty or default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchCardNoteRow(
              displayNote: '',
              matchType: '選手',
              noteColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.byType(MatchCardNoteRow), findsOneWidget);
      expect(find.textContaining('【選手】'), findsNothing);
    });
  });
}
