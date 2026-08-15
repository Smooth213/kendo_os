import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// プログラムビューア用ツールボタン（ペン、消しゴム、マーカー等の切り替えボタン）
class ProgramViewerToolButton extends StatelessWidget {
  final String tool;
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final bool isDark;
  final Color activeColor;
  final VoidCallback onTap;

  const ProgramViewerToolButton({
    super.key,
    required this.tool,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.isDark,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.sub,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF))
                : AppKendoColors.transparent,
            borderRadius: AppRadius.sub,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppKendoColors.pureBlack.withAlpha(20),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected
                ? activeColor
                : (isDark
                      ? AppKendoColors.white38
                      : const Color(0xFF000000).withValues(alpha: 0.38)),
          ),
        ),
      ),
    );
  }
}

/// プログラムビューア用ペンカラー選択ボタン（ボトムシート内）
class ProgramViewerPenOption extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ProgramViewerPenOption({
    super.key,
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withAlpha(26)
                : AppKendoColors.transparent,
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: isSelected ? color : context.appColors.separatorColor,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.edit, color: color, size: 28),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: isSelected
                        ? AppFontWeight.bold
                        : AppFontWeight.regular,
                    fontSize: AppFontSize.small,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
