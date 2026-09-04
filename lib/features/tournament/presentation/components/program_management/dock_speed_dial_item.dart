import 'package:flutter/material.dart';
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
  final int badgeCount;

  const DockSubItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
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

/// 🥋 スピードダイヤルの子ボタン（配置＆アニメーションウィジェット）
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
  });

  @override
  Widget build(BuildContext context) {
    // 流動的配置のオフセット計算（縦一列 vs L字型）
    double targetDx = 0.0;
    double targetDy = 0.0;

    if (layoutMode == DockLayoutMode.vertical) {
      targetDx = 0.0;
      targetDy = dirY * step * (index + 1);
    } else {
      switch (index) {
        case 0: // 垂直 1個目 (プログラム)
          targetDy = dirY * step * 1.0;
          break;
        case 1: // 垂直 2個目 (チーム状況)
          targetDy = dirY * step * 2.0;
          break;
        case 2: // 垂直 3個目 (対戦表)
          targetDy = dirY * step * 3.0;
          break;
        case 3: // 水平 1個目 (クイックメモ)
          targetDx = dirX * step * 1.0;
          break;
        case 4: // 水平 2個目 (お知らせ)
          targetDx = dirX * step * 2.0;
          break;
        case 5: // 水平 3個目 (ヘルプ)
          targetDx = dirX * step * 3.0;
          break;
        case 6: // 垂直 4個目 (設定)
          targetDy = dirY * step * 4.0;
          break;
        default:
          targetDy = dirY * step * ((index % 4) + 1);
          targetDx = dirX * step * (index ~/ 4);
          break;
      }
    }

    final double centerDiff = (buttonSize - subSize) / 2;
    final double currentItemX = originX + centerDiff + (targetDx * progress);
    final double currentItemY = originY + centerDiff + (targetDy * progress);

    return Positioned(
      left: currentItemX,
      top: currentItemY,
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.4 + (0.6 * progress.clamp(0.0, 1.0)),
          child: _buildButton(),
        ),
      ),
    );
  }

  Widget _buildButton() {
    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        item.onTap();
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
                color: item.color.withValues(alpha: 0.45),
                width: 1.4,
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
          if (item.badgeCount > 0)
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
