import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_display_card.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  final dummyColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

  group('[Widget] DockTimerDisplayCard ウィジェットテスト', () {
    testWidgets('通常表示においてフォーマットされた時間とプログレスバーが描画されること', (tester) async {
      const state = DockTimerState(
        initialSeconds: 180,
        remainingSeconds: 120,
        isRunning: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockTimerDisplayCard(
              timerState: state,
              isRunning: false,
              isStopwatch: false,
              isDark: false,
              themeColors: dummyColors,
              onTimeChanged: (min, sec) {},
            ),
          ),
        ),
      );

      expect(find.text('02'), findsOneWidget); // 分
      expect(find.text('00'), findsOneWidget); // 秒
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('タップで手入力 ｜ 長押しでダイヤル'), findsOneWidget);
    });

    testWidgets('分ブロックタップにより手入力モードへ切り替わり確定アイコンが表示されること', (tester) async {
      const state = DockTimerState(
        initialSeconds: 180,
        remainingSeconds: 180,
        isRunning: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockTimerDisplayCard(
              timerState: state,
              isRunning: false,
              isStopwatch: false,
              isDark: false,
              themeColors: dummyColors,
              onTimeChanged: (min, sec) {},
            ),
          ),
        ),
      );

      // 分ブロックをタップ
      await tester.tap(find.text('03'));
      await tester.pumpAndSettle();

      expect(find.text('分を入力して確定（または秒をタップ）'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('長押しによりドラムロールホイールピッカーモードへ変形すること', (tester) async {
      const state = DockTimerState(
        initialSeconds: 180,
        remainingSeconds: 180,
        isRunning: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockTimerDisplayCard(
              timerState: state,
              isRunning: false,
              isStopwatch: false,
              isDark: false,
              themeColors: dummyColors,
              onTimeChanged: (min, sec) {},
            ),
          ),
        ),
      );

      // 長押しを実行
      await tester.longPress(find.byType(DockTimerDisplayCard));
      await tester.pumpAndSettle();

      expect(find.text('完了'), findsOneWidget);
    });

    testWidgets('タイムアップ時に警告ヘッダーが表示されること', (tester) async {
      const state = DockTimerState(
        initialSeconds: 180,
        remainingSeconds: 0,
        isRunning: false,
        isFinished: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockTimerDisplayCard(
              timerState: state,
              isRunning: false,
              isStopwatch: false,
              isDark: false,
              themeColors: dummyColors,
              onTimeChanged: (min, sec) {},
            ),
          ),
        ),
      );

      expect(find.text('⏰ TIME UP !'), findsOneWidget);
    });
  });
}
