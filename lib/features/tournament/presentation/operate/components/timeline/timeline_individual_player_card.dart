import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_inner_comment_widget.dart';

import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_reorder_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/quick_next_match_wizard_sheet.dart';
import 'package:kendo_os/shared/presentation/widgets/app_slidable_action.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// タイムライン内の個人戦・個別試合アコーディオンカード
class TimelineIndividualPlayerCard extends ConsumerWidget {
  final String playerName;
  final List<MatchModel> playerMatches;
  final List<MatchCommentModel> playerComments;
  final String categoryName;
  final String teamName;
  final Widget? headerWidget;
  final String? tournamentId;
  final bool isReadOnlyUI;
  final bool isDark;
  final PermissionState permissions;
  final String sanitizedQuery;

  const TimelineIndividualPlayerCard({
    super.key,
    required this.playerName,
    required this.playerMatches,
    required this.playerComments,
    required this.categoryName,
    required this.teamName,
    this.headerWidget,
    this.tournamentId,
    required this.isReadOnlyUI,
    required this.isDark,
    required this.permissions,
    this.sanitizedQuery = '',
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

    final canDelete =
        (permissions.canDeleteData || permissions.canManageTournament) &&
        !isReadOnlyUI;

    final cardBody = Container(
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
              searchQuery: sanitizedQuery,
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
                    .asMap()
                    .entries
                    .map<Widget?>((entry) {
                      final i = entry.value;
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
                            index: entry.key,
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

    final canAddNext = !isReadOnlyUI && playerMatches.isNotEmpty;
    final canEdit = !isReadOnlyUI && playerMatches.isNotEmpty;
    final enableSlidable = canAddNext || canEdit || canDelete;
    final int actionCount =
        (canAddNext ? 1 : 0) + (canEdit ? 1 : 0) + (canDelete ? 1 : 0);
    final double extentRatio = actionCount == 3
        ? 0.68
        : (actionCount == 2 ? 0.46 : 0.25);

    final slidableCard = enableSlidable
        ? Slidable(
            key: ValueKey('player_slidable_$playerName'),
            enabled: enableSlidable,
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: extentRatio,
              children: [
                if (canAddNext)
                  AppSlidableAction(
                    onPressed: (context) {
                      QuickNextMatchWizardSheet.show(
                        context,
                        baseMatch: playerMatches.first,
                        teamMatches: playerMatches,
                      );
                    },
                    backgroundColor: AppKendoColors.teal,
                    icon: Icons.playlist_add,
                    label: '次戦追加',
                  ),
                if (canEdit)
                  AppSlidableAction(
                    onPressed: (context) {
                      showAppBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) {
                          return MatchEditSheet(
                            matches: playerMatches,
                            tournamentId: tournamentId,
                            themeColors: AppThemeColors.ofMode(
                              isDark:
                                  Theme.of(context).brightness ==
                                  Brightness.dark,
                              mode: 'operate',
                            ),
                          );
                        },
                      );
                    },
                    backgroundColor: AppKendoColors.blueAccent,
                    icon: Icons.edit,
                    label: '編集',
                  ),
                if (canDelete)
                  AppSlidableAction(
                    onPressed: (context) async {
                      final confirm = await showAppDialog<bool>(
                        context: context,
                        builder: (ctx) => AppDialog(
                          backgroundColor: isDark
                              ? const Color(0xFF1C1C1E)
                              : context.appColors.inputBackground,
                          titleWidget: Text(
                            '試合削除の確認',
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                            ),
                          ),
                          content: Text(
                            '「$playerName」の全試合データ（${playerMatches.length}件）を完全に削除します。\nよろしいですか？',
                            style: TextStyle(
                              color: context.appColors.textColor,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('キャンセル'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.appColors.errorColor,
                                foregroundColor: AppKendoColors.pureWhite,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('全削除する'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final targetIds = playerMatches
                            .map((m) => m.id)
                            .where((id) => id.isNotEmpty)
                            .toList();
                        if (targetIds.isNotEmpty) {
                          await ref
                              .read(matchCommandProvider)
                              .deleteMatchesBulk(targetIds);
                        }
                      }
                    },
                    backgroundColor: context.appColors.errorColor,
                    icon: Icons.delete,
                    label: '削除',
                  ),
              ],
            ),
            child: cardBody,
          )
        : cardBody;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [?headerWidget, slidableCard],
    );
  }
}
