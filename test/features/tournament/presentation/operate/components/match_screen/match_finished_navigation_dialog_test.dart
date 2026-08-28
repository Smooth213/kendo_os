import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_finished_navigation_dialog.dart';

void main() {
  group('MatchFinishedNavigationDialog Tests', () {
    testWidgets(
      '① Displays clear distinctive buttons for new team match and adding matches',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MatchFinishedNavigationDialog(
                isRenseikai: true,
                hasGroupName: false,
                isKachinuki: false,
                isDark: false,
                onQuickNextMatch: () {},
                onAddNextRenseikaiMatch: () {},
                onGoHome: () {},
              ),
            ),
          ),
        );

        // 上：別のチームと対戦（次の団体戦）
        expect(find.text('別のチームと対戦（次の団体戦）'), findsOneWidget);
        expect(find.byIcon(Icons.bolt), findsOneWidget);

        // 下：試合を追加（現在のチームと続行）
        expect(find.text('試合を追加（現在のチームと続行）'), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      },
    );

    testWidgets(
      '② Does not display quick next match button when onQuickNextMatch is null (Hon-sen tournament)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MatchFinishedNavigationDialog(
                isRenseikai: false,
                hasGroupName: false,
                isKachinuki: false,
                isDark: false,
                onQuickNextMatch: null, // 本戦モード時は null
                onGoHome: () {},
              ),
            ),
          ),
        );

        // 本戦モードではクイック対戦ボタンが表示されないこと
        expect(find.text('別のチームと対戦（次の団体戦）'), findsNothing);
      },
    );
  });
}
