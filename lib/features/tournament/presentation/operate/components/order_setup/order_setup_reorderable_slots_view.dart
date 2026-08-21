import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_position_slot.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// オーダー編成画面のドラッグ並び替え対応ポジションスロット一覧
class OrderSetupReorderableSlotsView extends StatelessWidget {
  final List<String> positions;
  final Map<int, String> selectedPlayers;
  final Map<int, String> opponentPlayers;
  final String teamName;
  final bool isLeague;
  final bool isDark;
  final bool isReadOnly;
  final AppThemeColors themeColors;
  final List<PlayerModel> masterPlayers;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onSelectPlayerTap;
  final void Function(int index, String val) onOpponentChanged;
  final void Function(int index) onVacantPressed;

  const OrderSetupReorderableSlotsView({
    super.key,
    required this.positions,
    required this.selectedPlayers,
    required this.opponentPlayers,
    required this.teamName,
    required this.isLeague,
    required this.isDark,
    this.isReadOnly = false,
    required this.themeColors,
    required this.masterPlayers,
    required this.onReorder,
    required this.onSelectPlayerTap,
    required this.onOpponentChanged,
    required this.onVacantPressed,
  });

  @override
  Widget build(BuildContext context) {
    final subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : context.appColors.subTextColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(Icons.swap_vert, size: 16, color: themeColors.primaryAccent),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '長押しドラッグで選手の配置・順番を自由に入れ替えできます',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: subTextColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          itemCount: positions.length,
          onReorderItem: onReorder,
          itemBuilder: (context, index) {
            final posName = positions[index];
            final playerName = selectedPlayers[index] ?? '未定';
            final isSelected = selectedPlayers.containsKey(index);

            return Padding(
              key: ValueKey('order_slot_${positions[index]}_$index'),
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: OrderSetupPositionSlot(
                index: index,
                posName: posName,
                playerName: playerName,
                teamName: teamName,
                isSelected: isSelected,
                onTap: () => onSelectPlayerTap(index),
                isDark: isDark,
                showOpponentField: !isLeague,
                opponentPlayerName: opponentPlayers[index] ?? '',
                onOpponentChanged: (val) => onOpponentChanged(index, val),
                onVacantPressed: () => onVacantPressed(index),
              ),
            );
          },
        ),
      ],
    );
  }
}
