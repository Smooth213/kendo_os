import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_dialog_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_group_children_builder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_group_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_group_score_summary.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_ui_state_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// タイムライン内の試合グループ（団体戦・リーグ戦・勝ち抜き戦）アコーディオンカード
class TimelineMatchGroupCard extends ConsumerWidget {
  final String groupId;
  final List<MatchModel> groupList;
  final List<MatchCommentModel> groupComments;
  final String categoryName;
  final String teamName;
  final String label;
  final Widget? headerWidget;
  final bool isReadOnlyUI;
  final bool canManageTournamentUI;
  final bool isDark;
  final String tournamentId;
  final List<String> ownTeams;

  const TimelineMatchGroupCard({
    super.key,
    required this.groupId,
    required this.groupList,
    required this.groupComments,
    required this.categoryName,
    required this.teamName,
    required this.label,
    this.headerWidget,
    required this.isReadOnlyUI,
    required this.canManageTournamentUI,
    required this.isDark,
    required this.tournamentId,
    required this.ownTeams,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionProvider);
    final firstMatch = groupList.first;
    final rTeam = firstMatch.redName.contains(':')
        ? firstMatch.redName.split(':').first.trim()
        : firstMatch.redName;
    final wTeam = firstMatch.whiteName.contains(':')
        ? firstMatch.whiteName.split(':').first.trim()
        : firstMatch.whiteName;

    final hasInProgress = groupList.any((m) => m.status == 'in_progress');
    final allFinished = groupList.every(
      (m) => m.status == 'finished' || m.status == 'approved',
    );
    final Color titleColor = allFinished
        ? context.appColors.subTextColor
        : context.appColors.textColor;

    final expansionVersion = ref.watch(timelineExpansionVersionProvider);
    final isGroupExpanded =
        ref.watch(timelineGroupExpansionMapProvider)[groupId] ?? false;

    final Color cardBg = allFinished
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
        : (isDark ? context.appColors.cardBackground : const Color(0xFFFFFFFF));
    final Color collapsedCardBg = allFinished
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
        : (isDark ? context.appColors.cardBackground : const Color(0xFFFAFAFC));

    final globalRule = ref.watch(matchRuleProvider);
    final rule = firstMatch.rule ?? globalRule;

    return Container(
      key: ValueKey(groupId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ?headerWidget,
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Slidable(
              key: ValueKey('group_$groupId'),
              enabled: !isReadOnlyUI,
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  if (!isReadOnlyUI)
                    SlidableAction(
                      onPressed: (context) =>
                          TimelineDialogHelper.showEditGroupNoteDialog(
                            context,
                            ref,
                            groupList,
                          ),
                      backgroundColor: context.appColors.infoColor,
                      foregroundColor: AppKendoColors.pureWhite,
                      icon: Icons.edit_note,
                      label: 'メモ',
                    ),
                  if (canManageTournamentUI && !isReadOnlyUI)
                    SlidableAction(
                      onPressed: (context) async {
                        final confirm = await showAppDialog<bool>(
                          context: context,
                          builder: (ctx) => AppDialog(
                            title: 'グループ全削除の確認',
                            content: Text(
                              '「$label」に含まれる全ての試合（${groupList.length}件）を削除しますか？\nこの操作は取り消せません。',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('キャンセル'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.appColors.errorColor,
                                  foregroundColor: AppKendoColors.pureWhite,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('全削除する'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          for (var m in groupList) {
                            await ref
                                .read(matchCommandProvider)
                                .deleteMatch(m.id);
                          }
                        }
                      },
                      backgroundColor: context.appColors.errorColor,
                      foregroundColor: AppKendoColors.pureWhite,
                      icon: Icons.delete,
                      label: '削除',
                    ),
                ],
              ),
              child: Opacity(
                opacity: allFinished ? 0.65 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: hasInProgress
                          ? AppKendoColors.hansokuRed.withValues(alpha: 0.6)
                          : (isDark
                                ? const Color(0xFF2C2C2E)
                                : context.appColors.separatorColor),
                      width: hasInProgress ? 1.5 : 1.0,
                    ),
                    boxShadow: hasInProgress
                        ? [
                            BoxShadow(
                              color: AppKendoColors.hansokuRed.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.smooth,
                    child: ExpansionTileTheme(
                      data: ExpansionTileThemeData(
                        backgroundColor: cardBg,
                        collapsedBackgroundColor: collapsedCardBg,
                        iconColor: context.appColors.primaryAccent,
                        collapsedIconColor: context.appColors.subTextColor,
                        textColor: context.appColors.textColor,
                        collapsedTextColor: isDark
                            ? AppKendoColors.pureWhite.withValues(alpha: 0.7)
                            : AppKendoColors.pureBlack.withValues(alpha: 0.54),
                      ),
                      child: ExpansionTile(
                        key: expansionVersion == 0
                            ? ValueKey('group_$groupId')
                            : ValueKey('group_${groupId}_$expansionVersion'),
                        initiallyExpanded: isGroupExpanded,
                        onExpansionChanged: (expanded) {
                          ref
                              .read(timelineGroupExpansionMapProvider.notifier)
                              .setGroup(groupId, expanded);
                        },
                        shape: const Border(),
                        collapsedShape: const Border(),
                        childrenPadding: EdgeInsets.zero,
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔽 【1段目〜4段目】: ステータス・対戦名・コート情報・アクション操作行
                            TimelineGroupHeader(
                              groupList: groupList,
                              label: label,
                              allFinished: allFinished,
                              hasInProgress: hasInProgress,
                              isReadOnlyUI: isReadOnlyUI,
                              canManageTournamentUI: canManageTournamentUI,
                              isDark: isDark,
                              ownTeams: ownTeams,
                              titleColor: titleColor,
                            ),

                            // 🔽 【5段目】: チーム対戦スコアサマリー（リーグ戦以外）
                            if (!label.contains('リーグ戦')) ...[
                              const SizedBox(height: AppSpacing.sm),
                              TimelineGroupScoreSummary(
                                groupList: groupList,
                                rTeam: rTeam,
                                wTeam: wTeam,
                                ownTeams: ownTeams,
                                titleColor: titleColor,
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                        children: TimelineGroupChildrenBuilder.buildChildren(
                          context: context,
                          ref: ref,
                          groupList: groupList,
                          groupComments: groupComments,
                          label: label,
                          isReadOnlyUI: isReadOnlyUI,
                          isDark: isDark,
                          permissions: permissions,
                          rule: rule,
                          firstMatch: firstMatch,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
