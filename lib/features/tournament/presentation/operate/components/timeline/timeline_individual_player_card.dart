import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_inner_comment_widget.dart';

import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_reorder_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
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

    final firstMatch = playerMatches.first;
    final scenePrefix = TeamProgressHelper.getScenePrefix(firstMatch);
    final rawLabel =
        (!firstMatch.isKachinuki &&
            (firstMatch.matchType.contains('個人') ||
                firstMatch.matchType == 'individual' ||
                firstMatch.matchType == '選手'))
        ? (firstMatch.note.contains('[リーグ戦]') ||
                  firstMatch.matchType.contains('リーグ')
              ? '個人戦/リーグ戦'
              : '個人戦')
        : (firstMatch.isKachinuki
              ? '団体戦/勝ち抜き戦'
              : (firstMatch.note.contains('[リーグ戦]') ||
                        firstMatch.matchType.contains('リーグ')
                    ? '団体戦/リーグ戦'
                    : '団体戦'));
    final label = scenePrefix.isNotEmpty ? '$scenePrefix$rawLabel' : rawLabel;
    final bool pInProgress = playerMatches.any(
      (m) => m.status == 'in_progress',
    );
    final bool pAllFinished = playerMatches.every(
      (m) => m.status == 'finished' || m.status == 'approved',
    );
    final Color pTitleColor = pAllFinished
        ? (context.appColors.subTextColor)
        : (context.appColors.textColor);
    final Color pSubTitleColor = context.appColors.subTextColor;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
          width: 1,
        ),
        boxShadow: pInProgress
            ? [
                BoxShadow(
                  color: AppKendoColors.blue.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.smooth,
        child: ExpansionTileTheme(
          data: ExpansionTileThemeData(
            backgroundColor: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
            collapsedBackgroundColor: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFAFAFC),
            iconColor: isDark
                ? context.appColors.primaryAccent
                : context.appColors.primaryAccent,
            collapsedIconColor: AppKendoColors.grey,
            textColor: context.appColors.textColor,
            collapsedTextColor: isDark
                ? context.appColors.textColor.withValues(alpha: 0.7)
                : context.appColors.cardBackground.withValues(alpha: 0.54),
          ),
          child: ExpansionTile(
            key: ValueKey('player_$playerName'),
            shape: const Border(),
            collapsedShape: const Border(),
            childrenPadding: EdgeInsets.zero,
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            leading: CircleAvatar(
              backgroundColor: pAllFinished
                  ? (context.appColors.separatorColor)
                  : context.appColors.warningColor,
              child: Text(
                playerName.isNotEmpty ? playerName[0] : '?',
                style: TextStyle(
                  color: pAllFinished
                      ? (isDark
                            ? const Color(0xFF9E9E9E)
                            : const Color(0xFF757575))
                      : AppKendoColors.pureWhite,
                  fontSize: AppFontSize.small,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
            title: Text(
              playerName,
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.bodyMedium,
                color: pTitleColor,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  '$label • ${playerMatches.length}試合',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: pSubTitleColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.subValue,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: pInProgress
                        ? const Color(0xFF2196F3)
                        : (pAllFinished
                              ? (isDark
                                    ? const Color(0xFF424242)
                                    : const Color(0xFFE0E0E0))
                              : (isDark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFEEEEEE))),
                    borderRadius: AppRadius.tiny,
                  ),
                  child: Text(
                    pInProgress ? '進行中' : (pAllFinished ? '終了' : '待機中'),
                    style: TextStyle(
                      fontSize: AppFontSize.badge,
                      fontWeight: AppFontWeight.bold,
                      color: pInProgress
                          ? AppKendoColors.pureWhite
                          : (pAllFinished
                                ? (isDark
                                      ? const Color(0xFFBDBDBD)
                                      : const Color(0xFF757575))
                                : (isDark
                                      ? const Color(0xFFBDBDBD)
                                      : const Color(0xFF616161))),
                    ),
                  ),
                ),
              ],
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
