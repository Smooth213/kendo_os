import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_slot_layout_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';

void main() {
  group('[Governance] 常設ドックスロット配置座標およびスワップ決定論保証規約', () {
    test('スロット相対オフセット計算が決定論的であり同一入力に対し常に同一座標を算出すること', () {
      const step = 64.0;
      final offset1 = DockSlotLayoutCalculator.getTournamentSlotOffset(
        index: 1,
        layoutMode: DockLayoutMode.vertical,
        dirX: 1.0,
        dirY: -1.0,
        step: step,
      );
      final offset2 = DockSlotLayoutCalculator.getTournamentSlotOffset(
        index: 1,
        layoutMode: DockLayoutMode.vertical,
        dirX: 1.0,
        dirY: -1.0,
        step: step,
      );

      expect(offset1, equals(offset2));
      expect(offset1.dx, 0.0);
      expect(offset1.dy, -128.0);
    });

    test('ドラッグスワップ判定において閾値内の最も近いスロットが唯一無二に特定されること', () {
      const step = 60.0;
      Offset slotGetter(int idx) => Offset(0.0, -60.0 * (idx + 1));

      final hitIndex = DockSlotLayoutCalculator.findSwapTarget(
        currentPos: const Offset(0.0, -182.0),
        currentDraggingIndex: 0,
        itemCount: 4,
        step: step,
        slotOffsetGetter: slotGetter,
      );

      // index 2 (-180.0) に極めて近いため 2 が特定される
      expect(hitIndex, 2);
    });

    test('静的解析においてDockSlotLayoutCalculatorがドックコンポーネント群から参照されていること', () {
      final calcFile = File(
        'lib/features/tournament/presentation/components/program_management/dock_slot_layout_calculator.dart',
      );
      expect(calcFile.existsSync(), isTrue);

      final dockButtonFile = File(
        'lib/features/tournament/presentation/components/program_management/floating_program_dock_button.dart',
      );
      expect(dockButtonFile.existsSync(), isTrue);
      final content = dockButtonFile.readAsStringSync();
      expect(content.contains('DockSlotLayoutCalculator'), isTrue);
    });
  });
}
