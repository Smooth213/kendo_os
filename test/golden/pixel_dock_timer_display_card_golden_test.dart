import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_display_card.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] ドックタイマー表示カード視覚ピクセルテスト', () {
    testWidgets('通常ライトモードでカードおよび時間が明瞭に描画されオーバーフローがないこと', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final lightColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      const state = DockTimerState(
        initialSeconds: 180,
        remainingSeconds: 180,
        isRunning: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [lightColors]),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 500,
                child: DockTimerDisplayCard(
                  timerState: state,
                  isRunning: true,
                  isStopwatch: false,
                  isDark: false,
                  themeColors: lightColors,
                  onTimeChanged: (min, sec) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DockTimerDisplayCard), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ダークモードかつ時間切れ（0秒）の停止状態が明瞭に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final darkColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');
      const state = DockTimerState(
        initialSeconds: 180,
        remainingSeconds: 0,
        isRunning: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: [darkColors]),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 500,
                child: DockTimerDisplayCard(
                  timerState: state,
                  isRunning: false,
                  isStopwatch: false,
                  isDark: true,
                  themeColors: darkColors,
                  onTimeChanged: (min, sec) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DockTimerDisplayCard), findsOneWidget);
      expect(find.text('00'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
