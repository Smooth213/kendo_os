import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_bottom_sheet.dart';

Widget createTestWidget({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('⏱️ DockTimerBottomSheet Widget Tests', () {
    testWidgets('初期表示で3分のデジタル表示と定型プリセットが表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // タイトルの存在確認
      expect(find.text('独立型タイマー'), findsOneWidget);

      // 初期デジタル時間の表示確認
      expect(find.text('03:00'), findsOneWidget);

      // プリセットボタンの確認
      expect(find.text('3分 (試合間)'), findsOneWidget);
      expect(find.text('5分 (回り稽古)'), findsOneWidget);
      expect(find.text('10分 (アップ)'), findsOneWidget);
      expect(find.text('15分 (合同稽古)'), findsOneWidget);

      // 操作ボタンの確認
      expect(find.text('スタート'), findsOneWidget);
      expect(find.text('リセット'), findsOneWidget);
    });

    testWidgets('プリセットタップでタイマー設定が切り替わること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // 5分プリセットをタップ
      await tester.tap(find.text('5分 (回り稽古)'));
      await tester.pumpAndSettle();

      // デジタル時間が05:00に切り替わること
      expect(find.text('05:00'), findsOneWidget);

      // +1分をタップ
      await tester.tap(find.text('+1分'));
      await tester.pumpAndSettle();
      expect(find.text('06:00'), findsOneWidget);
    });
  });
}
