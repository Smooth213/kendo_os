import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 遠征成績の対戦カード履歴リスト表示パーツ
class ExpeditionCardResultList extends StatelessWidget {
  final List<ExpeditionCardResult> cardResults;
  final bool isDark;

  const ExpeditionCardResultList({
    super.key,
    required this.cardResults,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (cardResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Text(
            '団体戦の対戦履歴はありません',
            style: TextStyle(color: AppKendoColors.grey),
          ),
        ),
      );
    }

    return Column(
      children: cardResults.map((res) {
        final Color badgeBg = res.isWin
            ? AppKendoColors.teal.withValues(alpha: 0.15)
            : (res.isDraw
                  ? AppKendoColors.grey.withValues(alpha: 0.15)
                  : AppKendoColors.hansokuRed.withValues(alpha: 0.15));
        final Color badgeText = res.isWin
            ? AppKendoColors.teal
            : (res.isDraw ? AppKendoColors.grey : AppKendoColors.hansokuRed);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: isDark
                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                  : const Color(0xFF000000).withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.caption,
                        color: AppKendoColors.grey,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'vs ${res.opponentTeamName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${res.myWins}(${res.myPoints}) - ${res.oppWins}(${res.oppPoints})',
                    style: TextStyle(
                      fontSize: AppFontSize.bodyMedium,
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: AppRadius.round,
                    ),
                    child: Text(
                      res.resultType,
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                        color: badgeText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
