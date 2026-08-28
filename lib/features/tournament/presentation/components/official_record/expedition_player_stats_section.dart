import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 選手別成績一覧セクション（団体戦・個人戦・通算対応）
class ExpeditionPlayerStatsSection extends StatefulWidget {
  final Map<String, DetailedPlayerStats> playerStatsMap;
  final bool isDark;

  const ExpeditionPlayerStatsSection({
    super.key,
    required this.playerStatsMap,
    required this.isDark,
  });

  @override
  State<ExpeditionPlayerStatsSection> createState() =>
      _ExpeditionPlayerStatsSectionState();
}

class _ExpeditionPlayerStatsSectionState
    extends State<ExpeditionPlayerStatsSection> {
  String _selectedCategory = 'all'; // 'all', 'team', 'individual'

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final statsMap = widget.playerStatsMap;

    final hasTeamStats = statsMap.values.any(
      (st) => (st.teamWin + st.teamLoss + st.teamDraw) > 0,
    );
    final hasIndividualStats = statsMap.values.any(
      (st) => (st.individualWin + st.individualLoss + st.individualDraw) > 0,
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // フィルター切り替え（個人戦・団体戦の双方が存在する場合）
          if (hasTeamStats && hasIndividualStats) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', '通算 (総合)'),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterChip('team', '団体戦のみ'),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterChip('individual', '個人戦のみ'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          Text(
            '※タップで個人カルテ（技内訳・対戦履歴）を表示',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: AppKendoColors.grey.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: statsMap.entries.map((entry) {
              final pName = entry.key;
              final st = entry.value;

              int displayWin = st.win;
              int displayLoss = st.loss;
              int displayDraw = st.draw;
              int displayPoints = st.totalPoints;

              if (_selectedCategory == 'team') {
                displayWin = st.teamWin;
                displayLoss = st.teamLoss;
                displayDraw = st.teamDraw;
                displayPoints = st.teamPoints;
              } else if (_selectedCategory == 'individual') {
                displayWin = st.individualWin;
                displayLoss = st.individualLoss;
                displayDraw = st.individualDraw;
                displayPoints = st.individualPoints;
              }

              final bool hasPlayedInSelected =
                  (displayWin + displayLoss + displayDraw) > 0 ||
                  displayPoints > 0;
              if (!hasPlayedInSelected && _selectedCategory != 'all') {
                return const SizedBox.shrink();
              }

              return InkWell(
                onTap: () {
                  ExpeditionDetailBottomSheet.showPlayerDetail(
                    context: context,
                    isDark: isDark,
                    playerName: pName,
                    stats: st,
                  );
                },
                borderRadius: AppRadius.medium,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFFFFFFF).withValues(alpha: 0.15)
                          : const Color(0xFF000000).withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$pName: $displayWin勝$displayLoss敗${displayDraw > 0 ? "$displayDraw分" : ""}',
                        style: TextStyle(
                          fontSize: AppFontSize.small,
                          fontWeight: AppFontWeight.bold,
                          color: context.appColors.textColor,
                        ),
                      ),
                      if (displayPoints > 0) ...[
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '($displayPoints本)',
                          style: const TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.bold,
                            color: AppKendoColors.indigo,
                          ),
                        ),
                      ],
                      // 通算表示時で個人戦もある場合、内訳のヒントを表示
                      if (_selectedCategory == 'all' &&
                          hasTeamStats &&
                          hasIndividualStats &&
                          (st.individualWin + st.individualLoss > 0)) ...[
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '(団${st.teamWin}/個${st.individualWin})',
                          style: TextStyle(
                            fontSize: AppFontSize.badge,
                            color: context.appColors.subTextColor,
                            fontWeight: AppFontWeight.semiBold,
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.xxs),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppKendoColors.grey.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return AppChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSize.caption,
          fontWeight: isSelected ? AppFontWeight.bold : AppFontWeight.regular,
        ),
      ),
      selected: isSelected,
      selectedColor: AppKendoColors.indigo,
      backgroundColor: widget.isDark
          ? const Color(0xFF38383A)
          : const Color(0xFFE5E5EA),
      onSelected: (_) => setState(() => _selectedCategory = category),
    );
  }
}
