import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_matchup_config_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_position_slot.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/kata_pair_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/order_setup_screen.dart'
    show playerListProvider;
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 クイック次戦作成 Step 3: 対戦相手 ＆ 紅白（タスキ）選択（オーダー編成画面準拠）
class QuickNextOpponentAndColorStep extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isIndividual;
  final bool isOwnTeamRed;
  final ValueChanged<bool> onIsOwnTeamRedChanged;
  final TextEditingController opponentTeamController;
  final String ownTeamName;
  final List<String> positions;
  final List<String> playerNames;
  final ValueChanged<List<String>> onPlayerNamesChanged;
  final List<TextEditingController> opponentPlayerControllers;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final VoidCallback? onAddExtraPosition;
  final bool isRenseikai;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final bool isSubmitting;

  const QuickNextOpponentAndColorStep({
    super.key,
    required this.tournamentId,
    required this.isIndividual,
    required this.isOwnTeamRed,
    required this.onIsOwnTeamRedChanged,
    required this.opponentTeamController,
    required this.ownTeamName,
    required this.positions,
    required this.playerNames,
    required this.onPlayerNamesChanged,
    required this.opponentPlayerControllers,
    this.onReorder,
    this.onAddExtraPosition,
    this.isRenseikai = false,
    required this.onBack,
    required this.onConfirm,
    this.isSubmitting = false,
  });

  @override
  ConsumerState<QuickNextOpponentAndColorStep> createState() =>
      _QuickNextOpponentAndColorStepState();
}

