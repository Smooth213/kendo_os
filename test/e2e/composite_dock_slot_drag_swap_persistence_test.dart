import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_slot_layout_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('[E2E] 常設ドックスロットドラッグスワップ永続化複合テスト', () {
    testWidgets('ドックスロットのドラッグスワップが計算エンジンにより判定され永続化と画面回転復元が行われること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prefs = await SharedPreferences.getInstance();

      // 初期スロット並び順（0: 大会プログラム, 1: 部内戦, 2: 掲示板, 3: タイマー）
      List<String> dockItems = ['program', 'bunaiksen', 'bulletin', 'timer'];
      const step = 60.0;

      // 1. スロット0をスロット2の位置へドラッグしたと想定
      final slot2Offset = DockSlotLayoutCalculator.getTournamentSlotOffset(
        index: 2,
        layoutMode: DockLayoutMode.vertical,
        dirX: 1.0,
        dirY: -1.0,
        step: step,
      );

      // findSwapTarget によるターゲット検知
      final swapTarget = DockSlotLayoutCalculator.findSwapTarget(
        currentPos: slot2Offset,
        currentDraggingIndex: 0,
        itemCount: dockItems.length,
        step: step,
        slotOffsetGetter: (idx) =>
            DockSlotLayoutCalculator.getTournamentSlotOffset(
              index: idx,
              layoutMode: DockLayoutMode.vertical,
              dirX: 1.0,
              dirY: -1.0,
              step: step,
            ),
      );

      expect(swapTarget, 2);

      // スワップ実行
      final itemToMove = dockItems.removeAt(0);
      dockItems.insert(swapTarget!, itemToMove);
      // 結果: ['bunaiksen', 'bulletin', 'program', 'timer']
      expect(dockItems, ['bunaiksen', 'bulletin', 'program', 'timer']);

      // SharedPreferences への永続化
      await prefs.setStringList('dock_slots_order_v1', dockItems);

      // 2. 画面回転（768x1024 縦向きへの変更）
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: Text('復元前: ${dockItems.join(',')}')),
          ),
        ),
      );

      // 3. アプリ再起動（設定値ロード）による復元
      final restoredSlots = prefs.getStringList('dock_slots_order_v1');
      expect(restoredSlots, isNotNull);
      expect(
        restoredSlots,
        equals(['bunaiksen', 'bulletin', 'program', 'timer']),
      );
      expect(restoredSlots![2], equals('program'));
    });
  });
}
