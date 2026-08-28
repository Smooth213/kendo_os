import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_finished_navigation_dialog.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ MatchFinishedNavigationDialog Widget Tests', () {
    testWidgets('Renders all buttons and triggers callbacks accurately', (
      WidgetTester tester,
    ) async {
      bool addRenseikaiClicked = false;
      bool nextMatchClicked = false;
      bool goHomeClicked = false;
      bool scoreboardClicked = false;

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchFinishedNavigationDialog(
              isRenseikai: true,
              nextMatchId: 'm2',
              nextMatchType: '先鋒',
              tournamentId: 'tour_1',
              hasGroupName: true,
              isKachinuki: false,
              isDark: false,
              onAddNextRenseikaiMatch: () {
                addRenseikaiClicked = true;
              },
              onGoToNextMatch: () {
                nextMatchClicked = true;
              },
              onGoHome: () {
                goHomeClicked = true;
              },
              onShowScoreboard: () {
                scoreboardClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('対戦終了'), findsOneWidget);
      expect(find.textContaining('試合を追加（現在のチームと続行）'), findsOneWidget);
      expect(find.textContaining('次の試合へ進む (先鋒)'), findsOneWidget);
      expect(find.text('大会ホームへ戻る'), findsOneWidget);
      expect(find.text('スコアボードを確認する'), findsOneWidget);

      // タップ検証
      await tester.tap(find.textContaining('試合を追加（現在のチームと続行）'));
      await tester.pump();
      expect(addRenseikaiClicked, isTrue);

      await tester.tap(find.textContaining('次の試合へ進む (先鋒)'));
      await tester.pump();
      expect(nextMatchClicked, isTrue);

      await tester.tap(find.text('大会ホームへ戻る'));
      await tester.pump();
      expect(goHomeClicked, isTrue);

      await tester.tap(find.text('スコアボードを確認する'));
      await tester.pump();
      expect(scoreboardClicked, isTrue);
    });

    testWidgets('Renders bunaiksen home label when tournamentId is bunaiksen', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchFinishedNavigationDialog(
              isRenseikai: false,
              nextMatchId: null,
              tournamentId: 'bunaiksen_123',
              hasGroupName: false,
              isKachinuki: false,
              isDark: false,
              onGoHome: () {},
            ),
          ),
        ),
      );

      expect(find.text('部内戦ホームに戻る'), findsOneWidget);
      expect(find.textContaining('次の試合へ進む'), findsNothing);
      expect(find.text('スコアボードを確認する'), findsNothing);
    });
  });
}
