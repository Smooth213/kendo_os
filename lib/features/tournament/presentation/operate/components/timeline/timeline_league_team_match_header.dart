import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';

import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// タイムラインのリーグ戦チーム対抗戦ヘッダー（コントロールボタン + 勝数・本数掲示ライン）
class TimelineLeagueTeamMatchHeader extends ConsumerWidget {
  final List<MatchModel> bouts;
  final bool isReadOnlyUI;
  final bool boutsAllFinished;
  final bool boutsInProgress;
  final String t1;
  final String t2;
  final List<String> ownTeams;
  final Color mTitleColor;
  final bool isDark;
  final void Function(
    BuildContext context,
    WidgetRef ref,
    List<MatchModel> bouts,
  )
  onShowSummaryInputDialog;

  const TimelineLeagueTeamMatchHeader({
    super.key,
    required this.bouts,
    required this.isReadOnlyUI,
    required this.boutsAllFinished,
    required this.boutsInProgress,
    required this.t1,
    required this.t2,
    required this.ownTeams,
    required this.mTitleColor,
    required this.isDark,
    required this.onShowSummaryInputDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int redWins = 0;
    int redPts = 0;
    int whiteWins = 0;
    int whitePts = 0;
    for (var m in bouts) {
      final r = (m.redScore as num).toInt();
      final w = (m.whiteScore as num).toInt();
      redPts += r;
      whitePts += w;
      if (m.status == 'finished' || m.status == 'approved') {
        if (r > w) {
          redWins++;
        } else if (w > r) {
          whiteWins++;
        }
      }
    }

    final ruleTeamName = bouts.firstOrNull?.rule?.teamName;
    final isRedOwn =
        ownTeams.contains(t1) ||
        (ruleTeamName?.isNotEmpty == true && t1 == ruleTeamName);
    final isWhiteOwn =
        ownTeams.contains(t2) ||
        (ruleTeamName?.isNotEmpty == true && t2 == ruleTeamName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔽 【中枠1行目】: 属性プレフィックス・ポジション数・スコア/簡易入力ボタン・ステータスバッジ
        Row(
          children: [
            Builder(
              builder: (context) {
                final firstBout = bouts.firstOrNull;
                final scenePrefix = firstBout != null
                    ? TeamProgressHelper.getScenePrefix(firstBout)
                    : '';
                if (scenePrefix.isEmpty) {
                  return const SizedBox.shrink();
                }
                final isMoushiawase = scenePrefix.contains('申合せ');
                final badgeColor = isMoushiawase
                    ? context.appColors.warningColor
                    : context.appColors.primaryAccent;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.subValue,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.sub,
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      scenePrefix,
                      style: TextStyle(
                        fontSize: AppFontSize.nano,
                        fontWeight: AppFontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                );
              },
            ),
            Text(
              '${bouts.length}ポジション',
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                color: AppKendoColors.grey,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            const Spacer(),
            // 簡易入力
            if (!isReadOnlyUI &&
                !boutsAllFinished &&
                !(ownTeams.contains(t1) ||
                    bouts.first.redName.contains('自チーム')) &&
                !(ownTeams.contains(t2) ||
                    bouts.first.whiteName.contains('自チーム')))
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.subValue),
                child: SizedBox(
                  height: 26,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        onShowSummaryInputDialog(context, ref, bouts),
                    icon: Icon(
                      Icons.flash_on,
                      size: 12,
                      color: context.appColors.warningColor,
                    ),
                    label: Text(
                      '簡易入力',
                      style: TextStyle(
                        fontSize: AppFontSize.nano,
                        fontWeight: AppFontWeight.bold,
                        color: mTitleColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.subValue,
                      ),
                      side: BorderSide(
                        color: mTitleColor.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.sub,
                      ),
                    ),
                  ),
                ),
              ),
            // スコアボタン
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.subValue),
              child: SizedBox(
                height: 26,
                child: OutlinedButton(
                  onPressed: () {
                    final target =
                        (bouts.first.groupName != null &&
                            bouts.first.groupName!.isNotEmpty)
                        ? bouts.first.groupName!
                        : bouts.first.id;
                    final encodedTarget = Uri.encodeComponent(target);
                    final tId = bouts.first.tournamentId ?? '';
                    context.push(
                      '/team-scoreboard/$encodedTarget?tournamentId=$tId',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    side: BorderSide(color: mTitleColor.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.sub),
                  ),
                  child: Text(
                    'スコア',
                    style: TextStyle(
                      fontSize: AppFontSize.badge,
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.primaryAccent,
                    ),
                  ),
                ),
              ),
            ),
            // 状態バナー（統一 MatchStatusBadge）
            MatchStatusBadge(
              isPlaying: boutsInProgress,
              isFinished: boutsAllFinished,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // 🔽 【中枠2行目】: リーグ内チーム対抗勝数(本数)掲示ライン
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                t1,
                style: TextStyle(
                  fontSize: AppFontSize.body,
                  fontWeight: isRedOwn
                      ? AppFontWeight.black
                      : AppFontWeight.bold,
                  color: isRedOwn ? const Color(0xFFD97706) : mTitleColor,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$redWins',
                    style: const TextStyle(
                      fontSize: AppFontSize.bodyMedium,
                      fontWeight: AppFontWeight.bold,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  Text(
                    '($redPts)',
                    style: TextStyle(
                      fontSize: AppFontSize.badge,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.subValue,
                    ),
                    child: Text(
                      'ー',
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        color: context.appColors.subTextColor,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '$whiteWins',
                    style: TextStyle(
                      fontSize: AppFontSize.bodyMedium,
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                  ),
                  Text(
                    '($whitePts)',
                    style: TextStyle(
                      fontSize: AppFontSize.badge,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                t2,
                style: TextStyle(
                  fontSize: AppFontSize.body,
                  fontWeight: isWhiteOwn
                      ? AppFontWeight.black
                      : AppFontWeight.bold,
                  color: isWhiteOwn ? const Color(0xFFD97706) : mTitleColor,
                ),
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
