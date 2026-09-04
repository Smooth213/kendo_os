import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_status_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

enum TeamFilterType { all, liveOnly, waitingOnly }

/// 🥋 指導者・保護者・生徒向け「チーム試合状況」画面
class TeamMatchStatusScreen extends ConsumerStatefulWidget {
  final String? tournamentId;
  final bool isBottomSheet;
  final VoidCallback? onFullScreen;

  const TeamMatchStatusScreen({
    super.key,
    this.tournamentId,
    this.isBottomSheet = false,
    this.onFullScreen,
  });

  static Future<void> showAsBottomSheet(
    BuildContext context, {
    required String tournamentId,
    bool isViewerMode = false,
  }) {
    final viewerParam = isViewerMode ? '&role=viewer' : '';
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppKendoColors.transparent,
      builder: (context) => TeamMatchStatusScreen(
        tournamentId: tournamentId,
        isBottomSheet: true,
        onFullScreen: () {
          Navigator.of(context).pop();
          context.push('/court-status?tournamentId=$tournamentId$viewerParam');
        },
      ),
    );
  }

  @override
  ConsumerState<TeamMatchStatusScreen> createState() =>
      _TeamMatchStatusScreenState();
}

class _TeamMatchStatusScreenState extends ConsumerState<TeamMatchStatusScreen> {
  TeamFilterType _filter = TeamFilterType.all;
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final teamList = ref.watch(teamProgressListProvider);

    final totalLiveCount = teamList.where((t) => t.hasLiveMatch).length;
    final totalWaitingCount = teamList
        .where((t) => !t.hasLiveMatch && !t.isFinished)
        .length;

    // カテゴリリストの抽出
    final rawCategories = teamList
        .map(
          (t) =>
              t.categoryName.isNotEmpty ? t.categoryName : t.currentCourtName,
        )
        .where((cat) => cat.isNotEmpty)
        .toSet()
        .toList();
    final categories = ['すべて', ...rawCategories];

    // 現在のインデックスが範囲外にならないようクランプ
    if (_currentIndex >= categories.length) {
      _currentIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }

    // フィルタリング（ステータス）
    final statusFilteredTeams = teamList.where((t) {
      switch (_filter) {
        case TeamFilterType.all:
          return true;
        case TeamFilterType.liveOnly:
          return t.hasLiveMatch;
        case TeamFilterType.waitingOnly:
          return !t.hasLiveMatch && !t.isFinished;
      }
    }).toList();

    final permissions = ref.watch(permissionProvider);
    final isReadOnly = permissions.isReadOnly;

    final effectiveTournamentId =
        (widget.tournamentId != null && widget.tournamentId!.isNotEmpty)
        ? widget.tournamentId!
        : (ref.watch(currentTournamentIdProvider).isNotEmpty
              ? ref.watch(currentTournamentIdProvider)
              : (ref.watch(webCurrentTournamentIdProvider) ?? ''));

