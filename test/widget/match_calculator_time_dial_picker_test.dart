import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_time_dial_picker.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] MatchCalculatorTimeDialPicker ドラムロールダイヤルピッカー検証テスト', () {
    testWidgets('初期インデックス値で正しくホイールが描画されドラムロール操作で値変更通知が発火すること', (tester) async {
      final hourController = FixedExtentScrollController(initialItem: 9);
      final minuteController = FixedExtentScrollController(initialItem: 30);

      int changedHour = -1;
      int changedMinute = -1;

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCalculatorTimeDialPicker(
              themeColors: themeColors,
              primaryAccent: Colors.blue,
              hourScrollController: hourController,
              minuteScrollController: minuteController,
              onHourChanged: (val) => changedHour = val,
              onMinuteChanged: (val) => changedMinute = val,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('wheel_picker_container')),
        findsOneWidget,
      );
      expect(find.text('時'), findsOneWidget);
      expect(find.text('分'), findsOneWidget);
      expect(find.text('09'), findsWidgets);
      expect(find.text('30'), findsWidgets);

      // 時間ホイールをスクロール
      final cupertinoPickers = find.byType(CupertinoPicker);
      expect(cupertinoPickers, findsNWidgets(2));

      await tester.drag(cupertinoPickers.first, const Offset(0, -70));
      await tester.pumpAndSettle();
      expect(changedHour, greaterThanOrEqualTo(0));

      // 分ホイールをスクロール
      await tester.drag(cupertinoPickers.last, const Offset(0, -70));
      await tester.pumpAndSettle();
      expect(changedMinute, greaterThanOrEqualTo(0));

      hourController.dispose();
      minuteController.dispose();
    });

    testWidgets('ダークモード環境においても選択枠と文字スタイルが破綻なく描画されること', (tester) async {
      final hourController = FixedExtentScrollController(initialItem: 14);
      final minuteController = FixedExtentScrollController(initialItem: 45);

      final darkColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: MatchCalculatorTimeDialPicker(
              themeColors: darkColors,
              primaryAccent: Colors.indigo,
              hourScrollController: hourController,
              minuteScrollController: minuteController,
              onHourChanged: (_) {},
              onMinuteChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('wheel_picker_container')),
        findsOneWidget,
      );
      expect(find.text('14'), findsWidgets);
      expect(find.text('45'), findsWidgets);

      hourController.dispose();
      minuteController.dispose();
    });
  });
}
