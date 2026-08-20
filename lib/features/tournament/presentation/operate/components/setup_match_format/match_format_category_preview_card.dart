import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 試合形式設定画面 選択カテゴリ確認プレビューカード
class MatchFormatCategoryPreviewCard extends StatelessWidget {
  final String category;
  final AppThemeColors themeColors;
  final Color textColor;

  const MatchFormatCategoryPreviewCard({
    super.key,
    required this.category,
    required this.themeColors,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: themeColors.softAccent,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: themeColors.primaryAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: themeColors.primaryAccent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '設定されるカテゴリ名',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: themeColors.primaryAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  category,
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.headline,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
