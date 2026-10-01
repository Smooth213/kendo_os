import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_display_card.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

  group('[E2E] ドックタイマー ホイール選択＆手入力キーボード同期複合テスト', () {
    testWidgets('キーボード手入力とホイールピッカーの両方でタイマー時間が正確に更新反映されること', (tester) async {
      int changedMinutes = -1;
      int changedSeconds = -1;

      DockTimerState currentState = const DockTimerState(
        initialSeconds: 180,
        remainingSeconds: 180,
        isRunning: false,
      );

      Widget buildHarness() {
        return MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 500,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return DockTimerDisplayCard(
                      timerState: currentState,
                      isRunning: currentState.isRunning,
                      isStopwatch: false,
                      isDark: false,
                      themeColors: themeColors,
                      onTimeChanged: (min, sec) {
                        changedMinutes = min;
                        changedSeconds = sec;
                        setState(() {
                          currentState = currentState.copyWith(
                            initialSeconds: min * 60 + sec,
                            remainingSeconds: min * 60 + sec,
                          );
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // 1. 初期表示の確認（3分00秒）
      expect(find.text('03'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);

      // 2. 分ブロックをタップして手入力モードへ突入
      await tester.tap(find.text('03'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // 3. キーボードで「5」分と入力し確定
      await tester.enterText(find.byType(TextField), '5');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pumpAndSettle();

      expect(changedMinutes, 5);
      expect(changedSeconds, 0);
      expect(find.text('05'), findsOneWidget);

      // 4. 長押ししてホイールピッカーモードへ変形
      await tester.longPress(find.byType(DockTimerDisplayCard));
      await tester.pumpAndSettle();

      expect(find.text('完了'), findsOneWidget);

      // 5. ホイールピッカーモードで「完了」をタップして確定・終了
      await tester.tap(find.text('完了'));
      await tester.pumpAndSettle();

      // 通常表示に戻り、整合性が維持されていること
      expect(find.text('05'), findsOneWidget);
      expect(find.text('タップで手入力 ｜ 長押しでダイヤル'), findsOneWidget);
    });
  });
}
