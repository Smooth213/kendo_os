import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/court_progress_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 各コートの進行状況を表示するインタラクティブカード
class CourtStatusCard extends StatelessWidget {
  final CourtProgressStatus status;
  final bool isDark;

  const CourtStatusCard({
    super.key,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final liveMatch = status.inProgressMatch;
    final isLive = status.hasLiveMatch;
    final isMyDojo = status.hasMyDojoMatch;

    return Card(
      elevation: isLive ? 3 : 1,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(
          color: isMyDojo
              ? AppKendoColors.ipponGold
              : (isLive
                    ? AppKendoColors.hansokuRed
                    : context.appColors.separatorColor),
          width: isMyDojo ? 2.0 : (isLive ? 1.5 : 1.0),
        ),
      ),
      child: InkWell(
        onTap: () {
          final targetMatch =
              liveMatch ?? status.nextWaitingMatch ?? status.lastFinishedMatch;
          if (targetMatch != null) {
            context.push('/match/${targetMatch.id}');
          }
        },
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1段目: カテゴリ + LIVEバッジ + 自チームバッジ + 進行度
              _buildHeaderRow(context, isLive, isMyDojo),
              const SizedBox(height: AppSpacing.xs),

              // 2段目: 【錬成】団体戦：〇〇剣友会 vs ◯◯道場（対戦カード名）
              if (status.matchupTitle.isNotEmpty) ...[
                Text(
                  status.matchupTitle,
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
              ],

              // 3段目: 試合詳細メモ（未入力の場合は2段のみ）
              if (status.detailNote.isNotEmpty) ...[
                Text(
                  status.detailNote,
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.medium,
                    color: context.appColors.subTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
              ] else ...[
                const SizedBox(height: AppSpacing.xxs),
              ],

              // メイン進行中試合エリア
              if (liveMatch != null)
                _buildLiveMatchSection(context, liveMatch)
              else
                _buildNoLiveMatchSection(context),

              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xs),

              // フッター: 直前終了試合 & 次の試合予告
              _buildFooterInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, bool isLive, bool isMyDojo) {
    final displayCategory = status.categoryName.isNotEmpty
        ? status.categoryName
        : status.courtName;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFFE5E7EB),
                borderRadius: AppRadius.small,
              ),
              child: Text(
                displayCategory,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.textColor,
                ),
              ),
            ),
            if (isLive) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppKendoColors.hansokuRed,
                  borderRadius: AppRadius.compact,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 10,
                      color: AppKendoColors.pureWhite,
                    ),
                    SizedBox(width: AppSpacing.xxs),
                    Text(
                      'LIVE 試合中',
                      style: TextStyle(
                        fontSize: AppFontSize.micro,
                        fontWeight: AppFontWeight.bold,
                        color: AppKendoColors.pureWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isMyDojo) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppKendoColors.ipponGold,
                  borderRadius: AppRadius.compact,
                ),
                child: const Text(
                  '⭐ 自チーム',
                  style: TextStyle(
                    fontSize: AppFontSize.micro,
                    fontWeight: AppFontWeight.bold,
                    color: AppKendoColors.pureWhite,
                  ),
                ),
              ),
            ],
          ],
        ),
        // 進行度
        Text(
          '${status.completedCount}/${status.totalCount} 試合 (${status.progressPercent}%)',
          style: TextStyle(
            fontSize: AppFontSize.caption,
            color: context.appColors.subTextColor,
            fontWeight: AppFontWeight.medium,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMatchSection(BuildContext context, MatchModel match) {
    final rName = match.redName.isNotEmpty ? match.redName : '赤';
    final wName = match.whiteName.isNotEmpty ? match.whiteName : '白';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF9FAFB),
        borderRadius: AppRadius.medium,
        border: Border.all(color: context.appColors.separatorColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.matchType,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.primaryAccent,
                ),
              ),
              const Row(
                children: [
                  Icon(
                    Icons.play_circle_fill_rounded,
                    size: 14,
                    color: AppKendoColors.hansokuRed,
                  ),
                  SizedBox(width: AppSpacing.xxs),
                  Text(
                    '進行中',
                    style: TextStyle(
                      fontSize: AppFontSize.micro,
                      fontWeight: AppFontWeight.bold,
                      color: AppKendoColors.hansokuRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              // 赤側
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        rName,
                        style: TextStyle(
                          fontSize: AppFontSize.bodySmall,
                          fontWeight: AppFontWeight.bold,
                          color: AppKendoColors.hansokuRed,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              // スコア
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFE5E7EB),
                    borderRadius: AppRadius.small,
                  ),
                  child: Text(
                    '${match.redScore} - ${match.whiteScore}',
                    style: const TextStyle(
                      fontSize: AppFontSize.bodyMedium,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
              ),
              // 白側
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        wName,
                        style: TextStyle(
                          fontSize: AppFontSize.bodySmall,
                          fontWeight: AppFontWeight.bold,
                          color: isDark
                              ? AppKendoColors.pureWhite
                              : const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoLiveMatchSection(BuildContext context) {
    if (status.nextWaitingMatch != null) {
      final next = status.nextWaitingMatch!;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 16,
              color: context.appColors.subTextColor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '次の試合待機中: ',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: context.appColors.subTextColor,
              ),
            ),
            Expanded(
              child: Text(
                '${next.matchType} (${next.redName} vs ${next.whiteName})',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.semiBold,
                  color: context.appColors.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppKendoColors.green,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '全試合完了',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: AppKendoColors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterInfo(BuildContext context) {
    final last = status.lastFinishedMatch;
    if (last == null) {
      return const SizedBox.shrink();
    }

    final rName = last.redName.isNotEmpty ? last.redName : '赤';
    final wName = last.whiteName.isNotEmpty ? last.whiteName : '白';

    return Row(
      children: [
        Icon(
          Icons.history_rounded,
          size: 14,
          color: context.appColors.subTextColor,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '直前終了: ',
          style: TextStyle(
            fontSize: AppFontSize.micro,
            color: context.appColors.subTextColor,
          ),
        ),
        Expanded(
          child: Text(
            '${last.matchType} ($rName ${last.redScore}-${last.whiteScore} $wName)',
            style: TextStyle(
              fontSize: AppFontSize.micro,
              color: context.appColors.subTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
