import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'team_status_card_sections.dart';

/// 🥋 iOS風の洗練されたチーム試合状況インタラクティブカード
class TeamStatusCard extends StatelessWidget {
  final TeamProgressStatus status;
  final bool isDark;

  const TeamStatusCard({super.key, required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final liveMatch = status.inProgressMatch;
    final isLive = status.hasLiveMatch;
    final isFinished =
        status.isAllFinished ||
        (liveMatch == null &&
            status.nextWaitingMatch == null &&
            status.lastFinishedMatch != null);

    final targetMatch =
        liveMatch ??
        status.nextWaitingMatch ??
        status.lastFinishedMatch ??
        (status.matches.isNotEmpty ? status.matches.first : null);

    final scenePrefix = targetMatch != null
        ? TeamProgressHelper.getScenePrefix(targetMatch)
        : '';

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final cardBgColor = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFFFFFFF);

    final borderColor = isLive
        ? AppKendoColors.hansokuRed.withValues(alpha: 0.6)
        : themeColors.borderColor;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: AppRadius.large,
        border: Border.all(color: borderColor, width: isLive ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: themeColors.cardShadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppKendoColors.transparent,
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: () {
            final isDantai =
                targetMatch != null &&
                !targetMatch.isKachinuki &&
                (targetMatch.matchType.contains('団体') ||
                    (targetMatch.groupName != null &&
                        targetMatch.groupName!.isNotEmpty &&
                        !targetMatch.matchType.contains('個人')));

            // ④ 終了した団体戦の場合は団体戦スコアボードへ遷移
            if (isFinished &&
                isDantai &&
                status.targetGroupId != null &&
                status.targetGroupId!.isNotEmpty) {
              final tourneyQuery =
                  status.tournamentId != null && status.tournamentId!.isNotEmpty
                  ? '?tournamentId=${status.tournamentId}'
                  : '';
              context.push(
                '/team-scoreboard/${Uri.encodeComponent(status.targetGroupId!)}$tourneyQuery',
              );
              return;
            }

            // 個人戦・リーグ個人戦・勝ち抜き戦および進行中/待機中の試合画面へ遷移
            if (targetMatch != null) {
              context.push('/match/${targetMatch.id}');
            }
          },
          borderRadius: AppRadius.large,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Opacity(
              opacity: isFinished ? 0.45 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔽 【1段目】: チーム名 + カテゴリ名（左） ────── ステータスバッジ（右）
                  _buildHeaderRow(context, isLive, isFinished),
                  const SizedBox(height: AppSpacing.xs),

                  // 🔽 【2段目】: 【錬成】等の属性プレフィックスバッジ（存在時のみ）
                  if (scenePrefix.isNotEmpty) ...[
                    _buildScenePrefixBadge(context, scenePrefix),
                    const SizedBox(height: AppSpacing.xs),
                  ],

                  // 🔽 【3段目】: 対戦カード見出し（headline）
                  if (status.matchupTitle.isNotEmpty) ...[
                    _buildMatchupTitleSection(context),
                    const SizedBox(height: AppSpacing.xs),
                  ],

                  // 🔽 【4段目】: 第1試合場, 3試合目 (このあと休憩)
                  _buildCourtSection(context),
                  const SizedBox(height: AppSpacing.sm),

                  // 🔽 【5段目以降】: メインコンテンツ（試合中 / 次の出番 / 直前終了）
                  if (liveMatch != null)
                    TeamStatusCardSections.buildLiveMatchSection(
                      context,
                      liveMatch,
                      isDark,
                    )
                  else if (status.nextWaitingMatch != null)
                    TeamStatusCardSections.buildWaitingMatchSection(
                      context,
                      status.nextWaitingMatch!,
                      isDark,
                    )
                  else if (status.lastFinishedMatch != null)
                    TeamStatusCardSections.buildFinishedMatchSection(
                      context,
                      status.lastFinishedMatch!,
                      isDark,
                    )
                  else
                    _buildNoMatchSection(context),

                  const SizedBox(height: AppSpacing.md),
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: themeColors.separatorColor,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // 本日の通算戦績 ＆ iOSプログレスバー
                  TeamStatusCardSections.buildFooterStats(
                    context,
                    status,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, bool isLive, bool isFinished) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  status.teamName,
                  style: TextStyle(
                    fontSize: AppFontSize.headline,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.textColor,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (status.categoryName.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFE5E5EA),
                    borderRadius: AppRadius.capsule,
                  ),
                  child: Text(
                    status.categoryName,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.medium,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        MatchStatusBadge(
          isPlaying: isLive,
          isFinished: isFinished,
          isDark: isDark,
          customFinishedText: status.isAllFinished ? '🏁 全試合終了' : '終了',
        ),
      ],
    );
  }

  Widget _buildScenePrefixBadge(BuildContext context, String scenePrefix) {
    final isMoushiawase = scenePrefix.contains('申合せ');
    final badgeColor = isMoushiawase
        ? context.appColors.warningColor
        : context.appColors.primaryAccent;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.subValue,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.sub,
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        scenePrefix,
        style: TextStyle(
          fontSize: AppFontSize.nano,
          fontWeight: AppFontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildCourtSection(BuildContext context) {
    return Material(
      color: AppKendoColors.transparent,
      borderRadius: AppRadius.small,
      child: InkWell(
        onTap: () {
          final targetMatch =
              status.inProgressMatch ??
              status.nextWaitingMatch ??
              status.lastFinishedMatch ??
              (status.matches.isNotEmpty ? status.matches.first : null);

          if (targetMatch != null) {
            final relevantMatches =
                (targetMatch.groupName != null &&
                    targetMatch.groupName!.isNotEmpty)
                ? status.matches
                      .where((m) => m.groupName == targetMatch.groupName)
                      .toList()
                : [targetMatch];

            showAppBottomSheet(
              context: context,
              builder: (ctx) => MatchEditSheet(
                matches: relevantMatches.isNotEmpty
                    ? relevantMatches
                    : [targetMatch],
                tournamentId: status.tournamentId ?? targetMatch.tournamentId,
                themeColors:
                    Theme.of(context).extension<AppThemeColors>() ??
                    AppThemeColors.ofMode(isDark: isDark, mode: 'normal'),
                initialTabIndex: 1, // 🌟 「コート・メモ」タブを直接開く！
              ),
            );
          }
        },
        borderRadius: AppRadius.small,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppKendoColors.indigo,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                status.currentCourtName.isNotEmpty
                    ? status.currentCourtName
                    : 'コート未指定',
                style: const TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: AppKendoColors.indigo,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                Icons.edit_outlined,
                size: 12,
                color: AppKendoColors.indigo.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchupTitleSection(BuildContext context) {
    String cleanTitle = status.matchupTitle;
    for (final p in ['【錬成】', '【申合せ】', '【本戦】', '【部内戦】']) {
      cleanTitle = cleanTitle.replaceAll(p, '').trim();
    }
    return Text(
      cleanTitle,
      style: TextStyle(
        fontSize: AppFontSize.headline,
        fontWeight: AppFontWeight.bold,
        color: context.appColors.textColor,
        letterSpacing: -0.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildNoMatchSection(BuildContext context) {
    return Text(
      '待機中の試合はありません',
      style: TextStyle(
        fontSize: AppFontSize.caption,
        color: context.appColors.subTextColor,
      ),
    );
  }
}
