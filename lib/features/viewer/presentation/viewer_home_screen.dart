import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_call_banner.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_category_section_list.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_match_list_search_bar.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_quick_action_buttons.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_share_dialog.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_tournament_info_card.dart';
import 'package:kendo_os/features/viewer/presentation/providers/viewer_timeline_provider.dart';
import 'package:kendo_os/features/viewer/presentation/providers/viewer_tournament_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';

export 'components/viewer_call_banner.dart';
export 'components/viewer_group_match_card.dart';
export 'components/viewer_individual_player_card.dart';
export 'components/viewer_match_list_search_bar.dart';
export 'components/viewer_match_list_tile_card.dart';
export 'components/viewer_quick_action_buttons.dart';
export 'components/viewer_settings_bottom_sheet.dart';
export 'components/viewer_share_dialog.dart';
export 'components/viewer_team_card.dart';
export 'components/viewer_tournament_info_card.dart';
export 'providers/viewer_timeline_provider.dart';
export 'providers/viewer_tournament_provider.dart';

/// 観客席専用ホーム画面
class ViewerHomeScreen extends ConsumerWidget {
  final String tournamentId;
  const ViewerHomeScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        listenGlobalAnnouncements(
          context,
          ref,
          tournamentId,
          isStaffRoom: false,
        );
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal_viewer');
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );
    final Color bgColor = themeColors.scaffoldBackground;

    try {
      final asyncMatches = ref.watch(
        matchListByTournamentProvider(tournamentId),
      );
      final allMatchesList = List<MatchModel>.from(asyncMatches.value ?? [])
        ..sort((a, b) => a.order.compareTo(b.order));

      final uniqueInProgress = <MatchModel>[];
      final uniqueWaiting = <MatchModel>[];
      final seenMatchups = <String>{};

      for (var match in allMatchesList) {
        if (match.status == 'finished' || match.status == 'approved') continue;

        String key;
        if (match.note.contains('[リーグ戦]')) {
          final t1 = match.redName.split(':').first.trim();
          final t2 = match.whiteName.split(':').first.trim();
          final sortedTeams = [t1, t2]..sort();
          key = 'league_${match.groupName}_${sortedTeams.join("_")}';
        } else if (match.isKachinuki) {
          key = 'kachinuki_${match.groupName}';
        } else if (match.groupName != null && match.groupName!.isNotEmpty) {
          key = 'group_${match.groupName}';
        } else {
          key = 'match_${match.id}';
        }

        if (!seenMatchups.contains(key)) {
          seenMatchups.add(key);
          if (match.status == 'in_progress') {
            uniqueInProgress.add(match);
          } else if (match.status == 'waiting') {
            uniqueWaiting.add(match);
          }
        }
      }

      final sanitizedQuery = ref
          .watch(searchQueryProvider)
          .replaceAll(RegExp(r'\s+'), '')
          .toLowerCase();
      final timelineResult = ref.watch(
        safeViewerTimelineProvider(tournamentId),
      );
      final matchedGroupNames = timelineResult.matchedGroupNames;
      final matchedMatchIds = timelineResult.matchedMatchIds;
      final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];

      return PopScope(
        canPop: false,
        child: LiquidBackground(
          child: Scaffold(
            backgroundColor: AppKendoColors.transparent,
            appBar: AppHeader(
              leading: GoRouter.of(context).canPop()
                  ? IconButton(
                      icon: const Icon(
                        Icons.exit_to_app,
                        color: AppKendoColors.deepOrange,
                      ),
                      tooltip: '管理画面に戻る',
                      onPressed: () => context.pop(),
                    )
                  : null,
              title: '大会ホーム (観客席)',
              backgroundColor: enableLiquidGlass
                  ? AppKendoColors.transparent
                  : (context.appColors.cardBackground),
              actions: [
                NotificationBellButton(
                  tournamentId: tournamentId,
                  isStaffRoom: false,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : themeColors.primaryAccent,
                ),
                ManualHelpButton(
                  manualPath: 'docs/manuals/faq/viewer_faq.md',
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : themeColors.primaryAccent,
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : themeColors.primaryAccent,
                  ),
                  tooltip: '表示設定',
                  onPressed: () {
                    showAppBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const ViewerSettingsBottomSheet(),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.qr_code_2,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : themeColors.primaryAccent,
                  ),
                  tooltip: '大会を共有する',
                  onPressed: () => ViewerShareDialog.show(
                    context,
                    tournamentId: tournamentId,
                    dojoId: ref.read(currentDojoIdProvider),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            body: Column(
              children: [
                ViewerCallBanner(
                  inProgressMatches: uniqueInProgress,
                  waitingMatches: uniqueWaiting,
                ),
                ViewerQuickActionButtons(
                  tournamentId: tournamentId,
                  enableLiquidGlass: enableLiquidGlass,
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.giant * 2,
                    ),
                    children: [
                      ref
                          .watch(viewerTournamentProvider(tournamentId))
                          .when(
                            data: (tournament) {
                              if (tournament != null) {
                                return ViewerTournamentInfoCard(
                                  tournament: tournament,
                                );
                              }
                              final dojoId = ref.watch(currentDojoIdProvider);
                              return Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF161618)
                                        : context.appColors.inputBackground,
                                    borderRadius: AppRadius.medium,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF38383A)
                                          : const Color(0x33000000),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '大会情報が見つかりません',
                                        style: TextStyle(
                                          fontWeight: AppFontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text('大会ID: $tournamentId'),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text('現在の dojoId: $dojoId'),
                                      const SizedBox(height: AppSpacing.sm),
                                      const Text(
                                        '原因候補: 道場IDが一致しない、または大会が他パスに存在します。管理者に確認してください。',
                                        style: TextStyle(
                                          color: AppKendoColors.grey,
                                          fontSize: AppFontSize.small,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.lg),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, s) => Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF161618)
                                      : const Color(0xFFFFFFFF),
                                  borderRadius: AppRadius.medium,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF38383A)
                                        : const Color(0x33000000),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '大会情報の読み込みに失敗しました',
                                      style: TextStyle(
                                        fontWeight: AppFontWeight.bold,
                                        color: AppKendoColors.red,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text('$e'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ViewerMatchListSearchBar(
                        isSearchVisible: ref.watch(isSearchVisibleProvider),
                        searchQuery: ref.watch(searchQueryProvider),
                        isSortAscending: ref.watch(categorySortProvider),
                        onSearchQueryChanged: (val) {
                          ref.read(searchQueryProvider.notifier).state = val;
                        },
                        onOpenSearch: () {
                          ref.read(isSearchVisibleProvider.notifier).state =
                              true;
                        },
                        onCloseSearch: () {
                          ref.read(searchQueryProvider.notifier).state = '';
                          ref.read(isSearchVisibleProvider.notifier).state =
                              false;
                        },
                        onToggleSort: () {
                          ref.read(categorySortProvider.notifier).state = !ref
                              .read(categorySortProvider);
                        },
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
                                  timelineResult.errorMessage ??
                                      '通信状況を確認してください',
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
                      if (timelineResult.entries.isEmpty &&
                          sanitizedQuery.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: Center(
                            child: Text(
                              '該当する試合が見つかりません',
                              style: TextStyle(color: AppKendoColors.grey),
                            ),
                          ),
                        ),
                      if (timelineResult.entries.isEmpty &&
                          timelineResult.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (timelineResult.entries.isEmpty &&
                          !timelineResult.isLoading &&
                          sanitizedQuery.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: Center(
                            child: Text(
                              'まだ試合が登録されていません',
                              style: TextStyle(
                                color: AppKendoColors.grey,
                                fontWeight: AppFontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ViewerCategorySectionList(
                        entries: timelineResult.entries,
                        ownTeams: ownTeams,
                        sanitizedQuery: sanitizedQuery,
                        matchedMatchIds: matchedMatchIds,
                        matchedGroupNames: matchedGroupNames,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, stack) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text(
            '致命的なUIエラー: $e\n$stack',
            style: const TextStyle(color: AppKendoColors.red),
          ),
        ),
      );
    }
  }
}
