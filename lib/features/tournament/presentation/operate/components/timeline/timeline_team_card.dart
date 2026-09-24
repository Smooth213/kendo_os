import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_comment_slidable_tile.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_rename_team_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_reorder_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart'
    show showUnifiedAnnounceDialog;
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// タイムライン内のチームごとの大枠カードWidget
class TimelineTeamCard extends ConsumerWidget {
  final String teamName;
  final List<MatchModel> teamMatchesList;
  final String categoryName;
  final String tournamentId;
  final String sanitizedQuery;
  final Set<String> matchedMatchIds;
  final Set<String> matchedGroupNames;
  final List<String> ownTeams;
  final List<MatchCommentModel> comments;
  final bool isReadOnlyUI;
  final bool canManageTournamentUI;
  final bool isDark;
  final PermissionState permissions;

  const TimelineTeamCard({
    super.key,
    required this.teamName,
    required this.teamMatchesList,
    required this.categoryName,
    required this.tournamentId,
    required this.sanitizedQuery,
    required this.matchedMatchIds,
    required this.matchedGroupNames,
    required this.ownTeams,
    required this.comments,
    required this.isReadOnlyUI,
    required this.canManageTournamentUI,
    required this.isDark,
    required this.permissions,
  });

  String _getMatchLabel(MatchModel m) {
    final bool isLeague = m.note.contains('[リーグ戦]');
    final bool isKachinuki = m.isKachinuki;
    final bool isIndividual =
        !isKachinuki && (m.matchType == 'individual' || m.matchType == '選手');
    if (isLeague) return isIndividual ? '個人戦/リーグ戦' : '団体戦/リーグ戦';
    if (isKachinuki) return '団体戦/勝ち抜き戦';
    return isIndividual ? '個人戦' : '団体戦';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classified = TimelinePlayerMatchClassifier.classifyTeamMatches(
      teamMatchesList: teamMatchesList,
      teamName: teamName,
      sanitizedQuery: sanitizedQuery,
      matchedMatchIds: matchedMatchIds,
      matchedGroupNames: matchedGroupNames,
      ownTeams: ownTeams,
    );
    final sortedGroups = classified.sortedGroups;
    final sortedPlayers = classified.sortedPlayers;

    final timelineItems = <ReorderableTimelineItem>[];
    for (var entry in sortedGroups) {
      final groupComments = comments
          .where(
            (c) =>
                c.category == categoryName &&
                c.groupName == teamName &&
                c.matchGroupId == entry.key,
          )
          .toList();
      timelineItems.add(
        MatchGroupTimelineItem(entry.key, entry.value, groupComments),
      );
    }

    for (var entry in sortedPlayers) {
      final playerComments = comments
          .where(
            (c) =>
                c.category == categoryName &&
                c.groupName == teamName &&
                c.matchGroupId == entry.key,
          )
          .toList();
      timelineItems.add(
        IndividualPlayerTimelineItem(entry.key, entry.value, playerComments),
      );
    }

    final teamComments = comments
        .where(
          (c) =>
              c.category == categoryName &&
              c.groupName == teamName &&
              c.matchGroupId == null,
        )
        .toList();
    for (var c in teamComments) {
      timelineItems.add(CommentTimelineItem(c));
    }
    // ★ あとから追加した対戦カード（試合グループ）が最上位に来るよう降順ソート
    timelineItems.sort((a, b) => b.order.compareTo(a.order));

    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161618) : const Color(0xFFFFFFFF),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
          width: 2,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3F51B5).withValues(alpha: 0.3)
                  : const Color(0xFF3F51B5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.modernValue),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : const Color(0xFF3F51B5),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.business,
                  color: AppKendoColors.pureWhite,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    teamName,
                    style: const TextStyle(
                      fontSize: AppFontSize.headline,
                      fontWeight: AppFontWeight.bold,
                      color: AppKendoColors.pureWhite,
                    ),
                  ),
                ),
                if (!isReadOnlyUI) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.add_comment,
                      color: AppKendoColors.pureWhite,
                      size: 20,
                    ),
                    tooltip: '見出し（コメント）を追加',
                    onPressed: () {
                      double topOrder = 0.0;
                      double groupMin = sortedGroups.isEmpty
                          ? double.infinity
                          : sortedGroups.first.value.first.order;
                      double playerMin = sortedPlayers.isEmpty
                          ? double.infinity
                          : sortedPlayers.first.value.first.order;
                      double minOrder = groupMin < playerMin
                          ? groupMin
                          : playerMin;
                      if (minOrder != double.infinity) {
                        topOrder = minOrder - 100.0;
                      }
                      showUnifiedAnnounceDialog(
                        context,
                        ref,
                        tournamentId,
                        categoryName,
                        teamName,
                        topOrder,
                      );
                    },
                  ),
                  if (canManageTournamentUI)
                    IconButton(
                      icon: const Icon(
                        Icons.edit_note,
                        color: AppKendoColors.pureWhite,
                        size: 20,
                      ),
                      tooltip: 'チーム名を修正して統合',
                      onPressed: () => TimelineRenameTeamSheet.show(
                        context: context,
                        ref: ref,
                        tournamentId: tournamentId,
                        oldName: teamName,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: !isReadOnlyUI,
            onReorderItem: (oldIndex, newIndex) =>
                TimelineReorderHelper.onReorderTimeline(
                  timelineItems,
                  oldIndex,
                  newIndex,
                  ref,
                ),
            children: (() {
              String lastGroupLabel = '';
              bool playerHeaderShown = false;
              return timelineItems
                  .asMap()
                  .entries
                  .map<Widget?>((itemEntry) {
                    final index = itemEntry.key;
                    final item = itemEntry.value;

                    if (item is CommentTimelineItem) {
                      return TimelineCommentSlidableTile(
                        key: ValueKey('comment_${item.comment.id}'),
                        comment: item.comment,
                        tournamentId: tournamentId,
                        isDark: isDark,
                        ref: ref,
                        index: index,
                      );
                    } else if (item is MatchGroupTimelineItem) {
                      final entry = MapEntry(item.groupId, item.matches);
                      final groupList = entry.value;
                      final firstMatch = groupList.first;
                      final label = _getMatchLabel(firstMatch);

                      Widget? headerWidget;
                      if (label != lastGroupLabel) {
                        headerWidget = Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.lg,
                            top: AppSpacing.md,
                            bottom: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.groups,
                                color: Color(0xFF3F51B5),
                                size: 16,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: AppFontSize.bodySmall,
                                  fontWeight: AppFontWeight.bold,
                                  color: Color(0xFF3F51B5),
                                ),
                              ),
                            ],
                          ),
                        );
                        lastGroupLabel = label;
                      }

                      return TimelineMatchGroupCard(
                        key: ValueKey('group_${entry.key}'),
                        groupId: entry.key,
                        groupList: groupList,
                        groupComments: item.comments,
                        categoryName: categoryName,
                        teamName: teamName,
                        label: label,
                        headerWidget: headerWidget,
                        isReadOnlyUI: isReadOnlyUI,
                        canManageTournamentUI: canManageTournamentUI,
                        isDark: isDark,
                        tournamentId: tournamentId,
                        ownTeams: ownTeams,
                      );
                    } else if (item is IndividualPlayerTimelineItem) {
                      Widget? headerWidget;
                      if (!playerHeaderShown) {
                        headerWidget = Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.lg,
                            top: AppSpacing.md,
                            bottom: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                sanitizedQuery.isNotEmpty
                                    ? Icons.manage_search
                                    : Icons.person,
                                color: const Color(0xFFFF9800),
                                size: 16,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                sanitizedQuery.isNotEmpty ? '抽出された個別試合' : '個人戦',
                                style: const TextStyle(
                                  fontSize: AppFontSize.bodySmall,
                                  fontWeight: AppFontWeight.bold,
                                  color: Color(0xFFFF9800),
                                ),
                              ),
                            ],
                          ),
                        );
                        playerHeaderShown = true;
                      }

                      return TimelineIndividualPlayerCard(
                        key: ValueKey('player_card_${item.playerName}'),
                        playerName: item.playerName,
                        playerMatches: item.matches,
                        playerComments: item.comments,
                        categoryName: categoryName,
                        teamName: teamName,
                        headerWidget: headerWidget,
                        tournamentId: tournamentId,
                        isReadOnlyUI: isReadOnlyUI,
                        isDark: isDark,
                        permissions: permissions,
                      );
                    }
                    return null;
                  })
                  .whereType<Widget>()
                  .toList();
            })(),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
