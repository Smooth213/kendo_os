import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_league_points_section.dart';

void main() {
  group('🛡️ CategoryLeaguePointsSection Widget Tests', () {
    testWidgets('Renders league points text fields and handles input', (
      WidgetTester tester,
    ) async {
      double win = 3.0;
      double loss = 0.0;
      double draw = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategoryLeaguePointsSection(
                  keyPrefix: 'test_category',
                  winPoint: win,
                  lossPoint: loss,
                  drawPoint: draw,
                  onWinChanged: (val) => setState(() => win = val),
                  onLossChanged: (val) => setState(() => loss = val),
                  onDrawChanged: (val) => setState(() => draw = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('勝ち点（リーグ戦の順位決定用）'), findsOneWidget);
      expect(find.text('勝ち（点）'), findsOneWidget);
      expect(find.text('負け（点）'), findsOneWidget);
      expect(find.text('引き分け（点）'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('win_pt_test_category')),
        '5.0',
      );
      await tester.pumpAndSettle();

      expect(win, 5.0);
    });
  });
}
