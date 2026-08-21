import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_dialog_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_inner_comment_widget.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_reorder_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_summary_input_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_tie_break_detector.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_tie_break_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';
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
              enabled: canManageTournamentUI,
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) =>
                        TimelineDialogHelper.showEditGroupNoteDialog(
                          context,
                          ref,
                          groupList,
                        ),
                    backgroundColor: AppKendoColors.blueAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    icon: Icons.edit,
                    label: '編集',
                  ),
                  SlidableAction(
                    onPressed: (context) async {
                      final confirm = await showAppDialog<bool>(
                        context: context,
                        builder: (ctx) => AppDialog(
                          backgroundColor: context.appColors.cardBackground,
                          titleWidget: Text(
                            '試合グループの削除',
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                            ),
                          ),
                          content: Text(
                            'このグループに含まれる全試合を\n削除しますか？\n(取り消せません)',
                            style: TextStyle(
                              color: context.appColors.textColor,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'キャンセル',
                                style: TextStyle(
                                  color: context.appColors.subTextColor,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                '削除する',
                                style: TextStyle(
                                  color: context.appColors.errorColor,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
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
                    backgroundColor: AppKendoColors.redAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    icon: Icons.delete,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(AppRadius.mediumValue),
                    ),
                    label: '削除',
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: context.appColors.separatorColor,
                    width: 1,
                  ),
                  boxShadow: hasInProgress
                      ? [
                          BoxShadow(
                            color: context.appColors.primaryAccent.withValues(
                              alpha: 0.1,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.smooth,
                  child: ExpansionTileTheme(
                    data: ExpansionTileThemeData(
                      backgroundColor: context.appColors.cardBackground,
                      collapsedBackgroundColor: isDark
                          ? context.appColors.cardBackground
                          : const Color(0xFFFAFAFC),
                      iconColor: context.appColors.primaryAccent,
                      collapsedIconColor: context.appColors.subTextColor,
                      textColor: context.appColors.textColor,
                      collapsedTextColor: isDark
                          ? AppKendoColors.pureWhite.withValues(alpha: 0.7)
                          : AppKendoColors.pureBlack.withValues(alpha: 0.54),
                    ),
                    child: ExpansionTile(
                      key: ValueKey('group_$groupId'),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      childrenPadding: EdgeInsets.zero,
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
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
                                    firstMatch.whiteName
                                        .split(':')
                                        .first
                                        .trim(),
                                  )) ...[
                                SizedBox(
                                  height: 26,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        TimelineSummaryInputDialog.show(
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
                                        color: titleColor.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.sub,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                              if (!allFinished)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.subValue,
                                  ),
                                  child: InkWell(
                                    onTap: () => showRuleInfoBottomSheet(
                                      context,
                                      firstMatch,
                                    ),
                                    borderRadius: AppRadius.medium,
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.xs,
                                      ),
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
                                    onPressed: () =>
                                        TimelineDialogHelper.showOrderReorderSheet(
                                          context,
                                          ref,
                                          groupList,
                                        ),
                                    tooltip: 'オーダー編集',
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
                                      final encodedTarget = Uri.encodeComponent(
                                        target,
                                      );
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
                                        color: titleColor.withValues(
                                          alpha: 0.2,
                                        ),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xxs,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label.contains('リーグ戦')
                                        ? label
                                        : '$rTeam vs $wTeam',
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
                          if (firstMatch.note.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xxs,
                              ),
                              child: Text(
                                firstMatch.note,
                                style: TextStyle(
                                  fontSize: AppFontSize.caption,
                                  color: context.appColors.subTextColor,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (!label.contains('リーグ戦')) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Builder(
                              builder: (context) {
                                int redWins = 0;
                                int redPts = 0;
                                int whiteWins = 0;
                                int whitePts = 0;

                                for (var m in groupList) {
                                  if (m.matchType == '代表戦') {
                                    continue;
                                  }
                                  final r = m.redScore;
                                  final w = m.whiteScore;
                                  redPts += (r as num).toInt();
                                  whitePts += (w as num).toInt();
                                  final mFinished =
                                      m.status == 'finished' ||
                                      m.status == 'approved';
                                  if (mFinished) {
                                    if (r > w) {
                                      redWins++;
                                    } else if (w > r) {
                                      whiteWins++;
                                    }
                                  }
                                }

                                final ruleTeamName =
                                    groupList.firstOrNull?.rule?.teamName;
                                final bool isOwnRed =
                                    (ruleTeamName != null &&
                                        rTeam == ruleTeamName) ||
                                    ownTeams.contains(rTeam);
                                final bool isOwnWhite =
                                    (ruleTeamName != null &&
                                        wTeam == ruleTeamName) ||
                                    ownTeams.contains(wTeam);

                                return Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          if (isOwnRed) ...[
                                            Container(
                                              margin: const EdgeInsets.only(
                                                right: AppSpacing.xs,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.xs,
                                                    vertical: AppSpacing.xxs,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF2C2C2E)
                                                    : context
                                                          .appColors
                                                          .separatorColor,
                                                borderRadius: AppRadius.tiny,
                                              ),
                                              child: Text(
                                                '自道場',
                                                style: TextStyle(
                                                  fontSize: AppFontSize.badge,
                                                  fontWeight:
                                                      AppFontWeight.bold,
                                                  color: context
                                                      .appColors
                                                      .primaryAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                          Expanded(
                                            child: Text(
                                              rTeam,
                                              style: TextStyle(
                                                fontSize: AppFontSize.body,
                                                fontWeight: isOwnRed
                                                    ? AppFontWeight.bold
                                                    : AppFontWeight.semiBold,

                                                color: titleColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF2C2C2E)
                                            : const Color(0xFFE5E5EA),
                                        borderRadius: AppRadius.sub,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$redWins',
                                            style: TextStyle(
                                              fontSize: AppFontSize.bodySmall,
                                              fontWeight: AppFontWeight.bold,
                                              color: redWins > whiteWins
                                                  ? AppKendoColors.hansokuRed
                                                  : titleColor,
                                            ),
                                          ),
                                          Text(
                                            '($redPts)',
                                            style: TextStyle(
                                              fontSize: AppFontSize.bodySmall,
                                              fontWeight: AppFontWeight.bold,
                                              color: redWins > whiteWins
                                                  ? AppKendoColors.hansokuRed
                                                  : titleColor,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.xs,
                                            ),
                                            child: Text(
                                              '-',
                                              style: TextStyle(
                                                fontSize: AppFontSize.badge,
                                                color: context
                                                    .appColors
                                                    .subTextColor,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$whiteWins',
                                            style: TextStyle(
                                              fontSize: AppFontSize.bodySmall,
                                              fontWeight: AppFontWeight.bold,
                                              color: whiteWins > redWins
                                                  ? context
                                                        .appColors
                                                        .primaryAccent
                                                  : titleColor,
                                            ),
                                          ),
                                          Text(
                                            '($whitePts)',
                                            style: TextStyle(
                                              fontSize: AppFontSize.bodySmall,
                                              fontWeight: AppFontWeight.bold,
                                              color: whiteWins > redWins
                                                  ? context
                                                        .appColors
                                                        .primaryAccent
                                                  : titleColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              wTeam,
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                fontSize: AppFontSize.body,
                                                fontWeight: isOwnWhite
                                                    ? AppFontWeight.bold
                                                    : AppFontWeight.semiBold,

                                                color: titleColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isOwnWhite) ...[
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: AppSpacing.xs,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.xs,
                                                    vertical: AppSpacing.xxs,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF2C2C2E)
                                                    : context
                                                          .appColors
                                                          .separatorColor,
                                                borderRadius: AppRadius.tiny,
                                              ),
                                              child: Text(
                                                '自道場',
                                                style: TextStyle(
                                                  fontSize: AppFontSize.badge,
                                                  fontWeight:
                                                      AppFontWeight.bold,
                                                  color: context
                                                      .appColors
                                                      .primaryAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),

                      children: _buildExpansionChildren(
                        context: context,
                        ref: ref,
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
        ],
      ),
    );
  }

  List<Widget> _buildExpansionChildren({
    required BuildContext context,
    required WidgetRef ref,
    required PermissionState permissions,
    required MatchRule rule,
    required MatchModel firstMatch,
  }) {
    final normalMatches = groupList.where((m) => m.matchType != '代表戦').toList();
    final normalItems = <dynamic>[...normalMatches, ...groupComments];
    normalItems.sort(
      (a, b) => (a.order as double).compareTo(b.order as double),
    );

    final childrenWidgets = <Widget>[const Divider(height: 1)];

    if (label.contains('リーグ戦')) {
      if (allGroupFinished(groupList)) {
        final tieGroups = TimelineTieBreakDetector.detectTieGroups(
          normalMatches: normalMatches,
          rule: rule,
        );

        if (tieGroups.isNotEmpty) {
          childrenWidgets.add(
            Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFFFF9800).withValues(alpha: 0.2)
                    : const Color(0xFFFF9800),
                border: Border.all(color: context.appColors.warningColor),
                borderRadius: AppRadius.medium,
              ),
              child: Column(
                children: tieGroups.map((group) {
                  return ElevatedButton.icon(
                    onPressed: () => TimelineTieBreakDialog.show(
                      context,
                      ref,
                      firstMatch,
                      group,
                      rule,
                    ),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('順位決定戦を作成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.warningColor,
                      foregroundColor: AppKendoColors.pureWhite,
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }
      }
    }

    if (label.contains('リーグ戦') && label.contains('個人戦')) {
      childrenWidgets.add(
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: !isReadOnlyUI,
          onReorderItem: (oldIndex, newIndex) =>
              TimelineReorderHelper.onReorderInnerTimeline(
                normalItems.cast<TimelineItem>(),
                oldIndex,
                newIndex,
                ref,
              ),
          children: normalItems
              .map<Widget?>((i) {
                if (i is MatchModel) {
                  return Container(
                    key: ValueKey(i.id),
                    child: MatchListTileCard(
                      key: ValueKey(i.id),
                      initialMatch: i,
                    ),
                  );
                } else if (i is MatchCommentModel) {
                  return Container(
                    key: ValueKey('inner_comment_${i.id}'),
                    child: TimelineInnerCommentWidget(
                      comment: i,
                      permissions: permissions,
                      isDark: isDark,
                      ref: ref,
                    ),
                  );
                }
                return null;
              })
              .whereType<Widget>()
              .toList(),
        ),
      );
    } else {
      childrenWidgets.addAll(
        normalMatches.map(
          (m) => MatchListTileCard(key: ValueKey(m.id), initialMatch: m),
        ),
      );
    }

    return childrenWidgets;
  }

  bool allGroupFinished(List<MatchModel> list) {
    return list.every((m) => m.status == 'finished' || m.status == 'approved');
  }
}
