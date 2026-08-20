import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_score_table_card.dart';

void main() {
  group('🛡️ ViewerBunaiksenScoreTableCard Widget Tests', () {
    testWidgets('Renders score table card with red and white teams', (
      tester,
    ) async {
      final matches = [
        MatchModel(
          id: 'test_m1',
          matchType: '先鋒',
          redName: '東京道場:山田 太郎',
          whiteName: '大阪道場:佐藤 次郎',
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
          order: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewerBunaiksenScoreTableCard(
              groupName: 'Aブロック',
              matches: matches,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('東京道場 vs 大阪道場'), findsOneWidget);
      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('本/勝'), findsOneWidget);
    });
  });
}
