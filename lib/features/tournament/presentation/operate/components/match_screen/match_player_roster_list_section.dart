import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_selection_card.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 道場名簿一覧セクション（出場中・同カテゴリ控え・他カテゴリ選手）
class MatchPlayerRosterListSection extends StatelessWidget {
  final List<PlayerModel> sameCatActive;
  final List<PlayerModel> dojoListSubstitutes;
  final List<PlayerModel> otherCategoryPlayers;
  final Set<String> activePlayerNames;
  final Map<String, String> playerPositions;
  final String currentPlayerName;
  final void Function(PlayerModel player, bool isSub) onPlayerSelected;

  const MatchPlayerRosterListSection({
    super.key,
    required this.sameCatActive,
    required this.dojoListSubstitutes,
    required this.otherCategoryPlayers,
    required this.activePlayerNames,
    required this.playerPositions,
    required this.currentPlayerName,
    required this.onPlayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (sameCatActive.isEmpty &&
        dojoListSubstitutes.isEmpty &&
        otherCategoryPlayers.isEmpty) {
      return const Center(
        child: Text(
          '名簿に登録されている選手がいません',
          style: TextStyle(color: AppKendoColors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (sameCatActive.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              '出場中の選手 (交代・スワップ)',
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.bold,
                color: Color(0xFFFF9800),
              ),
            ),
          ),
          ...sameCatActive.map(
            (p) => MatchPlayerSelectionCard(
              player: p,
              isSub: false,
              isCurrentPosition: p.name == currentPlayerName,
              currentPosition: playerPositions[p.name],
              onTap: () => onPlayerSelected(p, false),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (dojoListSubstitutes.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              '同カテゴリの控え選手',
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.bold,
                color: Color(0xFF009688),
              ),
            ),
          ),
          ...dojoListSubstitutes.map(
            (p) => MatchPlayerSelectionCard(
              player: p,
              isSub: true,
              isCurrentPosition: p.name == currentPlayerName,
              currentPosition: playerPositions[p.name],
              onTap: () => onPlayerSelected(p, true),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        Theme(
          data: Theme.of(
            context,
          ).copyWith(dividerColor: AppKendoColors.transparent),
          child: ExpansionTile(
            title: Text(
              '他のカテゴリの選手を表示',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
                color: context.appColors.primaryAccent,
              ),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            children: [
              if (otherCategoryPlayers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      '他のカテゴリに選手はいません',
                      style: TextStyle(color: AppKendoColors.grey),
                    ),
                  ),
                )
              else
                ...otherCategoryPlayers.map((p) {
                  final isSub = !activePlayerNames.contains(p.name);
                  return MatchPlayerSelectionCard(
                    player: p,
                    isSub: isSub,
                    isCurrentPosition: p.name == currentPlayerName,
                    currentPosition: playerPositions[p.name],
                    onTap: () => onPlayerSelected(p, isSub),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
