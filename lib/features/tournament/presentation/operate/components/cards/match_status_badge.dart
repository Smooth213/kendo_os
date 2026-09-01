import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 試合カード右上に「試合中(LIVE) / 待機中 / 終了 / 全試合終了」を鮮明に表示するステータスバッジ
class MatchStatusBadge extends StatelessWidget {
  final bool isPlaying;
  final bool isFinished;
  final bool isDark;
  final String? customFinishedText;

  const MatchStatusBadge({
    super.key,
    required this.isPlaying,
    required this.isFinished,
    required this.isDark,
    this.customFinishedText,
  });

  @override
  Widget build(BuildContext context) {
    if (isPlaying) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppKendoColors.hansokuRed.withValues(alpha: 0.12),
          borderRadius: AppRadius.capsule,
          border: Border.all(
            color: AppKendoColors.hansokuRed.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.fiber_manual_record,
              size: 7,
              color: AppKendoColors.hansokuRed,
            ),
            SizedBox(width: AppSpacing.xxs),
            Text(
              '試合中 (LIVE)',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
                color: AppKendoColors.hansokuRed,
              ),
            ),
          ],
        ),
      );
    }

    if (isFinished) {
      final displayText = customFinishedText ?? '終了';
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
          borderRadius: AppRadius.capsule,
        ),
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: AppFontSize.caption,
            fontWeight: AppFontWeight.bold,
            color: context.appColors.subTextColor,
          ),
        ),
      );
    }

    // ⏳ 待機中
    final waitingAccent = context.appColors.primaryAccent;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: waitingAccent.withValues(alpha: 0.1),
        borderRadius: AppRadius.capsule,
        border: Border.all(
          color: waitingAccent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        '⏳ 待機中',
        style: TextStyle(
          fontSize: AppFontSize.caption,
          fontWeight: AppFontWeight.bold,
          color: waitingAccent,
        ),
      ),
    );
  }
}
