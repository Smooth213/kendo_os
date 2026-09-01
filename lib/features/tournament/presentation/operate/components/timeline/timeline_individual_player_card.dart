import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_inner_comment_widget.dart';

import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_reorder_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// タイムライン内の個人戦・個別試合アコーディオンカード
class TimelineIndividualPlayerCard extends ConsumerWidget {
  final String playerName;
  final List<MatchModel> playerMatches;
  final List<MatchCommentModel> playerComments;
  final String categoryName;
  final String teamName;
  final bool isReadOnlyUI;
  final bool isDark;
  final PermissionState permissions;

  const TimelineIndividualPlayerCard({
    super.key,
    required this.playerName,
    required this.playerMatches,
    required this.playerComments,
    required this.categoryName,
    required this.teamName,
    required this.isReadOnlyUI,
    required this.isDark,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerMixedItems = <TimelineItem>[
      ...playerMatches,
      ...playerComments,
    ];
    // ★ あとから追加した試合（おかわりの試合）が上に来るよう降順ソート
    playerMixedItems.sort((a, b) => b.timelineOrder.compareTo(a.timelineOrder));

    final bool pInProgress = playerMatches.any(
      (m) => m.status == 'in_progress',
    );
    final bool pAllFinished = playerMatches.every(
      (m) => m.status == 'finished' || m.status == 'approved',
    );
    final Color pTitleColor = pAllFinished
        ? (context.appColors.subTextColor)
        : (context.appColors.textColor);

    final Color cardBg = pAllFinished
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
        : (isDark ? context.appColors.cardBackground : const Color(0xFFFFFFFF));
    final Color collapsedCardBg = pAllFinished
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
        : (isDark ? context.appColors.cardBackground : const Color(0xFFFAFAFC));

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: pInProgress
              ? AppKendoColors.hansokuRed.withValues(alpha: 0.6)
              : (isDark
                    ? const Color(0xFF2C2C2E)
                    : context.appColors.separatorColor),
          width: pInProgress ? 1.5 : 1.0,
        ),
        boxShadow: pInProgress
            ? [
                BoxShadow(
                  color: AppKendoColors.hansokuRed.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.smooth,
        child: ExpansionTileTheme(
          data: ExpansionTileThemeData(
            backgroundColor: cardBg,
            collapsedBackgroundColor: collapsedCardBg,
            iconColor: context.appColors.primaryAccent,
            collapsedIconColor: context.appColors.subTextColor,
            textColor: context.appColors.textColor,
            collapsedTextColor: isDark
                ? AppKendoColors.pureWhite.withValues(alpha: 0.7)
                : AppKendoColors.pureBlack.withValues(alpha: 0.54),
          ),
          child: ExpansionTile(
            key: ValueKey('player_$playerName'),
            shape: const Border(),
            collapsedShape: const Border(),
            childrenPadding: EdgeInsets.zero,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            title: TimelineIndividualPlayerHeader(
              playerName: playerName,
              playerMatches: playerMatches,
              isDark: isDark,
              isReadOnlyUI: isReadOnlyUI,
              titleColor: pTitleColor,
            ),
            children: [
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                        return Container(
                          key: ValueKey(i.id),
                          child: MatchListTileCard(
                            initialMatch: i,
                            isDeletable: true,
                          ),
                        );
                      } else if (i is MatchCommentModel) {
                        return Container(
                          key: ValueKey('inner_comment_${i.id}'),
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
                    .whereType<Widget>()
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
