import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 試合作成・フォーマット設定画面におけるセクション枠カード（純粋UIコンポーネント）
class MatchFormatOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const MatchFormatOptionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppKendoColors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        color: color,
                        fontSize: AppFontSize.bodyMedium,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const Divider(),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// ルール確認用の読み取り専用行パーツ（純粋UIコンポーネント）
class SetupReadOnlyRuleRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? accentColor;

  const SetupReadOnlyRuleRow({
    super.key,
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveAccent = accentColor ?? context.appColors.primaryAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: AppFontWeight.semiBold,
                fontSize: AppFontSize.bodySmall,
                color: context.appColors.subTextColor,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? context.appColors.textColor.withValues(alpha: 0.08)
                      : effectiveAccent.withValues(alpha: 0.08),
                  borderRadius: AppRadius.small,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.12)
                        : effectiveAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: AppFontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : context.appColors.textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
