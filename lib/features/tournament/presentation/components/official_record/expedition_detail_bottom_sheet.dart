import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_card_result_list.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_strike_stat_row.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 遠征成績 詳細分析ボトムシート
class ExpeditionDetailBottomSheet {
  static void show({
    required BuildContext context,
    required bool isDark,
    required String teamName,
    required int teamMen,
    required int teamKote,
    required int teamDou,
    required int teamTsuki,
    required int teamHansoku,
    required int teamOther,
    required int totalScored,
    required int totalConceded,
    required List<ExpeditionCardResult> cardResults,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insights,
                          color: AppKendoColors.indigo,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '成績 詳細分析 ($teamName)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      '🎯 有効打突・取得技内訳',
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF9FAFB),
                        borderRadius: AppRadius.large,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                              : const Color(0xFF000000).withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          ExpeditionStrikeStatRow(
                            men: teamMen,
                            kote: teamKote,
                            dou: teamDou,
                            tsuki: teamTsuki,
                            hansoku: teamHansoku,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              Text(
                                '総取得本数: $totalScored本',
                                style: const TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.caption,
                                  color: AppKendoColors.teal,
                                ),
                              ),
                              Text(
                                '総失本数: $totalConceded本',
                                style: const TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.caption,
                                  color: AppKendoColors.hansokuRed,
                                ),
                              ),
                              Text(
                                '得失差: ${totalScored - totalConceded >= 0 ? "+${totalScored - totalConceded}" : "${totalScored - totalConceded}"}',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.caption,
                                  color: (totalScored - totalConceded) >= 0
                                      ? AppKendoColors.teal
                                      : AppKendoColors.hansokuRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      '⚖️ 団体戦 対戦カード履歴 (全剣連基準)',
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ExpeditionCardResultList(
                      cardResults: cardResults,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showPlayerDetail({
    required BuildContext context,
    required bool isDark,
    required String playerName,
    required DetailedPlayerStats stats,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        final totalMatches = stats.win + stats.loss + stats.draw;
        final winRate = totalMatches > 0
            ? (stats.win / totalMatches * 100).toStringAsFixed(1)
            : '0.0';

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: AppKendoColors.indigo,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '$playerName 選手の個人カルテ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatPill(
                    '総試合数',
                    '$totalMatches 試合',
                    AppKendoColors.grey,
                  ),
                  _buildStatPill(
                    '勝敗',
                    '${stats.win}勝 ${stats.loss}敗 ${stats.draw > 0 ? "${stats.draw}分" : ""}',
                    AppKendoColors.indigo,
                  ),
                  _buildStatPill('勝率', '$winRate %', AppKendoColors.teal),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '🎯 取得技の内訳',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF9FAFB),
                  borderRadius: AppRadius.large,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                        : const Color(0xFF000000).withValues(alpha: 0.05),
                  ),
                ),
                child: ExpeditionStrikeStatRow(
                  men: stats.men,
                  kote: stats.kote,
                  dou: stats.dou,
                  tsuki: stats.tsuki,
                  hansoku: stats.hansoku,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildStatPill(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: AppKendoColors.grey,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: AppFontSize.bodyMedium,
            fontWeight: AppFontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
