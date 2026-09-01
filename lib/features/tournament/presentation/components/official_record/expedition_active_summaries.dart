import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 遠征・大会公式記録のシーン別勝敗サマリー（本戦、錬成、申合せ、個人戦）表示ウィジェット
class ExpeditionActiveSummaries extends StatelessWidget {
  final ExpeditionSummaryData summaryData;

  const ExpeditionActiveSummaries({super.key, required this.summaryData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeItems = <Widget>[];

    final renseikaiTotal =
        summaryData.renseikaiWin +
        summaryData.renseikaiLoss +
        summaryData.renseikaiDraw;
    if (renseikaiTotal > 0) {
      activeItems.add(
        _buildSummaryItem(
          '錬成 (団体)',
          summaryData.renseikaiWin,
          summaryData.renseikaiLoss,
          summaryData.renseikaiDraw,
          KendoSceneHelper.getColor(KendoMatchScene.renseikai, isDark: isDark),
        ),
      );
    }

    final honsenTotal =
        summaryData.honsenWin + summaryData.honsenLoss + summaryData.honsenDraw;
    if (honsenTotal > 0) {
      activeItems.add(
        _buildSummaryItem(
          '本戦 (団体)',
          summaryData.honsenWin,
          summaryData.honsenLoss,
          summaryData.honsenDraw,
          KendoSceneHelper.getColor(KendoMatchScene.honsen, isDark: isDark),
        ),
      );
    }

    final moushiawaseTotal =
        summaryData.moushiawaseWin +
        summaryData.moushiawaseLoss +
        summaryData.moushiawaseDraw;
    if (moushiawaseTotal > 0) {
      activeItems.add(
        _buildSummaryItem(
          '申合せ',
          summaryData.moushiawaseWin,
          summaryData.moushiawaseLoss,
          summaryData.moushiawaseDraw,
          KendoSceneHelper.getColor(
            KendoMatchScene.moushiawase,
            isDark: isDark,
          ),
        ),
      );
    }

    final individualTotal =
        summaryData.individualTotalWins +
        summaryData.individualTotalLosses +
        summaryData.individualTotalDraws;
    if (individualTotal > 0) {
      activeItems.add(
        _buildSummaryItem(
          '個人戦',
          summaryData.individualTotalWins,
          summaryData.individualTotalLosses,
          summaryData.individualTotalDraws,
          const Color(0xFF8B5CF6),
        ),
      );
    }

    if (activeItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(
            '未実施',
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: AppFontWeight.semiBold,
              color: AppKendoColors.grey.withValues(alpha: 0.8),
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.spaceAround,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: activeItems,
    );
  }

  Widget _buildSummaryItem(
    String title,
    int win,
    int loss,
    int draw,
    Color color,
  ) {
    final total = win + loss + draw;
    final String scoreText = draw > 0 ? '$win勝 $loss敗 $draw分' : '$win勝 $loss敗';
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.bodySmall,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          total > 0 ? scoreText : '未実施',
          style: const TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.semiBold,
          ),
        ),
        if (total > 0)
          Text(
            '（計$total試合）',
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              color: AppKendoColors.grey,
            ),
          ),
      ],
    );
  }
}
