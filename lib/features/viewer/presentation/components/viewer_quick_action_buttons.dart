import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 観客席画面用 クイックアクションボタン群（結果一覧PDF/CSV、プログラム閲覧）
class ViewerQuickActionButtons extends StatelessWidget {
  final String tournamentId;
  final bool enableLiquidGlass;

  const ViewerQuickActionButtons({
    super.key,
    required this.tournamentId,
    required this.enableLiquidGlass,
  });

  Widget _buildHugeMenuButton(
    BuildContext context,
    bool enableLiquidGlass,
    IconData icon,
    String title,
    MaterialColor color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassButton(
      onPressed: onTap,
      color: color,
      icon: icon,
      label: title,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: enableLiquidGlass
            ? (isDark ? color.shade500 : color.shade300)
            : context.appColors.textColor.withValues(alpha: 0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          _buildHugeMenuButton(
            context,
            enableLiquidGlass,
            Icons.print,
            '試合結果一覧 (PDF/CSV)',
            AppKendoColors.blueGrey,
            () => context.push('/official-record/$tournamentId'),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                '/tournament/$tournamentId/programs?role=viewer',
              ),
              icon: Icon(
                Icons.picture_as_pdf,
                size: 20,
                color: isDark
                    ? context.appColors.errorColor
                    : context.appColors.errorColor,
              ),
              label: Text(
                '大会プログラムを見る（閲覧専用）',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xDE000000),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : context.appColors.separatorColor,
                ),
                backgroundColor: context.appColors.cardBackground,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
