import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_sort_helper.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 🥋 チーム試合状況の並び替え（ソート）切り替えチップバー
class TeamMatchSortBar extends StatelessWidget {
  final TeamSortType currentSort;
  final ValueChanged<TeamSortType> onSortChanged;
  final bool isDark;

  const TeamMatchSortBar({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swap_vert_rounded,
                size: 14,
                color: context.appColors.subTextColor,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '並び替え:',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.subTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
          AppChoiceChip(
            label: const Text('⚡ 進行状況順'),
            selected: currentSort == TeamSortType.status,
            onSelected: (selected) {
              if (selected) onSortChanged(TeamSortType.status);
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          AppChoiceChip(
            label: const Text('🏟️ 試合会場順'),
            selected: currentSort == TeamSortType.court,
            onSelected: (selected) {
              if (selected) onSortChanged(TeamSortType.court);
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          AppChoiceChip(
            label: const Text('🔢 試合順'),
            selected: currentSort == TeamSortType.matchOrder,
            onSelected: (selected) {
              if (selected) onSortChanged(TeamSortType.matchOrder);
            },
          ),
        ],
      ),
    );
  }
}
