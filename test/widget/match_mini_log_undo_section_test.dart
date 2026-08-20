import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_mini_log_undo_section.dart';

void main() {
  group('🛡️ MatchMiniLogUndoSection Widget Tests', () {
    testWidgets('Renders empty history state when no valid events', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchMiniLogUndoSection(
              validEvents: const [],
              canUndo: false,
              isDark: false,
              onUndo: () {},
            ),
          ),
        ),
      );

      expect(find.text('操作履歴'), findsOneWidget);
      expect(find.text('操作履歴なし'), findsOneWidget);
    });

    testWidgets('Renders events and triggers onUndo callback', (tester) async {
      bool undoTriggered = false;
      final events = [
        ScoreEvent(
          id: 'e1',
          side: Side.red,
          strikeType: StrikeType.men,
          timestamp: DateTime(2026, 8, 20, 10, 0, 0),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchMiniLogUndoSection(
              validEvents: events,
              canUndo: true,
              isDark: false,
              onUndo: () => undoTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('メン'), findsOneWidget);
      expect(find.text('１つ前の操作を取り消す'), findsOneWidget);

      await tester.tap(find.text('１つ前の操作を取り消す'));
      await tester.pump();

      expect(undoTriggered, true);
    });
  });
}
