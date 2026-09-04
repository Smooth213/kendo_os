import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 ドックの親ボタン（金枠ハイライト・展開時✕マーク回転変形・未読バッジ内包）
class DockParentButton extends StatelessWidget {
  final bool isDark;
  final AppThemeColors themeColors;
  final int unreadCount;
  final bool isExpanded;
  final bool isDocked;
  final double buttonSize;
  final double closeButtonSize;
  final VoidCallback onTap;

  const DockParentButton({
    super.key,
    required this.isDark,
    required this.themeColors,
    required this.unreadCount,
    required this.isExpanded,
    required this.isDocked,
    required this.buttonSize,
    required this.closeButtonSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentSize = isExpanded ? closeButtonSize : buttonSize;
    final currentIconSize = isExpanded ? 22.0 : 26.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isExpanded
                  ? [AppKendoColors.deepOrange, AppKendoColors.redAccent]
                  : (isDark
                        ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                        : [
                            themeColors.cardBackground,
                            themeColors.cardBackground.withValues(alpha: 0.95),
                          ]),
            ),
            border: Border.all(
              color: isExpanded
                  ? AppKendoColors.pureWhite.withValues(alpha: 0.8)
                  : AppKendoColors.ipponGold.withValues(
                      alpha: isDocked ? 0.6 : 0.95,
                    ),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? AppKendoColors.redAccent.withValues(alpha: 0.4)
                    : AppKendoColors.ipponGold.withValues(
                        alpha: isDocked ? 0.25 : 0.4,
                      ),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: AppKendoColors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(
                child: AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    isExpanded ? Icons.close_rounded : Icons.menu_book_rounded,
                    color: isExpanded
                        ? AppKendoColors.pureWhite
                        : (isDark
                              ? AppKendoColors.ipponGold
                              : themeColors.primaryAccent),
                    size: currentIconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!isDocked && unreadCount > 0 && !isExpanded)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: AppKendoColors.redAccent,
                borderRadius: AppRadius.full,
                border: Border.all(color: AppKendoColors.pureWhite, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: AppKendoColors.pureBlack.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: AppKendoColors.pureWhite,
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
