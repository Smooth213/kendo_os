import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import '../bulk_rule_edit_sheet.dart';
import '../rule_info_bottom_sheet.dart';

import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show tournamentProvider;
import '../cards/match_list_tile_card.dart';
import 'match_timeline_control_bar.dart';
import 'tournament_header_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_summary_input_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_tie_break_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_rename_team_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_league_title_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_dialog_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_inner_comment_widget.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_edit_comment_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_reorder_helper.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

export '../cards/match_list_tile_card.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_category_team_resolver.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';

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

        if (timelineResult.hasError)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppKendoColors.red,
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'データの取得に失敗しました',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFE53935)
                          : AppKendoColors.red,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    timelineResult.errorMessage ?? '通信状況を確認してください',
                    style: const TextStyle(
                      color: AppKendoColors.grey,
                      fontSize: AppFontSize.small,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        if (timelineResult.entries.isEmpty && sanitizedQuery.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(
              child: Text(
                '該当する試合が見つかりません',
                style: TextStyle(color: AppKendoColors.grey),
              ),
            ),
          ),

        // ★ 追加: 検索もしておらず、エラーもなく、ただ純粋に試合が0件の場合のメッセージ
        if (timelineResult.entries.isEmpty &&
            !timelineResult.isLoading &&
            sanitizedQuery.isEmpty &&
            !timelineResult.hasError)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.giant),
            child: Center(
              child: Text(
                'まだ試合がありません\n（またはクラウド同期待ちです）',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0x8A000000),
                  fontWeight: AppFontWeight.bold,
                  height: 1.5,
                ),
              ),
            ),
          ),

        if (timelineResult.entries.isEmpty && timelineResult.isLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
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

                                        final rTeam =
                                            firstMatch.redName.contains(':')
                                            ? firstMatch.redName
                                                  .split(':')
                                                  .first
                                                  .trim()
                                            : firstMatch.redName;
                                        final wTeam =
                                            firstMatch.whiteName.contains(':')
                                            ? firstMatch.whiteName
                                                  .split(':')
                                                  .first
                                                  .trim()
                                            : firstMatch.whiteName;

                                        final hasInProgress = groupList.any(
                                          (m) => m.status == 'in_progress',
                                        );
                                        final allFinished = groupList.every(
                                          (m) =>
                                              m.status == 'finished' ||
                                              m.status == 'approved',
                                        );
                                        final Color titleColor = allFinished
                                            ? (isDark
                                                  ? context
                                                        .appColors
                                                        .subTextColor
                                                  : AppKendoColors
                                                        .grey
                                                        .shade500)
                                            : (context.appColors.textColor);
                                        final Color subTitleColor = allFinished
                                            ? (isDark
                                                  ? const Color(0xFFFFFFFF)
                                                  : AppKendoColors
                                                        .grey
                                                        .shade500)
                                            : (isDark
                                                  ? context
                                                        .appColors
                                                        .subTextColor
                                                  : AppKendoColors
                                                        .grey
                                                        .shade600);

                                        return Container(
                                          key: ValueKey(entry.key),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ?headerWidget,
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: AppSpacing.md,
                                                      vertical: 6,
                                                    ),
                                                child: Slidable(
                                                  key: ValueKey(
                                                    'group_${entry.key}',
                                                  ),
                                                  enabled:
                                                      canManageTournamentUI,
                                                  endActionPane: ActionPane(
                                                    motion:
                                                        const ScrollMotion(),
                                                    children: [
                                                      SlidableAction(
                                                        onPressed: (context) =>
                                                            TimelineDialogHelper.showEditGroupNoteDialog(
                                                              context,
                                                              ref,
                                                              groupList,
                                                            ),
                                                        backgroundColor:
                                                            AppKendoColors
                                                                .blueAccent,
                                                        foregroundColor:
                                                            AppKendoColors
                                                                .pureWhite,
                                                        icon: Icons.edit,
                                                        label: '編集',
                                                      ),
                                                      SlidableAction(
                                                        onPressed: (context) async {
                                                          final confirm = await showAppDialog<bool>(
                                                            context: context,
                                                            builder: (ctx) => AppDialog(
                                                              backgroundColor:
                                                                  isDark
                                                                  ? const Color(
                                                                      0xFF1C1C1E,
                                                                    )
                                                                  : Colors
                                                                        .white,
                                                              titleWidget: Text(
                                                                '試合グループの削除',
                                                                style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: isDark
                                                                      ? Colors
                                                                            .white
                                                                      : Colors
                                                                            .black87,
                                                                ),
                                                              ),
                                                              content: Text(
                                                                'このグループに含まれる全試合を\n削除しますか？\n(取り消せません)',
                                                                style: TextStyle(
                                                                  color: isDark
                                                                      ? Colors
                                                                            .white
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
                                                                      color: Colors
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
                                                                    '削除する',
                                                                    style: TextStyle(
                                                                      color: Colors
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
                                                            for (var m
                                                                in groupList) {
                                                              await ref
                                                                  .read(
                                                                    matchCommandProvider,
                                                                  )
                                                                  .deleteMatch(
                                                                    m.id,
                                                                  );
                                                            }
                                                          }
                                                        },
                                                        backgroundColor:
                                                            AppKendoColors
                                                                .redAccent,
                                                        foregroundColor:
                                                            AppKendoColors
                                                                .pureWhite,
                                                        icon: Icons.delete,
                                                        borderRadius:
                                                            const BorderRadius.horizontal(
                                                              right: Radius.circular(
                                                                AppRadius
                                                                    .mediumValue,
                                                              ),
                                                            ),
                                                        label: '削除',
                                                      ),
                                                    ],
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      // ★ 修正: color: cardBg, を削除
                                                      borderRadius:
                                                          AppRadius.medium,
                                                      border: Border.all(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF38383A,
                                                              )
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                        width: 1,
                                                      ),
                                                      boxShadow: hasInProgress
                                                          ? [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .blue
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                blurRadius: 8,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      4,
                                                                    ),
                                                              ),
                                                            ]
                                                          : [],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          AppRadius.smooth,
                                                      child: ExpansionTileTheme(
                                                        data: ExpansionTileThemeData(
                                                          backgroundColor:
                                                              isDark
                                                              ? const Color(
                                                                  0xFF1C1C1E,
                                                                )
                                                              : AppKendoColors
                                                                    .pureWhite,
                                                          collapsedBackgroundColor:
                                                              isDark
                                                              ? const Color(
                                                                  0xFF1C1C1E,
                                                                )
                                                              : const Color(
                                                                  0xFFFAFAFC,
                                                                ),
                                                          iconColor: isDark
                                                              ? Colors
                                                                    .indigo
                                                                    .shade300
                                                              : Colors
                                                                    .indigo
                                                                    .shade700,
                                                          collapsedIconColor:
                                                              AppKendoColors
                                                                  .grey,
                                                          textColor: context
                                                              .appColors
                                                              .textColor,
                                                          collapsedTextColor:
                                                              isDark
                                                              ? AppKendoColors
                                                                    .pureWhite
                                                                    .withValues(
                                                                      alpha:
                                                                          0.7,
                                                                    )
                                                              : AppKendoColors
                                                                    .pureBlack
                                                                    .withValues(
                                                                      alpha:
                                                                          0.54,
                                                                    ),
                                                        ),
                                                        child: ExpansionTile(
                                                          key: ValueKey(
                                                            'group_${entry.key}',
                                                          ),
                                                          shape: const Border(),
                                                          collapsedShape:
                                                              const Border(),
                                                          childrenPadding:
                                                              EdgeInsets.zero,
                                                          tilePadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal:
                                                                    AppSpacing
                                                                        .lg,
                                                              ),
                                                          title: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              // 🔼 【1行目】: 運営系ボタン・ステータスライン（コントロール右寄せ）
                                                              Row(
                                                                children: [
                                                                  const Spacer(),
                                                                  // 簡易入力ボタン
                                                                  if (!isReadOnlyUI &&
                                                                      !allFinished &&
                                                                      !label.contains(
                                                                        '個人戦',
                                                                      ) &&
                                                                      !label.contains(
                                                                        '勝ち抜き戦',
                                                                      ) &&
                                                                      !label.contains(
                                                                        'リーグ戦',
                                                                      ) &&
                                                                      !(ref
                                                                                  .read(
                                                                                    customTeamNamesProvider,
                                                                                  )
                                                                                  .value ??
                                                                              [])
                                                                          .contains(
                                                                            groupList.first.redName
                                                                                .split(
                                                                                  ':',
                                                                                )
                                                                                .first
                                                                                .trim(),
                                                                          ) &&
                                                                      !(ref
                                                                                  .read(
                                                                                    customTeamNamesProvider,
                                                                                  )
                                                                                  .value ??
                                                                              [])
                                                                          .contains(
                                                                            groupList.first.whiteName
                                                                                .split(
                                                                                  ':',
                                                                                )
                                                                                .first
                                                                                .trim(),
                                                                          )) ...[
                                                                    SizedBox(
                                                                      height:
                                                                          26,
                                                                      child: OutlinedButton.icon(
                                                                        onPressed: () => _showSummaryInputDialog(
                                                                          context,
                                                                          ref,
                                                                          groupList,
                                                                        ),
                                                                        icon: Icon(
                                                                          Icons
                                                                              .flash_on,
                                                                          size:
                                                                              12,
                                                                          color: Colors
                                                                              .amber
                                                                              .shade700,
                                                                        ),
                                                                        label: Text(
                                                                          '簡易入力',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                AppFontSize.nano,
                                                                            fontWeight:
                                                                                AppFontWeight.bold,
                                                                            color:
                                                                                titleColor,
                                                                          ),
                                                                        ),
                                                                        style: OutlinedButton.styleFrom(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                AppSpacing.subValue,
                                                                          ),
                                                                          side: BorderSide(
                                                                            color: titleColor.withValues(
                                                                              alpha: 0.2,
                                                                            ),
                                                                          ),
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                AppRadius.sub,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                  ],
                                                                  // ℹ️詳細マーク
                                                                  if (!allFinished)
                                                                    Padding(
                                                                      padding: const EdgeInsets.only(
                                                                        right: AppSpacing
                                                                            .subValue,
                                                                      ),
                                                                      child: InkWell(
                                                                        onTap: () => _showRuleInfoSheet(
                                                                          context,
                                                                          firstMatch,
                                                                        ),
                                                                        borderRadius:
                                                                            AppRadius.medium,
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.all(
                                                                            AppSpacing.xs,
                                                                          ),
                                                                          child: Icon(
                                                                            Icons.info_outline,
                                                                            color:
                                                                                context.appColors.subTextColor,
                                                                            size:
                                                                                16,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  // 🛠️オーダー編集ボタン（団体戦・勝ち抜き戦・リーグ団体戦すべて共通）
                                                                  if (!isReadOnlyUI &&
                                                                      !allFinished &&
                                                                      firstMatch
                                                                              .groupName !=
                                                                          null &&
                                                                      firstMatch
                                                                          .groupName!
                                                                          .isNotEmpty) ...[
                                                                    SizedBox(
                                                                      height:
                                                                          26,
                                                                      width: 26,
                                                                      child: IconButton(
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        icon: Icon(
                                                                          Icons
                                                                              .swap_vert,
                                                                          size:
                                                                              18,
                                                                          color:
                                                                              isDark
                                                                              ? context.appColors.infoColor
                                                                              : context.appColors.infoColor,
                                                                        ),
                                                                        onPressed: () => TimelineDialogHelper.showOrderReorderSheet(
                                                                          context,
                                                                          ref,
                                                                          groupList,
                                                                        ),
                                                                        tooltip:
                                                                            'オーダー編集',
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                  ],
                                                                  // 📊スコアボタン
                                                                  if (!label
                                                                      .contains(
                                                                        'リーグ戦',
                                                                      )) ...[
                                                                    SizedBox(
                                                                      height:
                                                                          26,
                                                                      child: OutlinedButton(
                                                                        onPressed: () {
                                                                          final target =
                                                                              (firstMatch.groupName !=
                                                                                      null &&
                                                                                  firstMatch.groupName!.isNotEmpty)
                                                                              ? firstMatch.groupName!
                                                                              : firstMatch.id;
                                                                          final encodedTarget = Uri.encodeComponent(
                                                                            target,
                                                                          );
                                                                          final tId =
                                                                              firstMatch.tournamentId ??
                                                                              '';
                                                                          context.push(
                                                                            firstMatch.isKachinuki
                                                                                ? '/kachinuki-scoreboard/$encodedTarget?tournamentId=$tId'
                                                                                : '/team-scoreboard/$encodedTarget?tournamentId=$tId',
                                                                          );
                                                                        },
                                                                        style: OutlinedButton.styleFrom(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                AppSpacing.sm,
                                                                          ),
                                                                          side: BorderSide(
                                                                            color: titleColor.withValues(
                                                                              alpha: 0.2,
                                                                            ),
                                                                          ),
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                AppRadius.sub,
                                                                          ),
                                                                        ),
                                                                        child: Text(
                                                                          'スコア',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                AppFontSize.badge,
                                                                            fontWeight:
                                                                                AppFontWeight.bold,
                                                                            color:
                                                                                titleColor,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                  ],
                                                                  // 状態バナー
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          AppSpacing
                                                                              .subValue,
                                                                      vertical:
                                                                          AppSpacing
                                                                              .xxs,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          hasInProgress
                                                                          ? context.appColors.infoColor
                                                                          : (allFinished
                                                                                ? (context.appColors.separatorColor)
                                                                                : (isDark
                                                                                      ? const Color(
                                                                                          0xFF2C2C2E,
                                                                                        )
                                                                                      : context.appColors.separatorColor)),
                                                                      borderRadius:
                                                                          AppRadius
                                                                              .tiny,
                                                                    ),
                                                                    child: Text(
                                                                      hasInProgress
                                                                          ? '進行中'
                                                                          : (allFinished
                                                                                ? '終了'
                                                                                : '待機中'),
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            AppFontSize.badge,
                                                                        fontWeight:
                                                                            AppFontWeight.bold,
                                                                        color:
                                                                            hasInProgress
                                                                            ? AppKendoColors.pureWhite
                                                                            : (allFinished
                                                                                  ? (isDark
                                                                                        ? AppKendoColors.pureWhite.withValues(
                                                                                            alpha: 0.6,
                                                                                          )
                                                                                        : AppKendoColors.pureBlack.withValues(
                                                                                            alpha: 0.54,
                                                                                          ))
                                                                                  : (isDark
                                                                                        ? AppKendoColors.pureWhite.withValues(
                                                                                            alpha: 0.87,
                                                                                          )
                                                                                        : AppKendoColors.pureBlack.withValues(
                                                                                            alpha: 0.87,
                                                                                          ))),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              if (firstMatch
                                                                  .note
                                                                  .isNotEmpty) ...[
                                                                const SizedBox(
                                                                  height: 6,
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        AppSpacing
                                                                            .xxs,
                                                                  ),
                                                                  child: Text(
                                                                    firstMatch
                                                                        .note,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          AppFontSize
                                                                              .caption,
                                                                      color:
                                                                          subTitleColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              // 🔽 【3行目】: チーム合計スコア勝数(本数)ライン
                                                              Builder(
                                                                builder: (context) {
                                                                  // 団体戦グループ内の全ポジションから勝数・本数をリアルタイムに合算算出
                                                                  int redWins =
                                                                      0;
                                                                  int redPts =
                                                                      0;
                                                                  int
                                                                  whiteWins = 0;
                                                                  int whitePts =
                                                                      0;

                                                                  for (var m
                                                                      in groupList) {
                                                                    if (m.matchType ==
                                                                        '代表戦') {
                                                                      continue; // ★ 代表戦のスコアは合計に含めない
                                                                    }
                                                                    final r = m
                                                                        .redScore;
                                                                    final w = m
                                                                        .whiteScore;
                                                                    redPts +=
                                                                        (r as num)
                                                                            .toInt();
                                                                    whitePts +=
                                                                        (w as num)
                                                                            .toInt();
                                                                    final mFinished =
                                                                        m.status ==
                                                                            'finished' ||
                                                                        m.status ==
                                                                            'approved';
                                                                    if (mFinished) {
                                                                      if (r >
                                                                          w) {
                                                                        redWins++;
                                                                      } else if (w >
                                                                          r) {
                                                                        whiteWins++;
                                                                      }
                                                                    }
                                                                  }

                                                                  final ruleTeamName =
                                                                      groupList
                                                                          .firstOrNull
                                                                          ?.rule
                                                                          ?.teamName;
                                                                  final isRedOwn =
                                                                      ownTeams
                                                                          .contains(
                                                                            rTeam,
                                                                          ) ||
                                                                      (ruleTeamName?.isNotEmpty ==
                                                                              true &&
                                                                          rTeam ==
                                                                              ruleTeamName);
                                                                  final isWhiteOwn =
                                                                      ownTeams
                                                                          .contains(
                                                                            wTeam,
                                                                          ) ||
                                                                      (ruleTeamName?.isNotEmpty ==
                                                                              true &&
                                                                          wTeam ==
                                                                              ruleTeamName);

                                                                  // ★ 修正: リーグ戦と通常の団体戦のRow構造を完全分離し、はみ出しを100%防止
                                                                  if (label
                                                                      .contains(
                                                                        'リーグ戦',
                                                                      )) {
                                                                    return Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child: Text(
                                                                            TimelineLeagueTitleHelper.generateDescriptiveLeagueTitle(
                                                                              groupList,
                                                                              ownTeams,
                                                                            ),
                                                                            style: TextStyle(
                                                                              fontSize: AppFontSize.bodySmall,
                                                                              fontWeight: AppFontWeight.bold,
                                                                              color: titleColor,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis, // 268pxの極小画面でも絶対に溢れず綺麗に省略
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  } else {
                                                                    final showLeftTeam =
                                                                        rTeam;
                                                                    final showRightTeam =
                                                                        wTeam;
                                                                    final showLeftWins =
                                                                        redWins;
                                                                    final showLeftPts =
                                                                        redPts;
                                                                    final showRightWins =
                                                                        whiteWins;
                                                                    final showRightPts =
                                                                        whitePts;
                                                                    final showLeftOwn =
                                                                        isRedOwn;
                                                                    final showRightOwn =
                                                                        isWhiteOwn;

                                                                    return Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        // 左チーム名
                                                                        Expanded(
                                                                          child: Text(
                                                                            showLeftTeam,
                                                                            style: TextStyle(
                                                                              fontSize: AppFontSize.bodyMedium,
                                                                              fontWeight: showLeftOwn
                                                                                  ? AppFontWeight.black
                                                                                  : AppFontWeight.bold,
                                                                              color: showLeftOwn
                                                                                  ? (isDark
                                                                                        ? const Color(
                                                                                            0xFFF59E0B,
                                                                                          )
                                                                                        : const Color(
                                                                                            0xFFD97706,
                                                                                          ))
                                                                                  : titleColor,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.end,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                        // 中央合計スコア掲示（例: 3(5) - 1(2)）
                                                                        Padding(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                AppSpacing.lg,
                                                                          ),
                                                                          child: Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              Text(
                                                                                '$showLeftWins',
                                                                                style: TextStyle(
                                                                                  fontSize: AppFontSize.subhead,
                                                                                  fontWeight: AppFontWeight.bold,
                                                                                  color: isDark
                                                                                      ? const Color(
                                                                                          0xFFE53935,
                                                                                        )
                                                                                      : const Color(
                                                                                          0xFFE53935,
                                                                                        ),
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                '($showLeftPts)',
                                                                                style: TextStyle(
                                                                                  fontSize: AppFontSize.caption,
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
                                                                                    fontSize: AppFontSize.body,
                                                                                    color: context.appColors.subTextColor,
                                                                                    fontWeight: AppFontWeight.bold,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                '$showRightWins',
                                                                                style: TextStyle(
                                                                                  fontSize: AppFontSize.subhead,
                                                                                  fontWeight: AppFontWeight.bold,
                                                                                  color: context.appColors.textColor,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                '($showRightPts)',
                                                                                style: TextStyle(
                                                                                  fontSize: AppFontSize.caption,
                                                                                  color: context.appColors.subTextColor,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        // 右チーム名
                                                                        Expanded(
                                                                          child: Text(
                                                                            showRightTeam,
                                                                            style: TextStyle(
                                                                              fontSize: AppFontSize.bodyMedium,
                                                                              fontWeight: showRightOwn
                                                                                  ? AppFontWeight.black
                                                                                  : AppFontWeight.bold,
                                                                              color: showRightOwn
                                                                                  ? (isDark
                                                                                        ? const Color(
                                                                                            0xFFF59E0B,
                                                                                          )
                                                                                        : const Color(
                                                                                            0xFFD97706,
                                                                                          ))
                                                                                  : titleColor,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.start,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                          children: (() {
                                                            final List<Widget>
                                                            childrenWidgets =
                                                                [];
                                                            final normalMatches =
                                                                groupList
                                                                    .where(
                                                                      (m) => !m
                                                                          .note
                                                                          .contains(
                                                                            '[順位決定戦]',
                                                                          ),
                                                                    )
                                                                    .toList();
                                                            final tieBreakMatches =
                                                                groupList
                                                                    .where(
                                                                      (m) => m
                                                                          .note
                                                                          .contains(
                                                                            '[順位決定戦]',
                                                                          ),
                                                                    )
                                                                    .toList();
                                                            final normalItems = item
                                                                .sortedInnerItems
                                                                .where((i) {
                                                                  if (i
                                                                      is MatchModel) {
                                                                    return !i
                                                                        .note
                                                                        .contains(
                                                                          '[順位決定戦]',
                                                                        );
                                                                  }
                                                                  return true;
                                                                })
                                                                .toList();

                                                            if (label.contains(
                                                                  'リーグ戦',
                                                                ) &&
                                                                allFinished &&
                                                                !label.contains(
                                                                  '個人戦',
                                                                ) &&
                                                                tieBreakMatches
                                                                    .isEmpty) {
                                                              final rule =
                                                                  firstMatch
                                                                      .rule ??
                                                                  ref.read(
                                                                    matchRuleProvider,
                                                                  );
                                                              final tieGroups =
                                                                  <
                                                                    List<
                                                                      dynamic
                                                                    >
                                                                  >[];
                                                              // ★ 適合修正: 強制アンラップ (!) を排し、if による無害なヌルガードを緊縛して Lint 警告を完全消滅させます
                                                              if (rule !=
                                                                  null) {
                                                                final stats =
                                                                    KendoRuleEngine.calculateLeagueStandings(
                                                                      normalMatches,
                                                                      rule,
                                                                    );
                                                                if (stats
                                                                        .length >
                                                                    1) {
                                                                  List<dynamic>
                                                                  currentTie = [
                                                                    stats.first,
                                                                  ];
                                                                  for (
                                                                    int i = 1;
                                                                    i <
                                                                        stats
                                                                            .length;
                                                                    i++
                                                                  ) {
                                                                    final prev =
                                                                        stats[i -
                                                                            1];
                                                                    final curr =
                                                                        stats[i];
                                                                    bool isTie =
                                                                        (prev.customPoints -
                                                                                    curr.customPoints)
                                                                                .abs() <
                                                                            0.001 &&
                                                                        prev.matchWins ==
                                                                            curr.matchWins &&
                                                                        prev.individualWinners ==
                                                                            curr.individualWinners &&
                                                                        prev.totalPointsScored ==
                                                                            curr.totalPointsScored;
                                                                    if (isTie) {
                                                                      currentTie
                                                                          .add(
                                                                            curr,
                                                                          );
                                                                    } else {
                                                                      if (currentTie
                                                                              .length >
                                                                          1) {
                                                                        tieGroups.add(
                                                                          List.from(
                                                                            currentTie,
                                                                          ),
                                                                        );
                                                                      }
                                                                      currentTie =
                                                                          [curr];
                                                                    }
                                                                  }
                                                                  if (currentTie
                                                                          .length >
                                                                      1) {
                                                                    tieGroups.add(
                                                                      currentTie,
                                                                    );
                                                                  }
                                                                }

                                                                if (tieGroups
                                                                    .isNotEmpty) {
                                                                  childrenWidgets.add(
                                                                    Container(
                                                                      margin: const EdgeInsets.all(
                                                                        AppSpacing
                                                                            .md,
                                                                      ),
                                                                      padding: const EdgeInsets.all(
                                                                        AppSpacing
                                                                            .md,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            isDark
                                                                            ? const Color(
                                                                                0xFFFF9800,
                                                                              ).withValues(
                                                                                alpha: 0.2,
                                                                              )
                                                                            : const Color(
                                                                                0xFFFF9800,
                                                                              ),
                                                                        border: Border.all(
                                                                          color: Colors
                                                                              .orange
                                                                              .shade300,
                                                                        ),
                                                                        borderRadius:
                                                                            AppRadius.medium,
                                                                      ),
                                                                      child: Column(
                                                                        children: tieGroups.map((
                                                                          group,
                                                                        ) {
                                                                          return ElevatedButton.icon(
                                                                            onPressed: () => _showTieBreakDialog(
                                                                              context,
                                                                              ref,
                                                                              firstMatch,
                                                                              group,
                                                                              rule,
                                                                            ),
                                                                            icon: const Icon(
                                                                              Icons.add_circle,
                                                                            ),
                                                                            label: const Text(
                                                                              '順位決定戦を作成',
                                                                            ),
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

                                                            if (label.contains(
                                                              'リーグ戦',
                                                            )) {
                                                              if (label
                                                                  .contains(
                                                                    '個人戦',
                                                                  )) {
                                                                childrenWidgets.add(
                                                                  ReorderableListView(
                                                                    shrinkWrap:
                                                                        true,
                                                                    physics:
                                                                        const NeverScrollableScrollPhysics(),
                                                                    buildDefaultDragHandles:
                                                                        !isReadOnlyUI,
                                                                    onReorderItem:
                                                                        (
                                                                          oldIndex,
                                                                          newIndex,
                                                                        ) => TimelineReorderHelper.onReorderInnerTimeline(
                                                                          normalItems,
                                                                          oldIndex,
                                                                          newIndex,
                                                                          ref,
                                                                        ),
                                                                    children: normalItems
                                                                        .map<
                                                                          Widget?
                                                                        >((i) {
                                                                          if (i
                                                                              is MatchModel) {
                                                                            // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                                            return Container(
                                                                              key: ValueKey(
                                                                                i.id,
                                                                              ),
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
                                                                        .whereType<
                                                                          Widget
                                                                        >()
                                                                        .toList(),
                                                                  ),
                                                                );
                                                              } else {
                                                                final boutsByMatchup =
                                                                    <
                                                                      String,
                                                                      List<
                                                                        MatchModel
                                                                      >
                                                                    >{};
                                                                final matchupOrder =
                                                                    <String>[];
                                                                for (var m
                                                                    in normalMatches) {
                                                                  final matchupName =
                                                                      '${m.redName.split(':').first.trim()} vs ${m.whiteName.split(':').first.trim()}';
                                                                  if (!boutsByMatchup
                                                                      .containsKey(
                                                                        matchupName,
                                                                      )) {
                                                                    matchupOrder
                                                                        .add(
                                                                          matchupName,
                                                                        );
                                                                    boutsByMatchup[matchupName] =
                                                                        [];
                                                                  }
                                                                  boutsByMatchup[matchupName]!
                                                                      .add(m);
                                                                }

                                                                final combinedItems =
                                                                    <dynamic>[];
                                                                for (var name
                                                                    in matchupOrder) {
                                                                  combinedItems.add({
                                                                    'type':
                                                                        'matchup',
                                                                    'name':
                                                                        name,
                                                                    'matches':
                                                                        boutsByMatchup[name]!,
                                                                    'order': boutsByMatchup[name]!
                                                                        .first
                                                                        .order,
                                                                  });
                                                                }
                                                                for (var i
                                                                    in normalItems) {
                                                                  if (i
                                                                      is MatchCommentModel) {
                                                                    combinedItems.add({
                                                                      'type':
                                                                          'comment',
                                                                      'comment':
                                                                          i,
                                                                      'order': i
                                                                          .order,
                                                                    });
                                                                  }
                                                                }
                                                                combinedItems.sort(
                                                                  (a, b) =>
                                                                      (a['order']
                                                                              as double)
                                                                          .compareTo(
                                                                            b['order']
                                                                                as double,
                                                                          ),
                                                                );

                                                                childrenWidgets.add(
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .stretch,
                                                                    children: combinedItems.map<Widget>((
                                                                      cItem,
                                                                    ) {
                                                                      if (cItem['type'] ==
                                                                          'comment') {
                                                                        final c =
                                                                            cItem['comment']
                                                                                as MatchCommentModel;
                                                                        return Container(
                                                                          key: ValueKey(
                                                                            'inner_comment_${c.id}',
                                                                          ),
                                                                          child: TimelineInnerCommentWidget(
                                                                            comment:
                                                                                c,
                                                                            permissions:
                                                                                permissions,
                                                                            isDark:
                                                                                isDark,
                                                                            ref:
                                                                                ref,
                                                                          ),
                                                                        );
                                                                      }
                                                                      final name =
                                                                          cItem['name']
                                                                              as String;
                                                                      final bouts =
                                                                          cItem['matches']
                                                                              as List<
                                                                                MatchModel
                                                                              >;
                                                                      final bool
                                                                      boutsInProgress = bouts.any(
                                                                        (m) =>
                                                                            m.status ==
                                                                            'in_progress',
                                                                      );
                                                                      final bool
                                                                      boutsAllFinished = bouts.every(
                                                                        (m) =>
                                                                            m.status ==
                                                                                'finished' ||
                                                                            m.status ==
                                                                                'approved',
                                                                      );
                                                                      final t1 =
                                                                          name.split(
                                                                            ' vs ',
                                                                          )[0];
                                                                      final t2 =
                                                                          name.split(
                                                                            ' vs ',
                                                                          )[1];
                                                                      final Color
                                                                      mTitleColor =
                                                                          boutsAllFinished
                                                                          ? (context.appColors.subTextColor)
                                                                          : (context.appColors.textColor);

                                                                      return Container(
                                                                        key: ValueKey(
                                                                          'league_team_$name',
                                                                        ),
                                                                        margin: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              AppSpacing.sm,
                                                                          vertical:
                                                                              AppSpacing.xs,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          borderRadius:
                                                                              AppRadius.small,
                                                                          border: Border.all(
                                                                            color:
                                                                                isDark
                                                                                ? const Color(
                                                                                    0xFF38383A,
                                                                                  )
                                                                                : const Color(
                                                                                    0x33000000,
                                                                                  ),
                                                                            width:
                                                                                1,
                                                                          ),
                                                                          boxShadow:
                                                                              boutsInProgress
                                                                              ? [
                                                                                  BoxShadow(
                                                                                    color: AppKendoColors.blue.withValues(
                                                                                      alpha: 0.1,
                                                                                    ),
                                                                                    blurRadius: 4,
                                                                                    offset: const Offset(
                                                                                      0,
                                                                                      2,
                                                                                    ),
                                                                                  ),
                                                                                ]
                                                                              : [],
                                                                        ),
                                                                        child: ClipRRect(
                                                                          borderRadius:
                                                                              AppRadius.sub,
                                                                          child: ExpansionTileTheme(
                                                                            data: ExpansionTileThemeData(
                                                                              backgroundColor: isDark
                                                                                  ? const Color(
                                                                                      0xFF1C1C1E,
                                                                                    )
                                                                                  : const Color(
                                                                                      0xFFFFFFFF,
                                                                                    ),
                                                                              collapsedBackgroundColor: isDark
                                                                                  ? const Color(
                                                                                      0xFF1C1C1E,
                                                                                    )
                                                                                  : const Color(
                                                                                      0xFFFAFAFC,
                                                                                    ),
                                                                              iconColor: isDark
                                                                                  ? context.appColors.primaryAccent
                                                                                  : context.appColors.primaryAccent,
                                                                              collapsedIconColor: AppKendoColors.grey,
                                                                              textColor: context.appColors.textColor,
                                                                              collapsedTextColor: isDark
                                                                                  ? context.appColors.textColor.withValues(
                                                                                      alpha: 0.7,
                                                                                    )
                                                                                  : context.appColors.cardBackground.withValues(
                                                                                      alpha: 0.54,
                                                                                    ),
                                                                            ),
                                                                            child: ExpansionTile(
                                                                              key: ValueKey(
                                                                                'tile_league_team_$name',
                                                                              ),
                                                                              backgroundColor: isDark
                                                                                  ? const Color(
                                                                                      0xFF1C1C1E,
                                                                                    )
                                                                                  : const Color(
                                                                                      0xFFFFFFFF,
                                                                                    ),
                                                                              collapsedBackgroundColor: isDark
                                                                                  ? const Color(
                                                                                      0xFF161618,
                                                                                    )
                                                                                  : context.appColors.textColor,
                                                                              iconColor: isDark
                                                                                  ? context.appColors.primaryAccent
                                                                                  : context.appColors.primaryAccent,
                                                                              collapsedIconColor: AppKendoColors.grey,
                                                                              textColor: context.appColors.textColor,
                                                                              collapsedTextColor: isDark
                                                                                  ? context.appColors.textColor.withValues(
                                                                                      alpha: 0.7,
                                                                                    )
                                                                                  : context.appColors.cardBackground.withValues(
                                                                                      alpha: 0.54,
                                                                                    ),
                                                                              shape: const Border(),
                                                                              collapsedShape: const Border(),
                                                                              childrenPadding: EdgeInsets.zero,
                                                                              tilePadding: const EdgeInsets.symmetric(
                                                                                horizontal: AppSpacing.lg,
                                                                              ),
                                                                              title: Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  // 🔼 【中枠1行目】: コントロールボタン集約ライン
                                                                                  Row(
                                                                                    children: [
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
                                                                                      Builder(
                                                                                        builder:
                                                                                            (
                                                                                              context,
                                                                                            ) {
                                                                                              final ownT =
                                                                                                  ref
                                                                                                      .read(
                                                                                                        customTeamNamesProvider,
                                                                                                      )
                                                                                                      .value ??
                                                                                                  [];
                                                                                              final rT = bouts.first.redName
                                                                                                  .split(
                                                                                                    ':',
                                                                                                  )
                                                                                                  .first
                                                                                                  .trim();
                                                                                              final wT = bouts.first.whiteName
                                                                                                  .split(
                                                                                                    ':',
                                                                                                  )
                                                                                                  .first
                                                                                                  .trim();
                                                                                              if (!isReadOnlyUI &&
                                                                                                  !boutsAllFinished &&
                                                                                                  !(ownT.contains(
                                                                                                        rT,
                                                                                                      ) ||
                                                                                                      bouts.first.redName.contains(
                                                                                                        '自チーム',
                                                                                                      )) &&
                                                                                                  !(ownT.contains(
                                                                                                        wT,
                                                                                                      ) ||
                                                                                                      bouts.first.whiteName.contains(
                                                                                                        '自チーム',
                                                                                                      ))) {
                                                                                                return Padding(
                                                                                                  padding: const EdgeInsets.only(
                                                                                                    right: AppSpacing.subValue,
                                                                                                  ),
                                                                                                  child: SizedBox(
                                                                                                    height: 24,
                                                                                                    child: OutlinedButton.icon(
                                                                                                      onPressed: () => _showSummaryInputDialog(
                                                                                                        context,
                                                                                                        ref,
                                                                                                        bouts,
                                                                                                      ),
                                                                                                      icon: Icon(
                                                                                                        Icons.flash_on,
                                                                                                        size: 11,
                                                                                                        color: const Color(
                                                                                                          0xFFD97706,
                                                                                                        ),
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
                                                                                                          color: mTitleColor.withValues(
                                                                                                            alpha: 0.2,
                                                                                                          ),
                                                                                                        ),
                                                                                                        shape: RoundedRectangleBorder(
                                                                                                          borderRadius: AppRadius.sub,
                                                                                                        ),
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                );
                                                                                              }
                                                                                              return const SizedBox.shrink();
                                                                                            },
                                                                                      ),
                                                                                      // スコアボタン
                                                                                      Padding(
                                                                                        padding: const EdgeInsets.only(
                                                                                          right: AppSpacing.subValue,
                                                                                        ),
                                                                                        child: SizedBox(
                                                                                          height: 24,
                                                                                          child: OutlinedButton(
                                                                                            onPressed: () {
                                                                                              final target =
                                                                                                  (bouts.first.groupName !=
                                                                                                          null &&
                                                                                                      bouts.first.groupName!.isNotEmpty)
                                                                                                  ? bouts.first.groupName!
                                                                                                  : bouts.first.id;
                                                                                              final encodedTarget = Uri.encodeComponent(
                                                                                                target,
                                                                                              );
                                                                                              final tId =
                                                                                                  bouts.first.tournamentId ??
                                                                                                  '';
                                                                                              context.push(
                                                                                                '/team-scoreboard/$encodedTarget?tournamentId=$tId',
                                                                                              );
                                                                                            },
                                                                                            style: OutlinedButton.styleFrom(
                                                                                              padding: const EdgeInsets.symmetric(
                                                                                                horizontal: AppSpacing.sm,
                                                                                              ),
                                                                                              side: BorderSide(
                                                                                                color: mTitleColor.withValues(
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
                                                                                                color: mTitleColor,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      // 状態バナー
                                                                                      Container(
                                                                                        padding: const EdgeInsets.symmetric(
                                                                                          horizontal: AppSpacing.subValue,
                                                                                          vertical: AppSpacing.xxs,
                                                                                        ),
                                                                                        decoration: BoxDecoration(
                                                                                          color: boutsInProgress
                                                                                              ? context.appColors.infoColor
                                                                                              : (boutsAllFinished
                                                                                                    ? (context.appColors.separatorColor)
                                                                                                    : (isDark
                                                                                                          ? const Color(
                                                                                                              0xFF2C2C2E,
                                                                                                            )
                                                                                                          : context.appColors.separatorColor)),
                                                                                          borderRadius: AppRadius.tiny,
                                                                                        ),
                                                                                        child: Text(
                                                                                          boutsInProgress
                                                                                              ? '進行中'
                                                                                              : (boutsAllFinished
                                                                                                    ? '終了'
                                                                                                    : '待機中'),
                                                                                          style: TextStyle(
                                                                                            fontSize: AppFontSize.badge,
                                                                                            fontWeight: AppFontWeight.bold,
                                                                                            color: boutsInProgress
                                                                                                ? AppKendoColors.pureWhite
                                                                                                : (boutsAllFinished
                                                                                                      ? (isDark
                                                                                                            ? const Color(
                                                                                                                0x8A000000,
                                                                                                              )
                                                                                                            : const Color(
                                                                                                                0x8A000000,
                                                                                                              ))
                                                                                                      : (isDark
                                                                                                            ? const Color(
                                                                                                                0x8A000000,
                                                                                                              )
                                                                                                            : const Color(
                                                                                                                0xDE000000,
                                                                                                              ))),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                  const SizedBox(
                                                                                    height: 8,
                                                                                  ),
                                                                                  // 🔽 【中枠2行目】: リーグ内チーム対抗勝数(本数)掲示ライン
                                                                                  Builder(
                                                                                    builder:
                                                                                        (
                                                                                          context,
                                                                                        ) {
                                                                                          int redWins = 0;
                                                                                          int redPts = 0;
                                                                                          int whiteWins = 0;
                                                                                          int whitePts = 0;
                                                                                          for (var m in bouts) {
                                                                                            final r = m.redScore;
                                                                                            final w = m.whiteScore;
                                                                                            redPts +=
                                                                                                (r
                                                                                                        as num)
                                                                                                    .toInt();
                                                                                            whitePts +=
                                                                                                (w
                                                                                                        as num)
                                                                                                    .toInt();
                                                                                            if (m.status ==
                                                                                                    'finished' ||
                                                                                                m.status ==
                                                                                                    'approved') {
                                                                                              if (r >
                                                                                                  w) {
                                                                                                redWins++;
                                                                                              } else if (w >
                                                                                                  r) {
                                                                                                whiteWins++;
                                                                                              }
                                                                                            }
                                                                                          }
                                                                                          final ruleTeamName = bouts.firstOrNull?.rule?.teamName;
                                                                                          final isRedOwn =
                                                                                              ownTeams.contains(
                                                                                                t1,
                                                                                              ) ||
                                                                                              (ruleTeamName?.isNotEmpty ==
                                                                                                      true &&
                                                                                                  t1 ==
                                                                                                      ruleTeamName);
                                                                                          final isWhiteOwn =
                                                                                              ownTeams.contains(
                                                                                                t2,
                                                                                              ) ||
                                                                                              (ruleTeamName?.isNotEmpty ==
                                                                                                      true &&
                                                                                                  t2 ==
                                                                                                      ruleTeamName);

                                                                                          final showLeftTeam = t1;
                                                                                          final showRightTeam = t2;
                                                                                          final showLeftWins = redWins;
                                                                                          final showLeftPts = redPts;
                                                                                          final showRightWins = whiteWins;
                                                                                          final showRightPts = whitePts;
                                                                                          final showLeftOwn = isRedOwn;
                                                                                          final showRightOwn = isWhiteOwn;

                                                                                          return Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                                            children: [
                                                                                              Expanded(
                                                                                                child: Text(
                                                                                                  showLeftTeam,
                                                                                                  style: TextStyle(
                                                                                                    fontSize: AppFontSize.body,
                                                                                                    fontWeight: showLeftOwn
                                                                                                        ? AppFontWeight.black
                                                                                                        : AppFontWeight.bold,
                                                                                                    color: showLeftOwn
                                                                                                        ? const Color(
                                                                                                            0xFFD97706,
                                                                                                          )
                                                                                                        : mTitleColor,
                                                                                                  ),
                                                                                                  textAlign: TextAlign.end,
                                                                                                  overflow: TextOverflow.ellipsis,
                                                                                                ),
                                                                                              ),
                                                                                              Padding(
                                                                                                padding: const EdgeInsets.symmetric(
                                                                                                  horizontal: AppSpacing.md,
                                                                                                ),
                                                                                                child: Row(
                                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                                  children: [
                                                                                                    Text(
                                                                                                      '$showLeftWins',
                                                                                                      style: TextStyle(
                                                                                                        fontSize: AppFontSize.bodyMedium,
                                                                                                        fontWeight: AppFontWeight.bold,
                                                                                                        color: isDark
                                                                                                            ? const Color(
                                                                                                                0xFFE53935,
                                                                                                              )
                                                                                                            : const Color(
                                                                                                                0xFFE53935,
                                                                                                              ),
                                                                                                      ),
                                                                                                    ),
                                                                                                    Text(
                                                                                                      '($showLeftPts)',
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
                                                                                                      '$showRightWins',
                                                                                                      style: TextStyle(
                                                                                                        fontSize: AppFontSize.bodyMedium,
                                                                                                        fontWeight: AppFontWeight.bold,
                                                                                                        color: context.appColors.textColor,
                                                                                                      ),
                                                                                                    ),
                                                                                                    Text(
                                                                                                      '($showRightPts)',
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
                                                                                                  showRightTeam,
                                                                                                  style: TextStyle(
                                                                                                    fontSize: AppFontSize.body,
                                                                                                    fontWeight: showRightOwn
                                                                                                        ? AppFontWeight.black
                                                                                                        : AppFontWeight.bold,
                                                                                                    color: showRightOwn
                                                                                                        ? const Color(
                                                                                                            0xFFD97706,
                                                                                                          )
                                                                                                        : mTitleColor,
                                                                                                  ),
                                                                                                  textAlign: TextAlign.start,
                                                                                                  overflow: TextOverflow.ellipsis,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          );
                                                                                        },
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                                              children: bouts
                                                                                  .map(
                                                                                    (
                                                                                      m,
                                                                                    ) => MatchListTileCard(
                                                                                      initialMatch: m,
                                                                                      isDeletable: false,
                                                                                    ),
                                                                                  )
                                                                                  .toList(),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }).toList(),
                                                                  ),
                                                                );
                                                              }
                                                            } else {
                                                              if (label
                                                                      .contains(
                                                                        '個人戦',
                                                                      ) ||
                                                                  label
                                                                      .contains(
                                                                        '選手',
                                                                      )) {
                                                                childrenWidgets.add(
                                                                  ReorderableListView(
                                                                    shrinkWrap:
                                                                        true,
                                                                    physics:
                                                                        const NeverScrollableScrollPhysics(),
                                                                    buildDefaultDragHandles:
                                                                        !isReadOnlyUI,
                                                                    onReorderItem:
                                                                        (
                                                                          oldIndex,
                                                                          newIndex,
                                                                        ) => TimelineReorderHelper.onReorderInnerTimeline(
                                                                          normalItems,
                                                                          oldIndex,
                                                                          newIndex,
                                                                          ref,
                                                                        ),
                                                                    children: normalItems
                                                                        .map<
                                                                          Widget?
                                                                        >((i) {
                                                                          if (i
                                                                              is MatchModel) {
                                                                            // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                                            return Container(
                                                                              key: ValueKey(
                                                                                i.id,
                                                                              ),
                                                                              child: MatchListTileCard(
                                                                                initialMatch: i,
                                                                                isDeletable: false,
                                                                              ),
                                                                            );
                                                                          } else if (i
                                                                              is MatchCommentModel) {
                                                                            return Container(
                                                                              key: ValueKey(
                                                                                'inner_comment_${i.id}',
                                                                              ),
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
                                                                        .whereType<
                                                                          Widget
                                                                        >()
                                                                        .toList(),
                                                                  ),
                                                                );
                                                              } else {
                                                                childrenWidgets.add(
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .stretch,
                                                                    children: normalItems.map<Widget>((
                                                                      i,
                                                                    ) {
                                                                      if (i
                                                                          is MatchModel) {
                                                                        return Container(
                                                                          key: ValueKey(
                                                                            i.id,
                                                                          ),
                                                                          child: MatchListTileCard(
                                                                            initialMatch:
                                                                                i,
                                                                            isDeletable:
                                                                                false,
                                                                          ),
                                                                        );
                                                                      } else if (i
                                                                          is MatchCommentModel) {
                                                                        return Container(
                                                                          key: ValueKey(
                                                                            'inner_comment_${i.id}',
                                                                          ),
                                                                          child: TimelineInnerCommentWidget(
                                                                            comment:
                                                                                i,
                                                                            permissions:
                                                                                permissions,
                                                                            isDark:
                                                                                isDark,
                                                                            ref:
                                                                                ref,
                                                                          ),
                                                                        );
                                                                      }
                                                                      return const SizedBox.shrink();
                                                                    }).toList(),
                                                                  ),
                                                                );
                                                              }
                                                            }

                                                            if (tieBreakMatches
                                                                .isNotEmpty) {
                                                              childrenWidgets.add(
                                                                const Divider(),
                                                              );
                                                              childrenWidgets.add(
                                                                const Padding(
                                                                  padding:
                                                                      EdgeInsets.all(
                                                                        AppSpacing
                                                                            .sm,
                                                                      ),
                                                                  child: Text(
                                                                    '【順位決定戦】',
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          AppFontSize
                                                                              .small,
                                                                      color: Colors
                                                                          .orange,
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                              if (label
                                                                      .contains(
                                                                        '個人戦',
                                                                      ) ||
                                                                  label
                                                                      .contains(
                                                                        '選手',
                                                                      )) {
                                                                childrenWidgets.add(
                                                                  ReorderableListView(
                                                                    shrinkWrap:
                                                                        true,
                                                                    physics:
                                                                        const NeverScrollableScrollPhysics(),
                                                                    buildDefaultDragHandles:
                                                                        !isReadOnlyUI,
                                                                    onReorderItem:
                                                                        (
                                                                          oldIndex,
                                                                          newIndex,
                                                                        ) => TimelineReorderHelper.onReorderMatches(
                                                                          tieBreakMatches,
                                                                          oldIndex,
                                                                          newIndex,
                                                                          ref,
                                                                        ),
                                                                    // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                                    children: tieBreakMatches
                                                                        .map(
                                                                          (
                                                                            m,
                                                                          ) => Container(
                                                                            key: ValueKey(
                                                                              m.id,
                                                                            ),
                                                                            child: MatchListTileCard(
                                                                              initialMatch: m,
                                                                              isDeletable: true,
                                                                            ),
                                                                          ),
                                                                        )
                                                                        .toList(),
                                                                  ),
                                                                );
                                                              } else {
                                                                final tieBoutsByMatchup =
                                                                    <
                                                                      String,
                                                                      List<
                                                                        MatchModel
                                                                      >
                                                                    >{};
                                                                final tieMatchupOrder =
                                                                    <String>[];
                                                                for (var m
                                                                    in tieBreakMatches) {
                                                                  final matchupName =
                                                                      '${m.redName.split(':').first.trim()} vs ${m.whiteName.split(':').first.trim()}';
                                                                  if (!tieBoutsByMatchup
                                                                      .containsKey(
                                                                        matchupName,
                                                                      )) {
                                                                    tieMatchupOrder
                                                                        .add(
                                                                          matchupName,
                                                                        );
                                                                    tieBoutsByMatchup[matchupName] =
                                                                        [];
                                                                  }
                                                                  tieBoutsByMatchup[matchupName]!
                                                                      .add(m);
                                                                }
                                                                childrenWidgets.add(
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .stretch,
                                                                    children: tieMatchupOrder.map<Widget>((
                                                                      name,
                                                                    ) {
                                                                      final bouts =
                                                                          tieBoutsByMatchup[name]!;
                                                                      // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                                      return Container(
                                                                        key: ValueKey(
                                                                          'tie_$name',
                                                                        ),
                                                                        child: Column(
                                                                          children: bouts
                                                                              .map(
                                                                                (
                                                                                  m,
                                                                                ) => MatchListTileCard(
                                                                                  initialMatch: m,
                                                                                  isDeletable: false,
                                                                                ),
                                                                              )
                                                                              .toList(),
                                                                        ),
                                                                      );
                                                                    }).toList(),
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                            return childrenWidgets;
                                                          })(),
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

// ============================================================================
// 🛡️ ファイル内トップレベル共有関数防衛要塞
// ============================================================================

void _showRuleInfoSheet(BuildContext context, MatchModel match) {
  showRuleInfoBottomSheet(context, match);
}

void _showTieBreakDialog(
  BuildContext parentContext,
  WidgetRef ref,
  MatchModel firstMatch,
  List<dynamic> tieTeams,
  dynamic baseRule,
) {
  TimelineTieBreakDialog.show(
    parentContext,
    ref,
    firstMatch,
    tieTeams,
    baseRule,
  );
}

void _showSummaryInputDialog(
  BuildContext context,
  WidgetRef ref,
  List<MatchModel> matches,
) {
  TimelineSummaryInputDialog.show(context, ref, matches);
}

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
