import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';

/// 🥋 ドックのスロット座標計算およびドラッグ近接スワップ判定ヘルパー
class DockSlotLayoutCalculator {
  DockSlotLayoutCalculator._();

  /// 大会ホームドックのスロット相対オフセット計算
  static Offset getTournamentSlotOffset({
    required int index,
    required DockLayoutMode layoutMode,
    required double dirX,
    required double dirY,
    required double step,
  }) {
    if (layoutMode == DockLayoutMode.vertical) {
      return Offset(0.0, dirY * step * (index + 1));
    }
    switch (index) {
      case 0:
        return Offset(0.0, dirY * step * 1.0);
      case 1:
        return Offset(0.0, dirY * step * 2.0);
      case 2:
        return Offset(0.0, dirY * step * 3.0);
      case 3:
        return Offset(0.0, dirY * step * 4.0);
      case 4:
        return Offset(dirX * step * 1.0, 0.0);
      case 5:
        return Offset(dirX * step * 2.0, 0.0);
      case 6:
        return Offset(dirX * step * 3.0, 0.0);
      case 7:
        return Offset(dirX * step * 4.0, 0.0);
      case 8:
        return Offset(dirX * step * 1.0, dirY * step * 1.0);
      default:
        return Offset(
          dirX * step * (index ~/ 4),
          dirY * step * ((index % 4) + 1),
        );
    }
  }

  /// 部内戦ドックのスロット相対オフセット計算
  static Offset getBunaiksenSlotOffset({
    required int index,
    required bool isVertical,
    required double dirX,
    required double dirY,
    required double step,
  }) {
    if (isVertical) {
      return Offset(0.0, dirY * step * (index + 1));
    }
    switch (index) {
      case 0:
        return Offset(0.0, dirY * step * 1.0);
      case 1:
        return Offset(0.0, dirY * step * 2.0);
      case 2:
        return Offset(0.0, dirY * step * 3.0);
      case 3:
        return Offset(0.0, dirY * step * 4.0);
      case 4:
        return Offset(dirX * step * 1.0, 0.0);
      case 5:
        return Offset(dirX * step * 2.0, 0.0);
      case 6:
        return Offset(dirX * step * 3.0, 0.0);
      default:
        return Offset(
          dirX * step * ((index ~/ 4) + 1),
          dirY * step * ((index % 4) + 1),
        );
    }
  }

  /// ドラッグ中の現在位置から最も近接するスワップ対象スロットを探す
  static int? findSwapTarget({
    required Offset currentPos,
    required int currentDraggingIndex,
    required int itemCount,
    required double step,
    required Offset Function(int index) slotOffsetGetter,
  }) {
    for (int target = 0; target < itemCount; target++) {
      if (target == currentDraggingIndex) continue;
      final targetSlot = slotOffsetGetter(target);
      final dist = (currentPos - targetSlot).distance;
      if (dist < step * 0.55) {
        return target;
      }
    }
    return null;
  }
}
