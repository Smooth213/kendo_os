import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_sub_item_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_slot_layout_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_dock_items_order_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class BunaiksenAnimatedDockItem extends StatelessWidget {
  final int index;
  final BunaiksenDockItemType item;
  final double buttonX;
  final double buttonY;
  final double itemStep;
  final bool isVertical;
  final double dirX;
  final double dirY;
  final AppThemeColors themeColors;
  final bool isDark;
  final int itemCount;
  final Animation<double> expandAnimation;
  final AnimationController jiggleController;
  final bool isEditMode;
  final bool isDragging;
  final Offset dragDelta;
  final bool isTimerRunning;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onPanStart;
  final void Function(DragUpdateDetails details) onPanUpdate;
  final VoidCallback onPanEnd;

  const BunaiksenAnimatedDockItem({
    super.key,
    required this.index,
    required this.item,
    required this.buttonX,
    required this.buttonY,
    required this.itemStep,
    required this.isVertical,
    required this.dirX,
    required this.dirY,
    required this.themeColors,
    required this.isDark,
    required this.itemCount,
    required this.expandAnimation,
    required this.jiggleController,
    required this.isEditMode,
    required this.isDragging,
    required this.dragDelta,
    this.isTimerRunning = false,
    required this.onTap,
    required this.onLongPress,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    final offset = DockSlotLayoutCalculator.getBunaiksenSlotOffset(
      index: index,
      isVertical: isVertical,
      dirX: dirX,
      dirY: dirY,
      step: itemStep,
    );
    final targetX = buttonX + offset.dx;
    final targetY = buttonY + offset.dy;

    final IconData itemIcon;
    final Color itemColor;
    if (item == BunaiksenDockItemType.timer) {
      itemIcon = isTimerRunning ? Icons.timer_rounded : Icons.timer_outlined;
      itemColor = isTimerRunning
          ? AppKendoColors.deepOrange
          : item.colorForMode(isDark);
    } else {
      itemIcon = item.icon;
      itemColor = item.colorForMode(isDark);
    }

    return AnimatedBuilder(
      animation: expandAnimation,
      builder: (context, child) {
        final p = expandAnimation.value;
        final curX = buttonX + (targetX - buttonX) * p;
        final curY = buttonY + (targetY - buttonY) * p;

        return Positioned(
          left: curX,
          top: curY,
          child: Opacity(
            opacity: p.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.4 + (0.6 * p.clamp(0.0, 1.0)),
              child: BunaiksenSubItemButton(
                icon: itemIcon,
                color: itemColor,
                themeColors: themeColors,
                isDark: isDark,
                index: index,
                isEditMode: isEditMode,
                isDragging: isDragging,
                dragDelta: dragDelta,
                jiggleAnimation: jiggleController,
                onTap: onTap,
                onLongPress: onLongPress,
                onPanStart: (_) => onPanStart(),
                onPanUpdate: onPanUpdate,
                onPanEnd: (_) => onPanEnd(),
              ),
            ),
          ),
        );
      },
    );
  }
}
