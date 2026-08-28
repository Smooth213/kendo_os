import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_inner_comment_widget.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_reorder_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_tie_break_detector.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_tie_break_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// タイムライン試合グループのアコーディオン展開内部コンポーネントビルダー
class TimelineGroupChildrenBuilder {
  static List<Widget> buildChildren({
    required BuildContext context,
    required WidgetRef ref,
    required List<MatchModel> groupList,
    required List<MatchCommentModel> groupComments,
    required String label,
    required bool isReadOnlyUI,
    required bool isDark,
    required PermissionState permissions,
    required MatchRule rule,
    required MatchModel firstMatch,
  }) {
    // 🌟 団体戦アコーディオン内の順序：
    // 基本ポジション（先鋒〜大将） ➔ 代表戦 ➔ 後から追加した試合（お代わり試合など）
    final baseMatches = <MatchModel>[];
    final appendedMatches = <MatchModel>[];

    for (final m in groupList) {
      final bool isAppended =
          m.matchType == '代表戦' ||
          m.matchType == '順位決定戦' ||
          m.matchType.contains('追加') ||
          m.note.contains('追加');

      if (isAppended) {
        appendedMatches.add(m);
      } else {
        baseMatches.add(m);
      }
    }

    baseMatches.sort((a, b) => a.order.compareTo(b.order));
    appendedMatches.sort((a, b) => a.order.compareTo(b.order));

    // ★ 表示順：先鋒〜大将 ➔ 代表戦 ➔ 追加試合（大将の後に自然に追加）
    final orderedMatches = [...baseMatches, ...appendedMatches];

    final normalItems = <dynamic>[...orderedMatches, ...groupComments];

    final childrenWidgets = <Widget>[const Divider(height: 1)];

    if (label.contains('リーグ戦')) {
      final allFinished = groupList.every(
        (m) => m.status == 'finished' || m.status == 'approved',
      );
      if (allFinished) {
        final tieGroups = TimelineTieBreakDetector.detectTieGroups(
          normalMatches: baseMatches,
          rule: rule,
        );

        if (tieGroups.isNotEmpty) {
          childrenWidgets.add(
            Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFFFF9800).withValues(alpha: 0.2)
                    : const Color(0xFFFF9800),
                border: Border.all(color: context.appColors.warningColor),
                borderRadius: AppRadius.medium,
              ),
              child: Column(
                children: tieGroups.map((group) {
                  return ElevatedButton.icon(
                    onPressed: () => TimelineTieBreakDialog.show(
                      context,
                      ref,
                      firstMatch,
                      group,
                      rule,
                    ),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('順位決定戦を作成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.warningColor,
                      foregroundColor: AppKendoColors.pureWhite,
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }
      }
    }

    if (label.contains('リーグ戦') && label.contains('個人戦')) {
      childrenWidgets.add(
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: !isReadOnlyUI,
          onReorderItem: (oldIndex, newIndex) =>
              TimelineReorderHelper.onReorderInnerTimeline(
                normalItems.cast<TimelineItem>(),
                oldIndex,
                newIndex,
                ref,
              ),
          children: normalItems
              .map<Widget?>((i) {
                if (i is MatchModel) {
                  return Container(
                    key: ValueKey(i.id),
                    child: MatchListTileCard(
                      key: ValueKey(i.id),
                      initialMatch: i,
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
      );
    } else {
      childrenWidgets.addAll(
        orderedMatches.map(
          (m) => MatchListTileCard(key: ValueKey(m.id), initialMatch: m),
        ),
      );
    }

    return childrenWidgets;
  }
}
