import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_screen_providers.dart'
    show playerListProvider;
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 クイック次戦作成 Step 1: オーダー確認・並び替え
class QuickNextOrderStep extends ConsumerWidget {
  final String teamName;
  final bool isIndividual;
  final bool isRenseikai;
  final List<String> positions;
  final List<String> playerNames;
  final ValueChanged<List<String>> onPlayerNamesChanged;
  final VoidCallback onNext;
  final VoidCallback? onQuickStartRenseikai;

  const QuickNextOrderStep({
    super.key,
    required this.teamName,
    required this.isIndividual,
    required this.isRenseikai,
    required this.positions,
    required this.playerNames,
    required this.onPlayerNamesChanged,
    required this.onNext,
    this.onQuickStartRenseikai,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'operate');
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;

    final allMasterPlayers = ref.watch(playerListProvider).value ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.people_alt,
                color: themeColors.primaryAccent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '$teamName のオーダー確認',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isIndividual ? '出場選手を確認してください。' : '長押しドラッグで選手の配置・順番を自由に入れ替えできます。',
            style: TextStyle(fontSize: AppFontSize.small, color: subTextColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: isIndividual
                ? _buildIndividualPlayerTile(
                    context,
                    themeColors,
                    allMasterPlayers,
                  )
                : _buildReorderableSlots(
                    context,
                    themeColors,
                    allMasterPlayers,
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBottomActionButtons(context, themeColors),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildIndividualPlayerTile(
    BuildContext context,
    AppThemeColors themeColors,
    List<PlayerModel> allMasterPlayers,
  ) {
    final playerName = playerNames.isNotEmpty ? playerNames.first : '選手';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : themeColors.cardBackground,
          borderRadius: AppRadius.large,
          border: Border.all(color: themeColors.separatorColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: themeColors.primaryAccent,
              child: Text(
                playerName.isNotEmpty ? playerName[0] : '?',
                style: const TextStyle(
                  color: AppKendoColors.pureWhite,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamName,
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      color: themeColors.subTextColor,
                    ),
                  ),
                  Text(
                    playerName,
                    style: TextStyle(
                      fontSize: AppFontSize.header,
                      fontWeight: AppFontWeight.bold,
                      color: themeColors.textColor,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () async {
                final selected = await OrderSetupPlayerSelectBottomSheet.show(
                  context,
                  masterPlayers: allMasterPlayers,
                  themeColors: themeColors,
                );
                if (selected != null && selected.isNotEmpty) {
                  onPlayerNamesChanged([selected]);
                }
              },
              child: const Text('変更'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableSlots(
    BuildContext context,
    AppThemeColors themeColors,
    List<PlayerModel> allMasterPlayers,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ReorderableListView.builder(
      itemCount: positions.length,
      onReorderItem: (oldIndex, newIndex) {
        final updatedList = List<String>.from(playerNames);
        while (updatedList.length < positions.length) {
          updatedList.add('選手');
        }
        final item = updatedList.removeAt(oldIndex);
        updatedList.insert(newIndex, item);
        onPlayerNamesChanged(updatedList);
      },
      itemBuilder: (context, index) {
        final pos = positions[index];
        final name = index < playerNames.length ? playerNames[index] : '選手';

        return Container(
          key: ValueKey('slot_${pos}_$index'),
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2C2C2E)
                : themeColors.cardBackground,
            borderRadius: AppRadius.medium,
            border: Border.all(color: themeColors.separatorColor),
          ),
          child: Row(
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
              SizedBox(
                width: 50,
                child: Text(
                  pos,
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.bodySmall,
                    color: themeColors.subTextColor,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  final selected = await OrderSetupPlayerSelectBottomSheet.show(
                    context,
                    masterPlayers: allMasterPlayers,
                    themeColors: themeColors,
                  );
                  if (selected != null) {
                    final updated = List<String>.from(playerNames);
                    while (updated.length <= index) {
                      updated.add('選手');
                    }
                    updated[index] = selected.isEmpty ? '選手' : selected;
                    onPlayerNamesChanged(updated);
                  }
                },
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
          ),
        );
      },
    );
  }

  Widget _buildBottomActionButtons(
    BuildContext context,
    AppThemeColors themeColors,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRenseikai && onQuickStartRenseikai != null) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onQuickStartRenseikai,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppKendoColors.teal,
                foregroundColor: AppKendoColors.pureWhite,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                elevation: 0,
              ),
              icon: const Icon(Icons.bolt),
              label: const Text(
                'このオーダーのまま即開始（Step2/3をスキップ）',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.bodySmall,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColors.primaryAccent,
              foregroundColor: AppKendoColors.pureWhite,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text(
              '試合詳細の設定へ進む',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.bodyMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
