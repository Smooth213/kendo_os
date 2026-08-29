import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_status_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

enum TeamFilterType { all, liveOnly, waitingOnly }

/// 🥋 指導者・保護者・生徒向け「チーム試合状況」画面
class TeamMatchStatusScreen extends ConsumerStatefulWidget {
  final String? tournamentId;

  const TeamMatchStatusScreen({super.key, this.tournamentId});

  @override
  ConsumerState<TeamMatchStatusScreen> createState() =>
      _TeamMatchStatusScreenState();
}

class _TeamMatchStatusScreenState extends ConsumerState<TeamMatchStatusScreen> {
  TeamFilterType _filter = TeamFilterType.all;
  String _selectedCategory = 'すべて';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final teamList = ref.watch(teamProgressListProvider);

    final totalLiveCount = teamList.where((t) => t.hasLiveMatch).length;
    final totalWaitingCount = teamList
        .where((t) => !t.hasLiveMatch && !t.isAllFinished)
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

    // フィルタリング（ステータス ＆ カテゴリ連動）
    final statusFilteredTeams = teamList.where((t) {
      switch (_filter) {
        case TeamFilterType.all:
          return true;
        case TeamFilterType.liveOnly:
          return t.hasLiveMatch;
        case TeamFilterType.waitingOnly:
          return !t.hasLiveMatch && !t.isAllFinished;
      }
    }).toList();

    final filteredList = statusFilteredTeams.where((t) {
      if (_selectedCategory != 'すべて') {
        final cat = t.categoryName.isNotEmpty
            ? t.categoryName
            : t.currentCourtName;
        if (cat != _selectedCategory) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: themeColors.scaffoldBackground,
      appBar: const AppHeader(title: 'チーム試合状況'),
      body: Column(
        children: [
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

          // チーム一覧
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.xs,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final teamStatus = filteredList[index];
                      return TeamStatusCard(status: teamStatus, isDark: isDark);
                    },
                  ),
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
                label: '登録チーム',
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

          // 🏷️ カテゴリ別アンダーラインタブバー
          if (categories.length > 1) ...[
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
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
                      setState(() => _selectedCategory = cat);
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
                }).toList(),
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
