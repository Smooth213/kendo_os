import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_jiggle_drag_wrapper.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_slot_layout_calculator.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 スピードダイヤル子アイテム定義
class DockSubItem {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int badgeCount;

  const DockSubItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.badgeCount = 0,
  });
}

/// 🥋 スピードダイヤルの展開形状モード
enum DockLayoutMode {
  /// 縦一列（上下に十分なスペースがある時）
  vertical,

  /// L字型（画面端などで縦の余白が足りない時）
  lShape,
}

/// 🥋 スピードダイヤルの子ボタン（配置＆アニメーション＆ジグルドラッグウィジェット）
class DockSpeedDialItemWidget extends StatelessWidget {
  final DockSubItem item;
  final int index;
  final double progress;
  final double originX;
  final double originY;
  final double dirX;
  final double dirY;
  final bool isDark;
  final AppThemeColors themeColors;
  final double buttonSize;
  final double subSize;
  final double step;
  final DockLayoutMode layoutMode;
  final bool isEditMode;
  final bool isDragging;
  final Offset dragDelta;
  final Animation<double>? jiggleAnimation;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  const DockSpeedDialItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.progress,
    required this.originX,
    required this.originY,
    required this.dirX,
    required this.dirY,
    required this.isDark,
    required this.themeColors,
    this.buttonSize = 58.0,
    this.subSize = 58.0,
    this.step = 66.0,
    this.layoutMode = DockLayoutMode.vertical,
    this.isEditMode = false,
    this.isDragging = false,
    this.dragDelta = Offset.zero,
    this.jiggleAnimation,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    final targetOffset = DockSlotLayoutCalculator.getTournamentSlotOffset(
      index: index,
      layoutMode: layoutMode,
      dirX: dirX,
      dirY: dirY,
      step: step,
    );

    final double centerDiff = (buttonSize - subSize) / 2;
    final double baseItemX =
        originX + centerDiff + (targetOffset.dx * progress);
    final double baseItemY =
        originY + centerDiff + (targetOffset.dy * progress);
    final double currentItemX = baseItemX + (isDragging ? dragDelta.dx : 0.0);
    final double currentItemY = baseItemY + (isDragging ? dragDelta.dy : 0.0);

    return Positioned(
      left: currentItemX,
      top: currentItemY,
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.4 + (0.6 * progress.clamp(0.0, 1.0)),
          child: DockJiggleDragWrapper(
            index: index,
            isEditMode: isEditMode,
            isDragging: isDragging,
            jiggleAnimation: jiggleAnimation,
            onLongPress: () {
              if (item.onLongPress != null) {
                AppHaptics.medium();
                item.onLongPress!();
              }
            },
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
            child: _buildButton(),
          ),
        ),
      ),
    );
  }

  Widget _buildButton() {
    return GestureDetector(
      onTap: () {
        if (!isEditMode) {
          AppHaptics.light();
          item.onTap();
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: subSize,
            height: subSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF1E293B)
                  : AppKendoColors.pureWhite,
              border: Border.all(
                color: item.color.withValues(alpha: isDark ? 0.65 : 0.45),
                width: isDark ? 1.6 : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppKendoColors.pureBlack.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          if (item.badgeCount > 0 && !isEditMode)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: AppKendoColors.redAccent,
                  borderRadius: AppRadius.full,
                  border: Border.all(
                    color: AppKendoColors.pureWhite,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                  style: const TextStyle(
                    color: AppKendoColors.pureWhite,
                    fontSize: AppFontSize.badge,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
