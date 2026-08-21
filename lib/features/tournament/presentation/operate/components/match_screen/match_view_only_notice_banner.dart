import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合操作画面用 他端末入力中警告＆入力権限切り替えバナー
class MatchViewOnlyNoticeBanner extends StatelessWidget {
  final bool isSomeoneElseOperating;
  final bool isApproved;
  final bool isReadOnly;
  final VoidCallback onClaimScorer;

  const MatchViewOnlyNoticeBanner({
    super.key,
    required this.isSomeoneElseOperating,
    required this.isApproved,
    required this.isReadOnly,
    required this.onClaimScorer,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSomeoneElseOperating || isApproved || isReadOnly) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: AppKendoColors.hansokuRed.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppKendoColors.pureWhite,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              '他の記録員が入力中です',
              style: TextStyle(
                color: AppKendoColors.pureWhite,
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.bodySmall,
              ),
            ),
          ),
          TextButton(
            onPressed: onClaimScorer,
            style: TextButton.styleFrom(
              backgroundColor: AppKendoColors.pureWhite.withValues(alpha: 0.2),
              foregroundColor: AppKendoColors.pureWhite,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 0,
              ),
              minimumSize: const Size(0, 30),
            ),
            child: const Text(
              '自分に切り替える',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
