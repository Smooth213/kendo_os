import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'expedition_stats_models.dart';

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
        final totalStrikes =
            teamMen + teamKote + teamDou + teamTsuki + teamHansoku + teamOther;
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
                          Row(
                            children: [
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '面 (メ)',
                                  teamMen,
                                  totalStrikes,
                                  AppKendoColors.teal,
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '小手 (コ)',
                                  teamKote,
                                  totalStrikes,
                                  AppKendoColors.indigo,
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '胴 (ド)',
                                  teamDou,
                                  totalStrikes,
                                  const Color(0xFFD97706),
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '突き (ツ)',
                                  teamTsuki,
                                  totalStrikes,
                                  const Color(0xFF8B5CF6),
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '反則 (反)',
                                  teamHansoku,
                                  totalStrikes,
                                  AppKendoColors.hansokuRed,
                                ),
                              ),
                            ],
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
                    if (cardResults.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(
                          child: Text(
                            '団体戦の対戦履歴はありません',
                            style: TextStyle(color: AppKendoColors.grey),
                          ),
                        ),
                      )
                    else
                      ...cardResults.map((res) {
                        final Color badgeBg = res.isWin
                            ? AppKendoColors.teal.withValues(alpha: 0.15)
                            : (res.isDraw
                                  ? AppKendoColors.grey.withValues(alpha: 0.15)
                                  : AppKendoColors.hansokuRed.withValues(
                                      alpha: 0.15,
                                    ));
                        final Color badgeText = res.isWin
                            ? AppKendoColors.teal
                            : (res.isDraw
                                  ? AppKendoColors.grey
                                  : AppKendoColors.hansokuRed);

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFFFFFFF),
                            borderRadius: AppRadius.medium,
                            border: Border.all(
                              color: isDark
                                  ? const Color(
                                      0xFFFFFFFF,
                                    ).withValues(alpha: 0.1)
                                  : const Color(
                                      0xFF000000,
                                    ).withValues(alpha: 0.08),
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
                      }),
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
        final totalStrikes =
            stats.men +
            stats.kote +
            stats.dou +
            stats.tsuki +
            stats.hansoku +
            stats.other;

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
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '面 (メ)',
                        stats.men,
                        totalStrikes,
                        AppKendoColors.teal,
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '小手 (コ)',
                        stats.kote,
                        totalStrikes,
                        AppKendoColors.indigo,
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '胴 (ド)',
                        stats.dou,
                        totalStrikes,
                        const Color(0xFFD97706),
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '突き (ツ)',
                        stats.tsuki,
                        totalStrikes,
                        const Color(0xFF8B5CF6),
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '反則 (反)',
                        stats.hansoku,
                        totalStrikes,
                        AppKendoColors.hansokuRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildStrikeStatBadge(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.caption,
            fontWeight: AppFontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count本',
          style: const TextStyle(
            fontSize: AppFontSize.bodyMedium,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        Text(
          '$pct%',
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: AppKendoColors.grey,
          ),
        ),
      ],
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
