import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// タイムライン・観客席ビュアー共通の個人戦アコーディオンヘッダー（1〜4段構造）
class TimelineIndividualPlayerHeader extends ConsumerWidget {
  final String playerName;
  final List<MatchModel> playerMatches;
  final bool isDark;
  final bool isReadOnlyUI;
  final Color titleColor;

  const TimelineIndividualPlayerHeader({
    super.key,
    required this.playerName,
    required this.playerMatches,
    required this.isDark,
    required this.isReadOnlyUI,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (playerMatches.isEmpty) return const SizedBox.shrink();

    final firstMatch = playerMatches.first;

    final hasInProgress = playerMatches.any((m) => m.status == 'in_progress');
    final allFinished = playerMatches.every(
      (m) => m.status == 'finished' || m.status == 'approved',
    );

    final liveMatch = playerMatches
        .where((m) => m.status == 'in_progress')
        .firstOrNull;
    final nextWaitingMatch = playerMatches
        .where((m) => m.status == 'pending')
        .firstOrNull;
    final lastFinishedMatch = playerMatches
        .where((m) => m.status == 'finished' || m.status == 'approved')
        .lastOrNull;

    final targetMatch =
        liveMatch ?? nextWaitingMatch ?? lastFinishedMatch ?? firstMatch;
    final courtDisplay = TeamProgressHelper.extractCourtAndRoundDisplay(
      targetMatch,
    );

    final stats = TeamProgressHelper.calculatePlayerStats(
      playerMatches,
      playerName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔽 【1段目】: 属性バッジ（左） ────── ステータスバッジ（右）
        Row(
          children: [
            Builder(
              builder: (context) {
                final scene = KendoSceneHelper.detectScene(firstMatch);
                if (scene == KendoMatchScene.honsen) {
                  return const SizedBox.shrink();
                }
                return KendoSceneBadge(scene: scene);
              },
            ),
            const Spacer(),
            MatchStatusBadge(
              isPlaying: hasInProgress,
              isFinished: allFinished,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // 🔽 【2段目】: マーク（CircleAvatar） ＋ 選手名（大きく太字） ＋ 試合数/戦績
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: allFinished
                  ? context.appColors.separatorColor
                  : (hasInProgress
                        ? AppKendoColors.hansokuRed
                        : context.appColors.warningColor),
              child: Text(
                playerName.isNotEmpty ? playerName[0] : '?',
                style: TextStyle(
                  color: allFinished
                      ? (isDark
                            ? const Color(0xFF9E9E9E)
                            : const Color(0xFF757575))
                      : AppKendoColors.pureWhite,
                  fontSize: AppFontSize.nano,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: playerName,
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    TextSpan(
                      text:
                          '  （全${playerMatches.length}試合${allFinished ? ' • ${stats.wins}勝${stats.losses}敗' : ''}）',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.medium,
                        color: context.appColors.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // 🔽 【3段目】: コート情報・進行メモ
        if (courtDisplay.isNotEmpty && courtDisplay != 'コート未指定') ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              courtDisplay,
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: context.appColors.subTextColor,
                fontWeight: AppFontWeight.medium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ] else if (targetMatch.note.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              targetMatch.note,
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: context.appColors.subTextColor,
                fontWeight: AppFontWeight.medium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],

        // 🔽 【4段目】: 状態に応じた自動切り替え（進行中 / 次の出番 / 全試合終了）
        _buildStatusContentSection(
          context,
          liveMatch: liveMatch,
          nextWaitingMatch: nextWaitingMatch,
          allFinished: allFinished,
          stats: stats,
        ),
      ],
    );
  }

  Widget _buildStatusContentSection(
    BuildContext context, {
    required MatchModel? liveMatch,
    required MatchModel? nextWaitingMatch,
    required bool allFinished,
    required ({int wins, int losses, int draws, int totalPoints}) stats,
  }) {
    if (liveMatch != null) {
      final opponent = TeamProgressHelper.getOpponentDisplay(
        liveMatch,
        playerName,
      );
      final isRed = liveMatch.redName.contains(playerName.trim());
      final myScore = isRed ? liveMatch.redScore : liveMatch.whiteScore;
      final oppScore = isRed ? liveMatch.whiteScore : liveMatch.redScore;

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppKendoColors.hansokuRed.withValues(alpha: 0.08),
          borderRadius: AppRadius.sub,
          border: Border.all(
            color: AppKendoColors.hansokuRed.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '🔴 試合中: vs $opponent',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: AppKendoColors.hansokuRed,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '($myScore - $oppScore)',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.black,
                color: titleColor,
              ),
            ),
          ],
        ),
      );
    }

    if (nextWaitingMatch != null) {
      final opponent = TeamProgressHelper.getOpponentDisplay(
        nextWaitingMatch,
        playerName,
      );
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.appColors.warningColor.withValues(alpha: 0.08),
          borderRadius: AppRadius.sub,
          border: Border.all(
            color: context.appColors.warningColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '⏳ 次の出番: vs $opponent',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.warningColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (allFinished) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.appColors.separatorColor.withValues(alpha: 0.2),
          borderRadius: AppRadius.sub,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '🏁 全試合終了: 通算 ${stats.wins}勝 ${stats.losses}敗 ${stats.draws}分 (${stats.totalPoints}本)',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.subTextColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
