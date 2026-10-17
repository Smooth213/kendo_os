import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_finished_navigation_dialog.dart';

void main() {
  group('[Widget] MatchFinishedNavigationDialog テスト', () {
    testWidgets('新規団体戦および試合追加のための明確に区別されたボタン一覧が表示されること', (tester) async {
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
    });

    testWidgets('本戦大会時（onQuickNextMatchがnull）に次の試合ボタンが表示されないこと', (
      tester,
    ) async {
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
    });

    testWidgets('全ボタン一覧が表示されコールバックが正確に実行されること', (tester) async {
      bool addRenseikaiClicked = false;
      bool nextMatchClicked = false;
      bool goHomeClicked = false;
      bool scoreboardClicked = false;

      await tester.pumpWidget(
        MaterialApp(
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

    testWidgets('tournamentId is 部内戦において 部内戦 home labelが正しく描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
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
