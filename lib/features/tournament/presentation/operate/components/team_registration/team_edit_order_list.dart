import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// チーム編集ボトムシート: オーダー一覧ウィジェット（ドラッグ＆ドロップ並び替え対応）
class TeamEditOrderList extends StatelessWidget {
  final int totalCount;
  final int baseCount;
  final List<String> posNames;
  final Map<int, String> tempSelectedPlayers;
  final List<String> slotKeys;
  final AppThemeColors themeColors;
  final Color borderColor;
  final Color inputBgColor;
  final void Function(int index) onSelectPlayer;
  final void Function(int index)? onClearPlayer;
  final void Function(int index) onRemoveSubstitute;
  final void Function(int oldIndex, int newIndex) onReorder;

  const TeamEditOrderList({
    super.key,
    required this.totalCount,
    required this.baseCount,
    required this.posNames,
    required this.tempSelectedPlayers,
    required this.slotKeys,
    required this.themeColors,
    required this.borderColor,
    required this.inputBgColor,
    required this.onSelectPlayer,
    this.onClearPlayer,
    required this.onRemoveSubstitute,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;
    final accentColor = themeColors.primaryAccent;

    return Material(
      color: inputBgColor,
      borderRadius: BorderRadius.circular(AppRadius.mediumValue),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.mediumValue),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: totalCount,
          // ignore: deprecated_member_use
          onReorder: onReorder,
          itemBuilder: (context, index) {
            final bool isSubstitute = index >= baseCount;
            final playerName = tempSelectedPlayers[index];
            final pos = index < posNames.length ? posNames[index] : '選手';
            final keyString = index < slotKeys.length
                ? slotKeys[index]
                : 'slot_fallback_$index';

            return Column(
              key: ValueKey(keyString),
              children: [
                ListTile(
                  onTap: () => onSelectPlayer(index),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: isSubstitute
                        ? (isDark
                              ? const Color(0xFFFF9800).withValues(alpha: 0.2)
                              : const Color(0xFFFFF3E0))
                        : themeColors.softAccent,
                    child: Text(
                      isSubstitute ? '補' : pos.substring(0, 1),
                      style: TextStyle(
                        color: isSubstitute
                            ? (isDark
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFFE65100))
                            : accentColor,
                        fontWeight: AppFontWeight.bold,
                        fontSize: AppFontSize.caption,
                      ),
                    ),
                  ),
                  title: Text(
                    playerName ?? '未選択（タップして設定）',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: playerName != null
                          ? AppFontWeight.bold
                          : AppFontWeight.regular,
                      color: playerName != null ? textColor : subTextColor,
                    ),
                  ),
                  subtitle: Text(
                    pos,
                    style: TextStyle(
                      color: isSubstitute
                          ? (isDark
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFFE65100))
                          : accentColor,
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSubstitute)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppKendoColors.redAccent,
                            size: 20,
                          ),
                          tooltip: '補欠枠を削除',
                          onPressed: () => onRemoveSubstitute(index),
                        ),
                      const SizedBox(width: AppSpacing.xs),
                      ReorderableDragStartListener(
                        index: index,
                        child: Tooltip(
                          message: 'ドラッグして並び替え',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.sm,
                            ),
                            child: Icon(
                              Icons.drag_handle,
                              color: subTextColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < totalCount - 1)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: borderColor.withValues(alpha: 0.5),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
