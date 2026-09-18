import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// チーム編集ボトムシート: オーダー一覧ウィジェット
class TeamEditOrderList extends StatelessWidget {
  final int totalCount;
  final int baseCount;
  final List<String> posNames;
  final Map<int, String> tempSelectedPlayers;
  final AppThemeColors themeColors;
  final Color borderColor;
  final Color inputBgColor;
  final void Function(int index) onSelectPlayer;
  final void Function(int index) onClearPlayer;
  final void Function(int index) onRemoveSubstitute;

  const TeamEditOrderList({
    super.key,
    required this.totalCount,
    required this.baseCount,
    required this.posNames,
    required this.tempSelectedPlayers,
    required this.themeColors,
    required this.borderColor,
    required this.inputBgColor,
    required this.onSelectPlayer,
    required this.onClearPlayer,
    required this.onRemoveSubstitute,
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
        child: Column(
          children: List.generate(totalCount, (index) {
            final bool isSubstitute = index >= baseCount;
            final playerName = tempSelectedPlayers[index];
            final pos = index < posNames.length ? posNames[index] : '選手';

            return Column(
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
                      if (playerName != null)
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: subTextColor,
                          ),
                          tooltip: '選手をクリア',
                          onPressed: () => onClearPlayer(index),
                        ),
                      if (isSubstitute)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppKendoColors.redAccent,
                            size: 20,
                          ),
                          tooltip: '補欠枠を削除',
                          onPressed: () => onRemoveSubstitute(index),
                        )
                      else
                        Icon(
                          Icons.chevron_right,
                          color: subTextColor,
                          size: 20,
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
          }),
        ),
      ),
    );
  }
}
