import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/kata_pair_helper.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// クイック次戦作成 Step 1 用のスロットタイル（単独選手および剣道形ペア選手個別変更対応）
class QuickNextOrderSlotTile extends StatelessWidget {
  final int index;
  final String pos;
  final String name;
  final AppThemeColors themeColors;
  final bool isDark;
  final void Function(int slotIndex, int? pairMemberIndex) onSelectPlayer;

  const QuickNextOrderSlotTile({
    super.key,
    required this.index,
    required this.pos,
    required this.name,
    required this.themeColors,
    required this.isDark,
    required this.onSelectPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final isPair = KataPairHelper.isPair(name);

    return Container(
      key: ValueKey('slot_${pos}_$index'),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : themeColors.cardBackground,
        borderRadius: AppRadius.medium,
        border: Border.all(color: themeColors.separatorColor),
      ),
      child: isPair ? _buildPairContent() : _buildStandardContent(),
    );
  }

  Widget _buildPairContent() {
    final members = KataPairHelper.parsePair(name, posName: pos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: themeColors.primaryAccent.withValues(
                alpha: 0.15,
              ),
              child: Text(
                pos.isNotEmpty ? pos[0] : '?',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.primaryAccent,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                pos,
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.bodySmall,
                  color: themeColors.subTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(
                  Icons.drag_handle,
                  color: themeColors.subTextColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.xs),
        ...members.map((member) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.subValue,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: themeColors.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: AppRadius.sub,
                  ),
                  child: Text(
                    member.role,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: themeColors.primaryAccent,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    member.name,
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                      color: themeColors.textColor,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => onSelectPlayer(index, member.index),
                  child: const Text('変更'),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStandardContent() {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: themeColors.primaryAccent.withValues(alpha: 0.15),
          child: Text(
            pos.isNotEmpty ? pos[0] : '?',
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: AppFontWeight.bold,
              color: themeColors.primaryAccent,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40, maxWidth: 100),
          child: Text(
            pos,
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
              color: themeColors.subTextColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: AppFontWeight.bold,
              color: themeColors.textColor,
            ),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => onSelectPlayer(index, null),
          child: const Text('変更'),
        ),
        const SizedBox(width: AppSpacing.xs),
        ReorderableDragStartListener(
          index: index,
          child: Icon(
            Icons.drag_handle,
            color: themeColors.subTextColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
