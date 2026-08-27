import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 観客席画面用 クイックアクションボタン群（2列横並びスマートグリッド構成）
class ViewerQuickActionButtons extends StatelessWidget {
  final String tournamentId;
  final bool enableLiquidGlass;

  const ViewerQuickActionButtons({
    super.key,
    required this.tournamentId,
    required this.enableLiquidGlass,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactTile(
              context: context,
              enableLiquidGlass: enableLiquidGlass,
              icon: Icons.print,
              title: '試合結果一覧',
              color: AppKendoColors.blueGrey,
              onTap: () => context.push('/viewer-record/$tournamentId'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildCompactTile(
              context: context,
              enableLiquidGlass: enableLiquidGlass,
              icon: Icons.picture_as_pdf,
              title: '大会プログラム',
              color: isDark
                  ? context.appColors.rosePink
                  : context.appColors.errorColor,
              onTap: () => context.push(
                '/tournament/$tournamentId/programs?role=viewer',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTile({
    required BuildContext context,
    required bool enableLiquidGlass,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: AppKendoColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: enableLiquidGlass
                ? (isDark
                      ? color.withValues(alpha: 0.18)
                      : color.withValues(alpha: 0.12))
                : context.appColors.cardBackground,
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: color.withValues(alpha: enableLiquidGlass ? 0.35 : 0.25),
              width: 1.2,
            ),
            boxShadow: enableLiquidGlass
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.body,
                      color: isDark
                          ? const Color(0xFFFFFFFF)
                          : context.appColors.textColor,
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 11,
                color: isDark
                    ? const Color(0x80FFFFFF)
                    : context.appColors.textColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
