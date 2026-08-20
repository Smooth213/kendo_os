import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 マスタ管理画面 選手一覧タイルコンポーネント（選択モード・学年・初心者バッジ・Slidable編集/削除）
class MasterPlayerTile extends StatelessWidget {
  final PlayerModel player;
  final bool isReadOnly;
  final bool canManageMaster;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTapSelection;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MasterPlayerTile({
    super.key,
    required this.player,
    required this.isReadOnly,
    required this.canManageMaster,
    required this.isSelectionMode,
    required this.isSelected,
    this.onTapSelection,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMale = player.gender == '男子';

    final genderColor = isMale
        ? (isDark ? context.appColors.infoColor : context.appColors.infoColor)
        : (isDark
              ? context.appColors.errorColor
              : context.appColors.errorColor);
    final bgColor = isMale
        ? (isDark
              ? context.appColors.infoColor.withValues(alpha: 0.25)
              : context.appColors.infoColor.withValues(alpha: 0.1))
        : (isDark
              ? context.appColors.errorColor.withValues(alpha: 0.25)
              : context.appColors.errorColor.withValues(alpha: 0.1));

    final selectedColor = isDark
        ? context.appColors.primaryAccent.withValues(alpha: 0.2)
        : const Color(0xFF9C27B0);

    final tile = Material(
      color: isSelectionMode && isSelected
          ? selectedColor
          : AppKendoColors.transparent,
      child: InkWell(
        onTap: isSelectionMode ? onTapSelection : null,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 10,
          ),
          child: Row(
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected
                        ? const Color(0xFF9C27B0)
                        : const Color(0x8A000000),
                    size: 22,
                  ),
                ),
              CircleAvatar(
                backgroundColor: bgColor,
                foregroundColor: genderColor,
                radius: 18,
                child: Text(
                  player.lastName.isNotEmpty
                      ? player.lastName.substring(0, 1)
                      : '',
                  style: const TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.body,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: TextStyle(
                              fontWeight: AppFontWeight.medium,
                              fontSize: AppFontSize.subhead,
                              color: context.appColors.textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.isBeginner) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.subValue,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppKendoColors.successGreen,
                              borderRadius: AppRadius.tiny,
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.eco,
                                  size: 10,
                                  color: AppKendoColors.pureWhite,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '初心者',
                                  style: TextStyle(
                                    color: AppKendoColors.pureWhite,
                                    fontSize: AppFontSize.nano,
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (player.nameKana.isNotEmpty)
                          Text(
                            '${player.nameKana} ',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0x8A000000),
                              fontSize: AppFontSize.caption,
                            ),
                          ),
                        Text(
                          '${player.gradeName} / ${player.gender}',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : const Color(0x8A000000),
                            fontSize: AppFontSize.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isSelectionMode || isReadOnly || !canManageMaster) {
      return tile;
    }

    return Slidable(
      key: ValueKey(player.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: onEdit != null ? (_) => onEdit!() : null,
            backgroundColor: AppKendoColors.blueAccent,
            foregroundColor: AppKendoColors.pureWhite,
            icon: Icons.edit,
            label: '編集',
          ),
          SlidableAction(
            onPressed: onDelete != null ? (_) => onDelete!() : null,
            backgroundColor: AppKendoColors.redAccent,
            foregroundColor: AppKendoColors.pureWhite,
            icon: Icons.delete,
            label: '削除',
          ),
        ],
      ),
      child: tile,
    );
  }
}
