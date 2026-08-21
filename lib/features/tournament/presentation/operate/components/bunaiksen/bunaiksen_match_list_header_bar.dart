import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 部内戦画面の「本日の試合一覧」ヘッダーおよびクイック操作ボタンバー
class BunaiksenMatchListHeaderBar extends StatelessWidget {
  final AppThemeColors themeColors;
  final bool hasMatches;
  final VoidCallback onQuickMatch;
  final VoidCallback onBulkRuleEdit;

  const BunaiksenMatchListHeaderBar({
    super.key,
    required this.themeColors,
    required this.hasMatches,
    required this.onQuickMatch,
    required this.onBulkRuleEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 6.0,
      ),
      color: themeColors.softAccent,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '本日の試合一覧',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              color: themeColors.primaryAccent,
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: onQuickMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColors.primaryAccent,
                  foregroundColor: AppKendoColors.pureWhite,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                ),
                child: const Text(
                  'クイック対戦',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.caption,
                  ),
                ),
              ),
              if (hasMatches) ...[
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: onBulkRuleEdit,
                  icon: Icon(
                    Icons.gavel,
                    size: 14,
                    color: themeColors.primaryAccent,
                  ),
                  label: Text(
                    'ルール一括変更',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.caption,
                      color: themeColors.primaryAccent,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeColors.primaryAccent,
                    side: BorderSide(
                      color: themeColors.primaryAccent.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
