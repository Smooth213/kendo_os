import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_infinite_next_dialog.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ MatchInfiniteNextDialog Widget Tests', () {
    testWidgets('Renders MatchInfiniteNextDialog and triggers actions', (
      WidgetTester tester,
    ) async {
      bool finishClicked = false;
      bool restClicked = false;
      bool startImmediatelyClicked = false;

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchInfiniteNextDialog(
              redName: '山田',
              whiteName: '佐藤',
              winnerStreak: 3,
              onFinishInfinite: () {
                finishClicked = true;
              },
              onRestAndReturn: () {
                restClicked = true;
              },
              onStartNextMatchImmediately: () {
                startImmediatelyClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('無限稽古: 次の試合'), findsOneWidget);
      expect(find.text('🔥 挑戦者が入りました！'), findsOneWidget);
      expect(find.text('防衛(赤): 山田 (3連勝中)'), findsOneWidget);
      expect(find.text('挑戦(白): 佐藤'), findsOneWidget);
      expect(find.text('無限稽古を終了'), findsOneWidget);
      expect(find.text('一覧に戻る（休憩）'), findsOneWidget);
      expect(find.text('すぐに次の試合を開始'), findsOneWidget);

      // タップ検証
      await tester.tap(find.text('無限稽古を終了'));
      await tester.pump();
      expect(finishClicked, isTrue);

      await tester.tap(find.text('一覧に戻る（休憩）'));
      await tester.pump();
      expect(restClicked, isTrue);

      await tester.tap(find.text('すぐに次の試合を開始'));
      await tester.pump();
      expect(startImmediatelyClicked, isTrue);
    });
  });
}