class _QuickNextOpponentAndColorStepState
    extends ConsumerState<QuickNextOpponentAndColorStep> {
  late final FocusNode _opponentTeamFocusNode;

  @override
  void initState() {
    super.initState();
    _opponentTeamFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _opponentTeamFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSelectPlayer(
    int index,
    AppThemeColors themeColors, {
    int? pairMemberIndex,
  }) async {
    final masterPlayers = ref.read(playerListProvider).value ?? [];
    final selected = await OrderSetupPlayerSelectBottomSheet.show(
      context,
      masterPlayers: masterPlayers,
      themeColors: themeColors,
    );
    if (selected == null) return;

    final updated = List<String>.from(widget.playerNames);
    while (updated.length <= index) {
      updated.add('選手');
    }

    final currentVal = updated[index];
    final cleanSelected = (selected == 'CLEAR_FLAG' || selected.trim().isEmpty)
        ? '選手'
        : selected.trim();

    if (pairMemberIndex != null && KataPairHelper.isPair(currentVal)) {
      updated[index] = KataPairHelper.updateMember(
        currentVal,
        pairMemberIndex,
        cleanSelected,
      );
    } else {
      updated[index] = cleanSelected;
    }
    widget.onPlayerNamesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'operate');
    final subTextColor = context.appColors.subTextColor;
    final registeredTeams =
        ref.watch(registeredTeamsProvider(widget.tournamentId)).value ?? [];
    final opponentSuggestions = registeredTeams.map((t) => t.teamName).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 自チーム紅白選択 & 相手チーム情報入力（オーダー編成共通UI）
                OrderSetupMatchupConfigSection(
                  themeColors: themeColors,
                  isOwnTeamRed: widget.isOwnTeamRed,
                  onIsOwnTeamRedChanged: widget.onIsOwnTeamRedChanged,
                  opponentTeamController: widget.opponentTeamController,
                  opponentTeamFocusNode: _opponentTeamFocusNode,
                  opponentTeamSuggestions: opponentSuggestions,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.sm),

                // 2. ドラッグ並び替え注記（団体戦時）
                if (!widget.isIndividual) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_vert,
                          size: 16,
                          color: themeColors.primaryAccent,
                        ),
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
                  const SizedBox(height: AppSpacing.xs),
                ],

                // 3. 各ポジションカード群（OrderSetupPositionSlot）
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: widget.isIndividual
                      ? _buildIndividualSlot(context, themeColors, isDark)
                      : _buildReorderableSlots(context, themeColors, isDark),
                ),

                // 4. イレギュラー枠追加ボタン（錬成会時）
                if (widget.isRenseikai &&
                    widget.onAddExtraPosition != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: TextButton.icon(
                      onPressed: widget.onAddExtraPosition,
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: themeColors.primaryAccent,
                      ),
                      label: Text(
                        'イレギュラー枠を追加する（錬成会用）',
                        style: TextStyle(
                          color: themeColors.primaryAccent,
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),

        // 5. 下部アクションバー（戻る ＆ 確定）
        _buildBottomBar(context, themeColors),
      ],
    );
  }

  Widget _buildReorderableSlots(
    BuildContext context,
    AppThemeColors themeColors,
    bool isDark,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.positions.length,
      onReorderItem: (oldIndex, newIndex) {
        if (widget.onReorder != null) {
          widget.onReorder!(oldIndex, newIndex);
        }
      },
      itemBuilder: (context, index) {
        final pos = widget.positions[index];
        final playerName = index < widget.playerNames.length
            ? widget.playerNames[index]
            : '選手';
        final isSelected = playerName.isNotEmpty && playerName != '未定';
        final oppCtrl = index < widget.opponentPlayerControllers.length
            ? widget.opponentPlayerControllers[index]
            : null;
        final oppName = oppCtrl?.text ?? '';

        return Padding(
          key: ValueKey('slot_${pos}_$index'),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: OrderSetupPositionSlot(
            index: index,
            posName: pos,
            playerName: playerName,
            teamName: widget.ownTeamName,
            isSelected: isSelected,
            onTap: () => _handleSelectPlayer(index, themeColors),
            onSelectPairMember: (memberIdx) => _handleSelectPlayer(
              index,
              themeColors,
              pairMemberIndex: memberIdx,
            ),
            isDark: isDark,
            showOpponentField: true,
            opponentPlayerName: oppName,
            onOpponentChanged: (val) {
              if (oppCtrl != null) {
                oppCtrl.text = val;
              }
            },
            onVacantPressed: () {
              if (oppCtrl != null) {
                setState(() {
                  oppCtrl.text = oppCtrl.text == '欠員' ? '' : '欠員';
                });
                FocusScope.of(context).unfocus();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildIndividualSlot(
    BuildContext context,
    AppThemeColors themeColors,
    bool isDark,
  ) {
    final pos = widget.positions.isNotEmpty ? widget.positions.first : '選手';
    final playerName = widget.playerNames.isNotEmpty
        ? widget.playerNames.first
        : '選手';
    final isSelected = playerName.isNotEmpty && playerName != '未定';
    final oppCtrl = widget.opponentPlayerControllers.isNotEmpty
        ? widget.opponentPlayerControllers.first
        : null;
    final oppName = oppCtrl?.text ?? '';

    return OrderSetupPositionSlot(
      index: 0,
      posName: pos,
      playerName: playerName,
      teamName: widget.ownTeamName,
      isSelected: isSelected,
      onTap: () => _handleSelectPlayer(0, themeColors),
      isDark: isDark,
      showOpponentField: true,
      opponentPlayerName: oppName,
      onOpponentChanged: (val) {
        if (oppCtrl != null) {
          oppCtrl.text = val;
        }
      },
      onVacantPressed: () {
        if (oppCtrl != null) {
          setState(() {
            oppCtrl.text = oppCtrl.text == '欠員' ? '' : '欠員';
          });
          FocusScope.of(context).unfocus();
        }
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, AppThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: widget.isSubmitting ? null : widget.onBack,
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                child: const Text('戻る'),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.isSubmitting ? null : widget.onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColors.primaryAccent,
                  foregroundColor: AppKendoColors.pureWhite,
                  shape: const StadiumBorder(),
                ),
                icon: widget.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppKendoColors.pureWhite,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  widget.isSubmitting ? '作成中...' : 'このオーダーで確定して進む',
                  style: const TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
