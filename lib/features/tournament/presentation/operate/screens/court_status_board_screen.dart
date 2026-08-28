import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/domain/court_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/court_status_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/court_progress_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

enum CourtFilterType { all, liveOnly, myDojoOnly }

/// 🥋 指導者・保護者向けマルチコート進行ステータスボード画面
class CourtStatusBoardScreen extends ConsumerStatefulWidget {
  final String? tournamentId;

  const CourtStatusBoardScreen({super.key, this.tournamentId});

  @override
  ConsumerState<CourtStatusBoardScreen> createState() =>
      _CourtStatusBoardScreenState();
}

class _CourtStatusBoardScreenState
    extends ConsumerState<CourtStatusBoardScreen> {
  CourtFilterType _filter = CourtFilterType.all;
  String _selectedCategory = 'すべて';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courtList = ref.watch(courtProgressListProvider);

    final totalLiveCount = courtList.where((c) => c.hasLiveMatch).length;
    final totalMyDojoLiveCount = courtList
        .where((c) => c.hasMyDojoMatch)
        .length;

    // カテゴリリストの抽出
    final rawCategories = courtList
        .map((c) => c.categoryName.isNotEmpty ? c.categoryName : c.courtName)
        .where((cat) => cat.isNotEmpty)
        .toSet()
        .toList();
    final categories = ['すべて', ...rawCategories];

    // フィルタリング（ステータス ＆ カテゴリ連動）
    final statusFilteredCourts = courtList.where((c) {
      switch (_filter) {
        case CourtFilterType.all:
          return true;
        case CourtFilterType.liveOnly:
          return c.hasLiveMatch;
        case CourtFilterType.myDojoOnly:
          return c.hasMyDojoMatch;
      }
    }).toList();

    final filteredList = statusFilteredCourts.where((c) {
      if (_selectedCategory != 'すべて') {
        final cat = c.categoryName.isNotEmpty ? c.categoryName : c.courtName;
        if (cat != _selectedCategory) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: const AppHeader(title: 'マルチコート進行状況'),
      body: Column(
        children: [
          // サマリーヘッダー & フィルターバー & カテゴリタブ
          _buildSummaryAndFilterBar(
            context,
            isDark,
            totalLiveCount,
            totalMyDojoLiveCount,
            courtList,
            statusFilteredCourts,
            categories,
          ),
          const Divider(height: 1),

          // コート一覧
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.xs,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final courtStatus = filteredList[index];
                      return CourtStatusCard(
                        status: courtStatus,
                        isDark: isDark,
                      );
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
    int myDojoCount,
    List<CourtProgressStatus> allCourts,
    List<CourtProgressStatus> statusFilteredCourts,
    List<String> categories,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF9FAFB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カウンターバッジ行
          Row(
            children: [
              _buildMetricBadge(
                label: '全コート',
                count: allCourts.length,
                color: context.appColors.primaryAccent,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildMetricBadge(
                label: '🔴 試合中 (LIVE)',
                count: liveCount,
                color: AppKendoColors.hansokuRed,
                highlight: liveCount > 0,
              ),
              if (myDojoCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                _buildMetricBadge(
                  label: '⭐ 自チーム試合中',
                  count: myDojoCount,
                  color: AppKendoColors.ipponGold,
                  highlight: true,
                ),
              ],
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
                  selected: _filter == CourtFilterType.all,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filter = CourtFilterType.all);
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                AppChoiceChip(
                  label: Text('🔴 試合中のみ ($liveCount)'),
                  selected: _filter == CourtFilterType.liveOnly,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filter = CourtFilterType.liveOnly);
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                AppChoiceChip(
                  label: Text('⭐ 自チームのみ ($myDojoCount)'),
                  selected: _filter == CourtFilterType.myDojoOnly,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filter = CourtFilterType.myDojoOnly);
                    }
                  },
                ),
              ],
            ),
          ),

          // 🏷️ 【公式記録画面準拠】カテゴリ別アンダーラインタブバー
          if (categories.length > 1) ...[
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  // 🔽 上の絞り込み（statusFilteredCourts）に連動してカウントを算出！
                  final count = cat == 'すべて'
                      ? statusFilteredCourts.length
                      : statusFilteredCourts.where((c) {
                          final cCat = c.categoryName.isNotEmpty
                              ? c.categoryName
                              : c.courtName;
                          return cCat == cat;
                        }).length;

                  final labelText = cat == 'すべて'
                      ? '全カテゴリ ($count)'
                      : '$cat ($count)';

                  final activeColor = isDark
                      ? context.appColors.primaryAccent
                      : const Color(0xFF3F51B5);
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
                                : Colors.transparent,
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
            Icons.stadium_outlined,
            size: 48,
            color: context.appColors.subTextColor,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '該当するコートの試合はありません',
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
