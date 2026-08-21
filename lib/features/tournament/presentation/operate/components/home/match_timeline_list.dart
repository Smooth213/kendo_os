import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_control_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/tournament_header_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_category_team_resolver.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_status_message_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_team_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show tournamentProvider;
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../bulk_rule_edit_sheet.dart';

export '../cards/match_list_tile_card.dart';
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
                  return TimelineTeamCard(
                    teamName: teamEntry.key,
                    teamMatchesList: teamEntry.value,
                    categoryName: categoryName,
                    tournamentId: tournamentId,
                    sanitizedQuery: sanitizedQuery,
                    matchedMatchIds: matchedMatchIds,
                    matchedGroupNames: matchedGroupNames,
                    ownTeams: ownTeams,
                    comments: comments,
                    isReadOnlyUI: isReadOnlyUI,
                    canManageTournamentUI: canManageTournamentUI,
                    isDark: isDark,
                    permissions: permissions,
                  );
                }),
              ],
            );
          }).toList();
        })(),
      ],
    );
  }
}
// ★ ここで MatchTimelineList クラスを安全にクローズ（閉じ括弧）します。

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
