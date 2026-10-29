import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_slot_layout_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';

void main() {
  group('[Unit] 常設ドックスロット配置座標およびドラッグスワップ判定単体テスト', () {
    test('大会ホーム用ドックのスロット相対座標が縦横複合モードに応じて決定論的に算出されること', () {
      const step = 64.0;
      const dirX = 1.0;
      const dirY = -1.0;

      // 縦配置モード
      final vOffset0 = DockSlotLayoutCalculator.getTournamentSlotOffset(
        index: 0,
        layoutMode: DockLayoutMode.vertical,
        dirX: dirX,
        dirY: dirY,
        step: step,
      );
      expect(vOffset0, const Offset(0.0, -64.0));

      final vOffset2 = DockSlotLayoutCalculator.getTournamentSlotOffset(
        index: 2,
        layoutMode: DockLayoutMode.vertical,
        dirX: dirX,
        dirY: dirY,
        step: step,
      );
      expect(vOffset2, const Offset(0.0, -192.0));

      // 複合配置モード
      final mOffset0 = DockSlotLayoutCalculator.getTournamentSlotOffset(
        index: 0,
        layoutMode: DockLayoutMode.lShape,
        dirX: dirX,
        dirY: dirY,
        step: step,
      );
      expect(mOffset0, const Offset(0.0, -64.0));

      final mOffset4 = DockSlotLayoutCalculator.getTournamentSlotOffset(
        index: 4,
        layoutMode: DockLayoutMode.lShape,
        dirX: dirX,
        dirY: dirY,
        step: step,
      );
      expect(mOffset4, const Offset(64.0, 0.0));

      final mOffset8 = DockSlotLayoutCalculator.getTournamentSlotOffset(
        index: 8,
        layoutMode: DockLayoutMode.lShape,
        dirX: dirX,
        dirY: dirY,
        step: step,
      );
      expect(mOffset8, const Offset(64.0, -64.0));
    });

    test('部内戦用ドックのスロット相対座標が方向と配置フラグに応じて正しく計算されること', () {
      const step = 60.0;
      const dirX = -1.0;
      const dirY = -1.0;

      // 縦モード
      final bVert = DockSlotLayoutCalculator.getBunaiksenSlotOffset(
        index: 1,
        isVertical: true,
        dirX: dirX,
        dirY: dirY,
        step: step,
      );
      expect(bVert, const Offset(0.0, -120.0));

      // 横展開モード
      final bHoriz0 = DockSlotLayoutCalculator.getBunaiksenSlotOffset(
        index: 0,
        isVertical: false,
        dirX: dirX,
        dirY: dirY,
        step: step,
      );
      expect(bHoriz0, const Offset(0.0, -60.0));

      final bHoriz5 = DockSlotLayoutCalculator.getBunaiksenSlotOffset(
        index: 5,
        isVertical: false,
        dirX: dirX,
        dirY: dirY,
        step: step,
      );
      expect(bHoriz5, const Offset(-120.0, 0.0));
    });

    test('ドラッグ中の現在位置から距離閾値に基づき最も近接するスワップ先が特定されること', () {
      const step = 60.0;
      Offset slotGetter(int idx) => Offset(0.0, -60.0 * (idx + 1));

      // ターゲット1番スロット(0, -120)の極近傍
      final targetHit = DockSlotLayoutCalculator.findSwapTarget(
        currentPos: const Offset(5.0, -122.0),
        currentDraggingIndex: 0,
        itemCount: 4,
        step: step,
        slotOffsetGetter: slotGetter,
      );
      expect(targetHit, 1);

      // 自分自身（index: 0）の位置に近い場合はnull
      final selfHit = DockSlotLayoutCalculator.findSwapTarget(
        currentPos: const Offset(2.0, -61.0),
        currentDraggingIndex: 0,
        itemCount: 4,
        step: step,
        slotOffsetGetter: slotGetter,
      );
      expect(selfHit, isNull);

      // どのスロットからも離れている場合（閾値 step * 0.55 = 33px 外）
      final noHit = DockSlotLayoutCalculator.findSwapTarget(
        currentPos: const Offset(200.0, 200.0),
        currentDraggingIndex: 0,
        itemCount: 4,
        step: step,
        slotOffsetGetter: slotGetter,
      );
      expect(noHit, isNull);
    });
  });
}