    final content = Column(
      children: [
        if (widget.isBottomSheet)
          DockBottomSheetHeader(
            title: 'チーム試合状況',
            icon: Icons.groups_rounded,
            iconColor: AppKendoColors.indigo,
            onFullScreen: widget.onFullScreen,
          ),
        // iOS風サマリーヘッダー & フィルターバー & カテゴリタブ
        _buildSummaryAndFilterBar(
          context,
          isDark,
          totalLiveCount,
          totalWaitingCount,
          teamList,
          statusFilteredTeams,
          categories,
        ),
        Divider(
          height: 1,
          thickness: 0.8,
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        ),

        // 🥋 スワイプ可能なチーム一覧 PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: categories.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, catIndex) {
              final currentCat = categories[catIndex];
              final filteredList = statusFilteredTeams.where((t) {
                if (currentCat != 'すべて') {
                  final cat = t.categoryName.isNotEmpty
                      ? t.categoryName
                      : t.currentCourtName;
                  if (cat != currentCat) return false;
                }
                return true;
              }).toList();

              if (filteredList.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                key: PageStorageKey('team_status_list_$currentCat'),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.xs,
                ),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final teamStatus = filteredList[index];
                  return TeamStatusCard(status: teamStatus, isDark: isDark);
                },
              );
            },
          ),
        ),
      ],
    );

    if (widget.isBottomSheet) {
      return DockDraggableSheet(
        backgroundColor: themeColors.scaffoldBackground,
        builder: (context, scrollController) => content,
      );
    }

    return Scaffold(
      backgroundColor: themeColors.scaffoldBackground,
      appBar: const AppHeader(title: 'チーム試合状況'),
      body: Stack(
        children: [
          content,
          if (effectiveTournamentId.isNotEmpty)
            FloatingProgramDockButton(
              tournamentId: effectiveTournamentId,
              isViewerMode: isReadOnly,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndFilterBar(
    BuildContext context,
    bool isDark,
    int liveCount,
    int waitingCount,
    List<TeamProgressStatus> allTeams,
    List<TeamProgressStatus> statusFilteredTeams,
    List<String> categories,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カウンターバッジ行
          Row(
            children: [
              _buildMetricBadge(
                label: '全試合',
                count: allTeams.length,
                color: context.appColors.primaryAccent,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildMetricBadge(
                label: '🔴 試合中 (LIVE)',
                count: liveCount,
                color: AppKendoColors.hansokuRed,
                highlight: liveCount > 0,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildMetricBadge(
                label: '⏳ 待機中',
                count: waitingCount,
                color: AppKendoColors.indigo,
                highlight: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // フィルターチップ行（ステータス）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppChoiceChip(
                  label: const Text('すべて表示'),
                  selected: _filter == TeamFilterType.all,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filter = TeamFilterType.all);
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                AppChoiceChip(
                  label: Text('🔴 試合中のみ ($liveCount)'),
                  selected: _filter == TeamFilterType.liveOnly,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filter = TeamFilterType.liveOnly);
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                AppChoiceChip(
                  label: Text('⏳ 待機中のみ ($waitingCount)'),
                  selected: _filter == TeamFilterType.waitingOnly,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filter = TeamFilterType.waitingOnly);
                    }
                  },
                ),
              ],
            ),
          ),

          // 🏷️ カテゴリ別アンダーラインタブバー（タップ & スワイプ連動）
          if (categories.length > 1) ...[
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(categories.length, (index) {
                  final cat = categories[index];
                  final isSelected = _currentIndex == index;
                  final count = cat == 'すべて'
                      ? statusFilteredTeams.length
                      : statusFilteredTeams.where((t) {
                          final cCat = t.categoryName.isNotEmpty
                              ? t.categoryName
                              : t.currentCourtName;
                          return cCat == cat;
                        }).length;

                  final labelText = cat == 'すべて'
                      ? '全カテゴリ ($count)'
                      : '$cat ($count)';

                  final activeColor = isDark
                      ? context.appColors.primaryAccent
                      : AppKendoColors.indigo;
                  final unselectedColor = context.appColors.subTextColor;

                  return InkWell(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: AppRadius.small,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? activeColor
                                : AppKendoColors.transparent,
                            width: 3.0,
                          ),
                        ),
                      ),
                      child: Text(
                        labelText,
                        style: TextStyle(
                          fontSize: AppFontSize.bodySmall,
                          fontWeight: isSelected
                              ? AppFontWeight.bold
                              : AppFontWeight.medium,
                          color: isSelected ? activeColor : unselectedColor,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricBadge({
    required String label,
    required int count,
    required Color color,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: highlight ? color : color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count',
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 48,
            color: context.appColors.subTextColor,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '該当するチームの試合はありません',
            style: TextStyle(
              fontSize: AppFontSize.bodyMedium,
              color: context.appColors.subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
