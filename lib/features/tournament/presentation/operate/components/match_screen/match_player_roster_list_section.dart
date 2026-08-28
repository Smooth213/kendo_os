import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_selection_card.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 道場名簿一覧セクション（出場中・同カテゴリ控え・他カテゴリ選手）
class MatchPlayerRosterListSection extends StatelessWidget {
  final List<PlayerModel> sameCatActive;
  final List<PlayerModel> dojoListSubstitutes;
  final List<PlayerModel> otherCategoryPlayers;
  final Set<String> activePlayerNames;
  final Map<String, String> playerPositions;
  final String currentPlayerName;
  final void Function(PlayerModel player, bool isSub) onPlayerSelected;
  final VoidCallback? onOpenFullReorder;

  const MatchPlayerRosterListSection({
    super.key,
    required this.sameCatActive,
    required this.dojoListSubstitutes,
    required this.otherCategoryPlayers,
    required this.activePlayerNames,
    required this.playerPositions,
    required this.currentPlayerName,
    required this.onPlayerSelected,
    this.onOpenFullReorder,
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
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '出場中の選手 (交代・スワップ)',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.bold,
                    color: Color(0xFFFF9800),
                  ),
                ),
                if (onOpenFullReorder != null)
                  InkWell(
                    onTap: onOpenFullReorder,
                    borderRadius: AppRadius.small,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                        borderRadius: AppRadius.small,
                        border: Border.all(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.drag_handle_rounded,
                            size: 14,
                            color: Color(0xFFFF9800),
                          ),
                          SizedBox(width: 2),
                          Text(
                            '全体を並び替え',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
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
              isCurrentPosition: false,
              onTap: () => onPlayerSelected(p, true),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (otherCategoryPlayers.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              '他カテゴリの所属選手 (助っ人)',
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.bold,
                color: AppKendoColors.blueGrey,
              ),
            ),
          ),
          ...otherCategoryPlayers.map(
            (p) => MatchPlayerSelectionCard(
              player: p,
              isSub: true,
              isCurrentPosition: false,
              onTap: () => onPlayerSelected(p, true),
            ),
          ),
        ],
      ],
    );
  }
}
