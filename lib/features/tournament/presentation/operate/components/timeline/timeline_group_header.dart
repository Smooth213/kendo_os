import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_dialog_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_summary_input_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// タイムライングループカードの1段目〜4段目（ステータス・対戦名・コート情報・アクション操作行）を担当するヘッダーWidget
class TimelineGroupHeader extends ConsumerWidget {
  final List<MatchModel> groupList;
  final String label;
  final bool allFinished;
  final bool hasInProgress;
  final bool isReadOnlyUI;
  final bool canManageTournamentUI;
  final bool isDark;
  final List<String> ownTeams;
  final Color titleColor;

  const TimelineGroupHeader({
    super.key,
    required this.groupList,
    required this.label,
    required this.allFinished,
    required this.hasInProgress,
    required this.isReadOnlyUI,
    required this.canManageTournamentUI,
    required this.isDark,
    required this.ownTeams,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstMatch = groupList.first;
    final rTeam = firstMatch.redName.contains(':')
        ? firstMatch.redName.split(':').first.trim()
        : firstMatch.redName;
    final wTeam = firstMatch.whiteName.contains(':')
        ? firstMatch.whiteName.split(':').first.trim()
        : firstMatch.whiteName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔽 【1段目】: 属性プレフィックス（左） ────── ステータスバッジ（右）
        Row(
          children: [
            Builder(
              builder: (context) {
                final scenePrefix = TeamProgressHelper.getScenePrefix(
                  firstMatch,
                );
                if (scenePrefix.isEmpty) {
                  return const SizedBox.shrink();
                }
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
                );
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
        const SizedBox(height: AppSpacing.xxs),

        // 🔽 【2段目】: 対戦カード名 / リーグタイトル（横幅全開・太字）
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label.contains('リーグ戦') ? label : '$rTeam vs $wTeam',
                  style: TextStyle(
                    fontSize: AppFontSize.subhead,
                    fontWeight: AppFontWeight.bold,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // 🔽 【3段目】: コート情報・進行・メモ（存在時のみ）
        if (firstMatch.note.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              firstMatch.note,
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: context.appColors.subTextColor,
                fontWeight: AppFontWeight.medium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],

        // 🔽 【4段目】: アクションボタン行（(i) ルール / ⇅ オーダー / [⚡ 簡易入力] / [スコア]）
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: Row(
            children: [
              if (!allFinished)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: InkWell(
                    onTap: () => showRuleInfoBottomSheet(context, firstMatch),
                    borderRadius: AppRadius.medium,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.info_outline,
                        color: context.appColors.subTextColor,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              if (!isReadOnlyUI &&
                  !allFinished &&
                  firstMatch.groupName != null &&
                  firstMatch.groupName!.isNotEmpty) ...[
                SizedBox(
                  height: 26,
                  width: 26,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.swap_vert,
                      size: 18,
                      color: context.appColors.infoColor,
                    ),
                    onPressed: () => TimelineDialogHelper.showOrderReorderSheet(
                      context,
                      ref,
                      groupList,
                    ),
                    tooltip: 'オーダー編集',
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              const Spacer(),
              if (!isReadOnlyUI &&
                  !allFinished &&
                  !label.contains('個人戦') &&
                  !label.contains('勝ち抜き戦') &&
                  !label.contains('リーグ戦') &&
                  !ownTeams.contains(
                    firstMatch.redName.split(':').first.trim(),
                  ) &&
                  !ownTeams.contains(
                    firstMatch.whiteName.split(':').first.trim(),
                  )) ...[
                SizedBox(
                  height: 26,
                  child: OutlinedButton.icon(
                    onPressed: () => TimelineSummaryInputDialog.show(
                      context,
                      ref,
                      groupList,
                    ),
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
                        color: titleColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.subValue,
                      ),
                      side: BorderSide(
                        color: titleColor.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.sub,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              if (!label.contains('リーグ戦')) ...[
                SizedBox(
                  height: 26,
                  child: OutlinedButton(
                    onPressed: () {
                      final target =
                          (firstMatch.groupName != null &&
                              firstMatch.groupName!.isNotEmpty)
                          ? firstMatch.groupName!
                          : firstMatch.id;
                      final encodedTarget = Uri.encodeComponent(target);
                      final tId = firstMatch.tournamentId ?? '';
                      context.push(
                        firstMatch.isKachinuki
                            ? '/kachinuki-scoreboard/$encodedTarget?tournamentId=$tId'
                            : '/team-scoreboard/$encodedTarget?tournamentId=$tId',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      side: BorderSide(
                        color: titleColor.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.sub,
                      ),
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
              ],
            ],
          ),
        ),
      ],
    );
  }
}
