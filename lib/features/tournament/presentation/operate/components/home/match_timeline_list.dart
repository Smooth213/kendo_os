import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import '../bulk_rule_edit_sheet.dart';

import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show tournamentProvider;
import '../cards/match_list_tile_card.dart';
import 'match_timeline_control_bar.dart';
import 'tournament_header_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_rename_team_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_inner_comment_widget.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_edit_comment_dialog.dart';

import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_reorder_helper.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

export '../cards/match_list_tile_card.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_category_team_resolver.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_status_message_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';

export 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';

class MatchTimelineList extends ConsumerWidget {
  final String tournamentId;
  const MatchTimelineList({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final permissions = ref.watch(permissionProvider);
    final bool isReadOnlyUI = permissions.isReadOnly;
    final bool canManageTournamentUI = permissions.canManageTournament;

    final comments = ref.watch(commentStreamProvider(tournamentId)).value ?? [];

    final sanitizedQuery = ref
        .watch(searchQueryProvider)
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
    final timelineResult = ref.watch(safeTimelineProvider(tournamentId));
    final matchedGroupNames = timelineResult.matchedGroupNames;
    final matchedMatchIds = timelineResult.matchedMatchIds;
    final allMatches = timelineResult.entries.expand((e) => e.value).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.giant * 2),
      children: [
        // ============================================================
        // ★ 移設: 大会ヘッダー（HomeScreen から移動。リストと一緒にスクロールさせる）
        // ============================================================
        ref
            .watch(tournamentProvider(tournamentId))
            .when(
              data: (tournament) => tournament != null
                  ? TournamentHeaderCard(tournament: tournament)
                  : const SizedBox.shrink(),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, s) => Text('大会情報の読み込みに失敗しました: $e'),
            ),

        MatchTimelineControlBar(
          isSearchVisible: ref.watch(isSearchVisibleProvider),
          searchQuery: ref.watch(searchQueryProvider),
          isSortAscending: ref.watch(categorySortProvider),
          isReadOnlyUI: isReadOnlyUI,
          allMatches: allMatches,
          isDark: isDark,
          onSearchVisibilityChanged: (val) =>
              ref.read(isSearchVisibleProvider.notifier).state = val,
          onSearchQueryChanged: (val) =>
              ref.read(searchQueryProvider.notifier).state = val,
          onToggleSort: () => ref.read(categorySortProvider.notifier).state =
              !ref.read(categorySortProvider),
          onBulkRuleEdit: () => showBulkRuleEditSheet(
            context,
            tournamentId,
            allMatches,
            isBunaiksen: false,
          ),
        ),

        TimelineStatusMessageSection(
          timelineResult: timelineResult,
          sanitizedQuery: sanitizedQuery,
          isDark: isDark,
        ),

        ...(() {
          if (timelineResult.entries.isEmpty) return <Widget>[];
          final sortedEntries = timelineResult.entries;
          return sortedEntries.map<Widget>((catEntry) {
            final categoryName = catEntry.key;
            final catMatches = catEntry.value;
            final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
            final sortedTeams =
                TimelineCategoryTeamResolver.resolveMatchesByTeam(
                  catMatches: catMatches,
                  ownTeams: ownTeams,
                );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.bold,
                      color: isDark
                          ? context.appColors.primaryAccent
                          : const Color(0xFF3F51B5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                ...sortedTeams.map((teamEntry) {
                  final teamName = teamEntry.key;
                  final teamMatchesList = teamEntry.value;

                  String getMatchLabel(MatchModel m) {
                    final bool isLeague = m.note.contains('[リーグ戦]');
                    final bool isKachinuki = m.isKachinuki;
                    final bool isIndividual =
                        !isKachinuki &&
                        (m.matchType == 'individual' || m.matchType == '選手');
                    if (isLeague) return isIndividual ? '個人戦/リーグ戦' : '団体戦/リーグ戦';
                    if (isKachinuki) return '団体戦/勝ち抜き戦';
                    return isIndividual ? '個人戦' : '団体戦';
                  }

                  final classified =
                      TimelinePlayerMatchClassifier.classifyTeamMatches(
                        teamMatchesList: teamMatchesList,
                        teamName: teamName,
                        sanitizedQuery: sanitizedQuery,
                        matchedMatchIds: matchedMatchIds,
                        matchedGroupNames: matchedGroupNames,
                        ownTeams: ownTeams,
                      );
                  final sortedGroups = classified.sortedGroups;
                  final sortedPlayers = classified.sortedPlayers;

                  return Container(
                    margin: const EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.xl,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF161618)
                          : const Color(0xFFFFFFFF),
                      borderRadius: AppRadius.large,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : const Color(0x33000000),
                        width: 2,
                      ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(
                                  0xFF000000,
                                ).withValues(alpha: 0.05),
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
                              Icon(
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
                                    onPressed: () =>
                                        TimelineRenameTeamSheet.show(
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

                        Builder(
                          builder: (context) {
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
                                MatchGroupTimelineItem(
                                  entry.key,
                                  entry.value,
                                  groupComments,
                                ),
                              );
                            }
                            // ★ 修正: アコーディオン内に属さない（matchGroupId == null）コメントだけをチーム全体のタイムラインに配置する
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
                            timelineItems.sort(
                              (a, b) => a.order.compareTo(b.order),
                            );

                            return ReorderableListView(
                              shrinkWrap: true,
                              // ★ 修正: 閲覧専用の時はドラッグの物理的な動きを完全にロックし、誤タップによるブレを完全防止
                              physics: const NeverScrollableScrollPhysics(),
                              buildDefaultDragHandles:
                                  !isReadOnlyUI, // ★ 追加: 閲覧モードの時はドラッグ用のハンドルをつまませない
                              onReorderItem: (oldIndex, newIndex) =>
                                  TimelineReorderHelper.onReorderTimeline(
                                    timelineItems,
                                    oldIndex,
                                    newIndex,
                                    ref,
                                  ),
                              children: (() {
                                String lastGroupLabel = '';
                                return timelineItems
                                    .map<Widget?>((item) {
                                      if (item is CommentTimelineItem) {
                                        final c = item.comment;
                                        final commentWidget = Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.lg,
                                            vertical: AppSpacing.sm,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF2C2C2E)
                                                : const Color(0xFFF2F2F7),
                                            borderRadius: AppRadius.small,
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF38383A)
                                                  : AppKendoColors
                                                        .grey
                                                        .shade300,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.label_outline,
                                                color: isDark
                                                    ? AppKendoColors
                                                          .grey
                                                          .shade500
                                                    : AppKendoColors
                                                          .grey
                                                          .shade600,
                                                size: 16,
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  c.text,
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppFontSize.bodySmall,
                                                    fontWeight:
                                                        AppFontWeight.bold,
                                                    color: isDark
                                                        ? AppKendoColors
                                                              .grey
                                                              .shade300
                                                        : AppKendoColors
                                                              .grey
                                                              .shade800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        return Container(
                                          key: ValueKey('comment_${c.id}'),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.lg,
                                            vertical: AppSpacing.sm,
                                          ),
                                          child: Slidable(
                                            key: ValueKey(
                                              'slidable_comment_${c.id}',
                                            ),
                                            endActionPane: ActionPane(
                                              motion: const ScrollMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed: (context) =>
                                                      TimelineEditCommentDialog.show(
                                                        context,
                                                        ref,
                                                        c,
                                                      ),
                                                  backgroundColor:
                                                      AppKendoColors.blueAccent,
                                                  foregroundColor:
                                                      AppKendoColors.pureWhite,
                                                  icon: Icons.edit,
                                                  label: '編集',
                                                ),
                                                SlidableAction(
                                                  onPressed: (context) async {
                                                    final confirm = await showAppDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AppDialog(
                                                        backgroundColor: isDark
                                                            ? const Color(
                                                                0xFF1C1C1E,
                                                              )
                                                            : AppKendoColors
                                                                  .pureWhite,
                                                        titleWidget: Text(
                                                          '見出しの削除',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                AppFontWeight
                                                                    .bold,
                                                            color: isDark
                                                                ? AppKendoColors
                                                                      .pureWhite
                                                                : Colors
                                                                      .black87,
                                                          ),
                                                        ),
                                                        content: Text(
                                                          'この見出しを削除しますか？\n(取り消せません)',
                                                          style: TextStyle(
                                                            color: isDark
                                                                ? AppKendoColors
                                                                      .pureWhite
                                                                : Colors
                                                                      .black87,
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  ctx,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'キャンセル',
                                                              style: TextStyle(
                                                                color:
                                                                    AppKendoColors
                                                                        .grey,
                                                              ),
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  ctx,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              '削除',
                                                              style: TextStyle(
                                                                color:
                                                                    AppKendoColors
                                                                        .red,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      await ref
                                                          .read(
                                                            commentCommandProvider,
                                                          )
                                                          .deleteComment(
                                                            c.id,
                                                            c.tournamentId ??
                                                                tournamentId,
                                                          );
                                                    }
                                                  },
                                                  backgroundColor:
                                                      AppKendoColors.redAccent,
                                                  foregroundColor:
                                                      AppKendoColors.pureWhite,
                                                  icon: Icons.delete,
                                                  borderRadius:
                                                      const BorderRadius.horizontal(
                                                        right: Radius.circular(
                                                          AppRadius.smallValue,
                                                        ),
                                                      ),
                                                  label: '削除',
                                                ),
                                              ],
                                            ),
                                            child: commentWidget,
                                          ),
                                        );
                                      } else if (item
                                          is MatchGroupTimelineItem) {
                                        final entry = MapEntry(
                                          item.groupId,
                                          item.matches,
                                        );
                                        final groupList = entry.value;
                                        final firstMatch = groupList.first;
                                        final label = getMatchLabel(firstMatch);

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
                                                Icon(
                                                  Icons.groups,
                                                  color: isDark
                                                      ? AppKendoColors
                                                            .indigo
                                                            .shade300
                                                      : AppKendoColors
                                                            .indigo
                                                            .shade700,
                                                  size: 16,
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.xs,
                                                ),
                                                Text(
                                                  label,
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppFontSize.bodySmall,
                                                    fontWeight:
                                                        AppFontWeight.bold,
                                                    color: isDark
                                                        ? AppKendoColors
                                                              .indigo
                                                              .shade300
                                                        : Colors
                                                              .indigo
                                                              .shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          lastGroupLabel = label;
                                        }

                                        return TimelineMatchGroupCard(
                                          key: ValueKey(entry.key),
                                          groupId: entry.key,
                                          groupList: groupList,
                                          groupComments: item.comments,
                                          categoryName: categoryName,
                                          teamName: teamName,
                                          label: label,
                                          headerWidget: headerWidget,
                                          isReadOnlyUI: isReadOnlyUI,
                                          canManageTournamentUI:
                                              canManageTournamentUI,
                                          isDark: isDark,
                                          tournamentId: tournamentId,
                                          ownTeams: ownTeams,
                                        );
                                      }
                                      return null;
                                    })
                                    .whereType<Widget>()
                                    .toList();
                              })(),
                            );
                          },
                        ),

                        if (sortedPlayers.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.lg,
                              top: AppSpacing.xs,
                              bottom: AppSpacing.sm,
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
                                  sanitizedQuery.isNotEmpty
                                      ? '抽出された個別試合'
                                      : '個人戦',
                                  style: TextStyle(
                                    fontSize: AppFontSize.bodySmall,
                                    fontWeight: AppFontWeight.bold,
                                    color: const Color(0xFFFF9800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...sortedPlayers.map((playerEntry) {
                            final playerName = playerEntry.key;
                            final playerMatches = playerEntry.value;

                            // ★ 追加: 個人戦アコーディオン内部のコメントを取得し、試合と統合・ソートする
                            final playerComments = comments
                                .where(
                                  (c) =>
                                      c.category == categoryName &&
                                      c.groupName == teamName &&
                                      c.matchGroupId == playerName,
                                )
                                .toList();
                            final playerMixedItems = <TimelineItem>[
                              ...playerMatches,
                              ...playerComments,
                            ];
                            playerMixedItems.sort(
                              (a, b) =>
                                  a.timelineOrder.compareTo(b.timelineOrder),
                            );

                            final firstMatch = playerMatches.first;
                            final label =
                                (!firstMatch.isKachinuki &&
                                    (firstMatch.matchType == 'individual' ||
                                        firstMatch.matchType == '選手'))
                                ? (firstMatch.note.contains('[リーグ戦]')
                                      ? '個人戦/リーグ戦'
                                      : '個人戦')
                                : (firstMatch.isKachinuki
                                      ? '団体戦/勝ち抜き戦'
                                      : (firstMatch.note.contains('[リーグ戦]')
                                            ? '団体戦/リーグ戦'
                                            : '団体戦'));
                            final bool pInProgress = playerMatches.any(
                              (m) => m.status == 'in_progress',
                            );
                            final bool pAllFinished = playerMatches.every(
                              (m) =>
                                  m.status == 'finished' ||
                                  m.status == 'approved',
                            );
                            final Color pTitleColor = pAllFinished
                                ? (context.appColors.subTextColor)
                                : (context.appColors.textColor);
                            final Color pSubTitleColor =
                                context.appColors.subTextColor;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.medium,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF38383A)
                                      : const Color(0x33000000),
                                  width: 1,
                                ),
                                boxShadow: pInProgress
                                    ? [
                                        BoxShadow(
                                          color: AppKendoColors.blue.withValues(
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
                                    backgroundColor: isDark
                                        ? const Color(0xFF1C1C1E)
                                        : const Color(0xFFFFFFFF),
                                    collapsedBackgroundColor: isDark
                                        ? const Color(0xFF1C1C1E)
                                        : const Color(0xFFFAFAFC),
                                    iconColor: isDark
                                        ? context.appColors.primaryAccent
                                        : context.appColors.primaryAccent,
                                    collapsedIconColor: AppKendoColors.grey,
                                    textColor: context.appColors.textColor,
                                    collapsedTextColor: isDark
                                        ? context.appColors.textColor
                                              .withValues(alpha: 0.7)
                                        : context.appColors.cardBackground
                                              .withValues(alpha: 0.54),
                                  ),
                                  child: ExpansionTile(
                                    key: ValueKey('player_$playerName'),
                                    shape: const Border(),
                                    collapsedShape: const Border(),
                                    childrenPadding: EdgeInsets.zero,
                                    tilePadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: pAllFinished
                                          ? (context.appColors.separatorColor)
                                          : context.appColors.warningColor,
                                      child: Text(
                                        playerName[0],
                                        style: TextStyle(
                                          color: pAllFinished
                                              ? (isDark
                                                    ? AppKendoColors
                                                          .grey
                                                          .shade500
                                                    : AppKendoColors
                                                          .grey
                                                          .shade600)
                                              : context.appColors.warningColor,
                                          fontSize: AppFontSize.small,
                                          fontWeight: AppFontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      playerName,
                                      style: TextStyle(
                                        fontWeight: AppFontWeight.bold,
                                        fontSize: AppFontSize.bodyMedium,
                                        color: pTitleColor,
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text(
                                          '$label • ${playerMatches.length}試合',
                                          style: TextStyle(
                                            fontSize: AppFontSize.small,
                                            color: pSubTitleColor,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.subValue,
                                            vertical: AppSpacing.xxs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: pInProgress
                                                ? const Color(0xFF2196F3)
                                                : (pAllFinished
                                                      ? (isDark
                                                            ? Colors
                                                                  .grey
                                                                  .shade800
                                                            : Colors
                                                                  .grey
                                                                  .shade300)
                                                      : (isDark
                                                            ? const Color(
                                                                0xFF2C2C2E,
                                                              )
                                                            : Colors
                                                                  .grey
                                                                  .shade200)),
                                            borderRadius: AppRadius.tiny,
                                          ),
                                          child: Text(
                                            pInProgress
                                                ? '進行中'
                                                : (pAllFinished ? '終了' : '待機中'),
                                            style: TextStyle(
                                              fontSize: AppFontSize.badge,
                                              fontWeight: AppFontWeight.bold,
                                              color: pInProgress
                                                  ? AppKendoColors.pureWhite
                                                  : (pAllFinished
                                                        ? (isDark
                                                              ? Colors
                                                                    .grey
                                                                    .shade400
                                                              : Colors
                                                                    .grey
                                                                    .shade600)
                                                        : (isDark
                                                              ? Colors
                                                                    .grey
                                                                    .shade400
                                                              : Colors
                                                                    .grey
                                                                    .shade700)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: [
                                      // ★ 修正: playerMatches のみのリストから、playerMixedItems（コメント混在リスト）に変更し、_onReorderInnerTimeline に接続
                                      ReorderableListView(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        buildDefaultDragHandles: !isReadOnlyUI,
                                        onReorderItem: (oldIndex, newIndex) =>
                                            TimelineReorderHelper.onReorderInnerTimeline(
                                              playerMixedItems,
                                              oldIndex,
                                              newIndex,
                                              ref,
                                            ),
                                        children: playerMixedItems
                                            .map<Widget?>((i) {
                                              if (i is MatchModel) {
                                                // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                return Container(
                                                  key: ValueKey(i.id),
                                                  child: MatchListTileCard(
                                                    initialMatch: i,
                                                    isDeletable: true,
                                                  ),
                                                );
                                              } else if (i
                                                  is MatchCommentModel) {
                                                return Container(
                                                  key: ValueKey(
                                                    'inner_comment_${i.id}',
                                                  ),
                                                  child:
                                                      TimelineInnerCommentWidget(
                                                        comment: i,
                                                        permissions:
                                                            permissions,
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
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  );
                }),
              ],
            );
          }).toList();
        })(),
      ],
    );
  }
} // ★ ここで MatchTimelineList クラスを安全にクローズ（閉じ括弧）します。

void showUnifiedAnnounceDialog(
  BuildContext context,
  WidgetRef ref,
  String tournamentId,
  String category,
  String groupName,
  double order, {
  String? matchGroupId,
}) {
  TimelineUnifiedAnnounceDialog.show(
    context,
    ref,
    tournamentId,
    category,
    groupName,
    order,
    matchGroupId: matchGroupId,
  );
}
