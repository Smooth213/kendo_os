import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_team_autocomplete_field.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 クイック次戦作成 Step 3: 対戦相手 ＆ 紅白（タスキ）選択（添付ファイル2準拠）
class QuickNextOpponentAndColorStep extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isIndividual;
  final bool isOwnTeamRed;
  final ValueChanged<bool> onIsOwnTeamRedChanged;
  final TextEditingController opponentTeamController;
  final List<String> positions;
  final List<TextEditingController> opponentPlayerControllers;
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
    required this.positions,
    required this.opponentPlayerControllers,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'operate');
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;

    final registeredTeams =
        ref.watch(registeredTeamsProvider(widget.tournamentId)).value ??
        <TeamModel>[];
    final suggestions = registeredTeams.map((t) => t.teamName).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.shield, color: themeColors.primaryAccent, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '対戦相手と紅白（タスキ）の設定',
                style: TextStyle(
                  fontSize: AppFontSize.body,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '自チームの赤白を選択し、対戦相手を入力してください。',
            style: TextStyle(fontSize: AppFontSize.small, color: subTextColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔴⚪ 自チームの紅白（タスキ）選択
                  _buildColorSelector(context, themeColors, isDark),
                  const SizedBox(height: AppSpacing.md),

                  // 🛡 相手チームの情報入力
                  _buildOpponentTeamSection(
                    context,
                    themeColors,
                    suggestions,
                    isDark,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 各ポジションの対戦相手選手名（任意入力）
                  if (widget.positions.isNotEmpty) ...[
                    Text(
                      widget.isIndividual
                          ? '対戦相手の選手名（任意）'
                          : '相手選手のオーダー（任意・後から入力可）',
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        fontWeight: AppFontWeight.bold,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...List.generate(widget.positions.length, (idx) {
                      final pos = widget.positions[idx];
                      final ctrl = idx < widget.opponentPlayerControllers.length
                          ? widget.opponentPlayerControllers[idx]
                          : null;
                      if (ctrl == null) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: AppTextField(
                          controller: ctrl,
                          hintText: widget.isIndividual
                              ? '対戦相手の氏名'
                              : '対戦相手 ($pos)',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            size: 18,
                            color: subTextColor,
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: widget.isSubmitting ? null : widget.onBack,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
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
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildColorSelector(
    BuildContext context,
    AppThemeColors themeColors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : themeColors.cardBackground,
        borderRadius: AppRadius.large,
        border: Border.all(color: themeColors.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, size: 16, color: themeColors.primaryAccent),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '自チームの紅白（タスキ）',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.bodySmall,
                  color: themeColors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            '※数字の小さい方または上・左のチーム（選手）が赤になります',
            style: TextStyle(
              fontSize: AppFontSize.small,
              color: AppKendoColors.red,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
              borderRadius: AppRadius.medium,
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onIsOwnTeamRedChanged(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isOwnTeamRed
                            ? (isDark
                                  ? const Color(0xFF2C2C2E)
                                  : AppKendoColors.pureWhite)
                            : Colors.transparent,
                        borderRadius: AppRadius.small,
                        boxShadow: (widget.isOwnTeamRed && !isDark)
                            ? [
                                BoxShadow(
                                  color: AppKendoColors.pureBlack.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: AppKendoColors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '赤（左側）',
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.bodySmall,
                              color: widget.isOwnTeamRed
                                  ? AppKendoColors.red
                                  : context.appColors.subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onIsOwnTeamRedChanged(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: !widget.isOwnTeamRed
                            ? (isDark
                                  ? const Color(0xFF2C2C2E)
                                  : AppKendoColors.pureWhite)
                            : Colors.transparent,
                        borderRadius: AppRadius.small,
                        boxShadow: (!widget.isOwnTeamRed && !isDark)
                            ? [
                                BoxShadow(
                                  color: AppKendoColors.pureBlack.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppKendoColors.pureWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppKendoColors.grey,
                                width: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '白（右側）',
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.bodySmall,
                              color: !widget.isOwnTeamRed
                                  ? themeColors.textColor
                                  : context.appColors.subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentTeamSection(
    BuildContext context,
    AppThemeColors themeColors,
    List<String> suggestions,
    bool isDark,
  ) {
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : themeColors.cardBackground,
        borderRadius: AppRadius.large,
        border: Border.all(color: themeColors.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 16,
                color: themeColors.primaryAccent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '相手チームの情報（所属・団体名）',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.bodySmall,
                  color: themeColors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OrderSetupTeamAutocompleteField(
            controller: widget.opponentTeamController,
            focusNode: _opponentTeamFocusNode,
            suggestions: suggestions,
            labelText: '相手チーム名・所属名',
            hintText: '相手チーム名・所属名（任意）',
            fillColor: isDark
                ? const Color(0xFF1C1C1E)
                : context.appColors.inputBackground,
            borderColor: borderColor,
            textColor: context.appColors.textColor,
            subTextColor: context.appColors.subTextColor,
            primaryAccent: themeColors.primaryAccent,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}
