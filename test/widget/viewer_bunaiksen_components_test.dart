import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_match_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ ViewerBunaiksen Components Tests', () {
    testWidgets('1. ViewerBunaiksenMatchCard renders correctly', (
      tester,
    ) async {
      final match = MatchModel(
        id: 'm1',
        matchOrder: 1,
        redName: '佐藤',
        whiteName: '鈴木',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        matchType: '個人戦',
        note: '予選',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewerBunaiksenMatchCard(
              match: match,
              index: 0,
              tournamentId: 'bunaiksen_20260821',
              dojoId: 'dojo1',
            ),
          ),
        ),
      );

      expect(find.text('佐藤'), findsOneWidget);
      expect(find.text('鈴木'), findsOneWidget);
      expect(find.text('第1試合'), findsOneWidget);
    });

    test('2. ViewerBunaiksenMatchCard.buildScoreMarks handles zero scores', () {
      final match = MatchModel(
        id: 'm2',
        matchOrder: 2,
        redName: '佐藤',
        whiteName: '鈴木',
        redScore: 0,
        whiteScore: 0,
        status: 'waiting',
        matchType: '個人戦',
      );

      final widget = ViewerBunaiksenMatchCard.buildScoreMarks(match, false);
      expect(widget, isNotNull);
    });
  });
}
