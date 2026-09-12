import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_jiggle_drag_wrapper.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 部内戦スピードダイヤル子アイテムのボタンウィジェット（58px 大会ホーム完全統一仕様）
class BunaiksenSubItemButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final AppThemeColors themeColors;
  final bool isDark;
  final int index;
  final bool isEditMode;
  final bool isDragging;
  final Offset dragDelta;
  final Animation<double>? jiggleAnimation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  const BunaiksenSubItemButton({
    super.key,
    required this.icon,
    required this.color,
    required this.themeColors,
    required this.isDark,
    required this.index,
    this.isEditMode = false,
    this.isDragging = false,
    this.dragDelta = Offset.zero,
    this.jiggleAnimation,
    required this.onTap,
    required this.onLongPress,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: isDragging ? dragDelta : Offset.zero,
      child: DockJiggleDragWrapper(
        index: index,
        isEditMode: isEditMode,
        isDragging: isDragging,
        jiggleAnimation: jiggleAnimation,
        onLongPress: onLongPress,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: GestureDetector(
          onTap: () {
            if (!isEditMode) {
              AppHaptics.light();
              onTap();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 58.0, // 大会ホームと完全統一
            height: 58.0, // 大会ホームと完全統一
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : AppKendoColors.pureWhite,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.65 : 0.45),
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
            child: Center(child: Icon(icon, color: color, size: 26)),
          ),
        ),
      ),
    );
  }
}
