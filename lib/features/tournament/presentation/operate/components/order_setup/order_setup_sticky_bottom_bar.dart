import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// オーダー編成画面の下部確定・追加アクションバー
class OrderSetupStickyBottomBar extends StatelessWidget {
  final AppThemeColors themeColors;
  final bool isDark;
  final bool enableLiquidGlass;
  final VoidCallback onAddExtraPosition;
  final VoidCallback onConfirmAndProceed;

  const OrderSetupStickyBottomBar({
    super.key,
    required this.themeColors,
    required this.isDark,
    required this.enableLiquidGlass,
    required this.onAddExtraPosition,
    required this.onConfirmAndProceed,
  });

  @override
  Widget build(BuildContext context) {
    final inputBgColor = themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: enableLiquidGlass ? AppKendoColors.transparent : inputBgColor,
        border: Border(
          top: BorderSide(
            color: enableLiquidGlass ? AppKendoColors.transparent : borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: onAddExtraPosition,
            icon: Icon(
              Icons.add_circle_outline,
              color: isDark
                  ? const Color(0xFF64B5F6)
                  : themeColors.primaryAccent,
            ),
            label: Text(
              'イレギュラー枠を追加する（錬成会用）',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF64B5F6)
                    : themeColors.primaryAccent,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirmAndProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors.primaryAccent,
                foregroundColor: AppKendoColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'このオーダーで確定して進む',
                    style: TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
