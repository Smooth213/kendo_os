import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合カード右上に配置されるボタングループ（簡易入力 / ルール詳細 / スコア）
class MatchCardActionButtons extends StatelessWidget {
  final bool showSummaryButton;
  final bool showInfoButton;
  final bool showScoreButton;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback? onSummaryPressed;
  final VoidCallback? onInfoPressed;
  final VoidCallback? onScorePressed;

  const MatchCardActionButtons({
    super.key,
    required this.showSummaryButton,
    required this.showInfoButton,
    required this.showScoreButton,
    required this.textColor,
    required this.subTextColor,
    this.onSummaryPressed,
    this.onInfoPressed,
    this.onScorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ⚡️ 簡易入力ボタン
        if (showSummaryButton)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.subValue),
            child: SizedBox(
              height: 26,
              child: OutlinedButton.icon(
                onPressed: onSummaryPressed,
                icon: const Icon(
                  Icons.flash_on,
                  size: 11,
                  color: Color(0xFFD97706),
                ),
                label: Text(
                  '簡易',
                  style: TextStyle(
                    fontSize: AppFontSize.nano,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.subValue,
                  ),
                  side: BorderSide(color: textColor.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.sub),
                ),
              ),
            ),
          ),
        // ℹ️ 詳細ルールアイコン
        if (showInfoButton)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.subValue),
            child: InkWell(
              onTap: onInfoPressed,
              borderRadius: AppRadius.medium,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(Icons.info_outline, color: subTextColor, size: 16),
              ),
            ),
          ),
        // 📊 スコアボタン
        if (showScoreButton)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: SizedBox(
              height: 26,
              child: OutlinedButton(
                onPressed: onScorePressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  side: BorderSide(color: textColor.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.sub),
                ),
                child: Text(
                  'スコア',
                  style: TextStyle(
                    fontSize: AppFontSize.badge,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
