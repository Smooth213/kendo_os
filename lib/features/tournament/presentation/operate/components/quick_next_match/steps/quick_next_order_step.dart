import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/kata_pair_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/steps/quick_next_order_slot_tile.dart';
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

  Future<void> _changePlayer({
    required BuildContext context,
    required List<PlayerModel> masterPlayers,
    required AppThemeColors themeColors,
    required int slotIndex,
    int? pairMemberIndex,
  }) async {
    final selected = await OrderSetupPlayerSelectBottomSheet.show(
      context,
      masterPlayers: masterPlayers,
      themeColors: themeColors,
    );
    if (selected == null) return;

    final updated = List<String>.from(playerNames);
    while (updated.length <= slotIndex) {
      updated.add('選手');
    }

    final currentVal = updated[slotIndex];
    final cleanSelected = (selected == 'CLEAR_FLAG' || selected.trim().isEmpty)
        ? '選手'
        : selected.trim();

    if (pairMemberIndex != null && KataPairHelper.isPair(currentVal)) {
      updated[slotIndex] = KataPairHelper.updateMember(
        currentVal,
        pairMemberIndex,
        cleanSelected,
      );
    } else {
      updated[slotIndex] = cleanSelected;
    }
    onPlayerNamesChanged(updated);
  }

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
    final isPair = KataPairHelper.isPair(playerName);

    if (isPair) {
      final members = KataPairHelper.parsePair(playerName);
      return Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2C2C2E)
                : themeColors.cardBackground,
            borderRadius: AppRadius.large,
            border: Border.all(color: themeColors.separatorColor),
          ),
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
              const SizedBox(height: AppSpacing.xs),
              Text(
                'ペア選手 (形競技)',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.primaryAccent,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...members.map((member) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: themeColors.primaryAccent.withValues(
                            alpha: 0.12,
                          ),
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
                      const SizedBox(width: AppSpacing.md),
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
                      OutlinedButton(
                        onPressed: () => _changePlayer(
                          context: context,
                          masterPlayers: allMasterPlayers,
                          themeColors: themeColors,
                          slotIndex: 0,
                          pairMemberIndex: member.index,
                        ),
                        child: const Text('変更'),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

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
              onPressed: () => _changePlayer(
                context: context,
                masterPlayers: allMasterPlayers,
                themeColors: themeColors,
                slotIndex: 0,
              ),
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

        return QuickNextOrderSlotTile(
          key: ValueKey('slot_${pos}_$index'),
          index: index,
          pos: pos,
          name: name,
          themeColors: themeColors,
          isDark: isDark,
          onSelectPlayer: (slotIdx, memberIdx) => _changePlayer(
            context: context,
            masterPlayers: allMasterPlayers,
            themeColors: themeColors,
            slotIndex: slotIdx,
            pairMemberIndex: memberIdx,
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
                shape: const StadiumBorder(),
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
              shape: const StadiumBorder(),
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
