import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 スピードダイヤル子アイテムの純粋アイコンボタンウィジェット（タイトル非表示・ピュアアイコン仕様）
class BunaiksenSubItemButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final AppThemeColors themeColors;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const BunaiksenSubItemButton({
    super.key,
    required this.icon,
    required this.color,
    required this.themeColors,
    required this.isDark,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppKendoColors.pureWhite,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.55), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: AppKendoColors.pureBlack.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: Icon(icon, color: color, size: 26)),
      ),
    );
  }
}
