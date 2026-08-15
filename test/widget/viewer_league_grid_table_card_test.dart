import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/components/viewer_league_grid_table_card.dart';

void main() {
  group('🛡️ ViewerLeagueGridTableCard Widget Tests', () {
    testWidgets('Renders league grid table headers and ranks', (
      WidgetTester tester,
    ) async {
      final match1 = MatchModel(
        id: 'm1',
        redName: 'チームA: 山田',
        whiteName: 'チームB: 佐藤',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        matchType: 'リーグ戦',
        note: '[リーグ戦]',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewerLeagueGridTableCard(
              groupName: 'Aブロック',
              matches: [match1],
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('勝数'), findsOneWidget);
      expect(find.text('勝者'), findsOneWidget);
      expect(find.text('本数'), findsOneWidget);
      expect(find.text('順位'), findsOneWidget);
      expect(find.text('チームA'), findsWidgets);
      expect(find.text('チームB'), findsWidgets);
    });
  });
}
