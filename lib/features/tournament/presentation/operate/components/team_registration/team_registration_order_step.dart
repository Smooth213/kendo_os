import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_autocomplete_field.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// チーム登録画面 ページ2: チーム名入力＆オーダー編成
class TeamRegistrationOrderStep extends ConsumerStatefulWidget {
  final int playerCount;
  final List<String> posNames;
  final List<PlayerModel> players;
  final TextEditingController teamNameController;
  final FocusNode teamNameFocusNode;
  final List<String> teamNameSuggestions;
  final Map<int, String> tempSelectedPlayers;
  final int substituteCount;
  final String matchType;
  final String kataRoleOption;
  final ValueChanged<String>? onKataRoleOptionChanged;
  final AppThemeColors themeColors;
  final void Function(int index) onSelectPlayer;
  final void Function(int index) onRemoveSubstitute;
  final VoidCallback onAddSubstitute;
  final VoidCallback? onAddPlayerSlot;
  final void Function(int index)? onRemovePlayerSlot;

  const TeamRegistrationOrderStep({
    super.key,
    required this.playerCount,
    required this.posNames,
    required this.players,
    required this.teamNameController,
    required this.teamNameFocusNode,
    required this.teamNameSuggestions,
    required this.tempSelectedPlayers,
    required this.substituteCount,
    required this.matchType,
    this.kataRoleOption = 'none',
    this.onKataRoleOptionChanged,
    required this.themeColors,
    required this.onSelectPlayer,
    required this.onRemoveSubstitute,
    required this.onAddSubstitute,
    this.onAddPlayerSlot,
    this.onRemovePlayerSlot,
  });

  @override
  ConsumerState<TeamRegistrationOrderStep> createState() =>
      _TeamRegistrationOrderStepState();
}

class _TeamRegistrationOrderStepState
    extends ConsumerState<TeamRegistrationOrderStep> {
  bool _isRoleSectionExpanded = false;

  static const Map<String, String> _kataRoleLabels = {
    'none': '表示なし（選手）',
    'uchidachi_shidachi': '打太刀・仕太刀',
    'shidachi_uchidachi': '仕太刀・打太刀 (入替)',
    'motodachi_kakarite': '元立ち・掛かり手',
    'kakarite_motodachi': '掛かり手・元立ち (入替)',
  };

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppFontSize.subhead,
          fontWeight: AppFontWeight.bold,
          color: widget.themeColors.primaryAccent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = widget.themeColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final inputBgColor = themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;
    final bool isKata =
        widget.matchType.contains('形') || widget.matchType.contains('稽古法');
    final playerCount = widget.playerCount;
    final substituteCount = widget.substituteCount;
    final matchType = widget.matchType;
    final posNames = widget.posNames;
    final tempSelectedPlayers = widget.tempSelectedPlayers;
    final onSelectPlayer = widget.onSelectPlayer;
    final onRemoveSubstitute = widget.onRemoveSubstitute;
    final onRemovePlayerSlot = widget.onRemovePlayerSlot;
    final onAddPlayerSlot = widget.onAddPlayerSlot;
    final onAddSubstitute = widget.onAddSubstitute;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          isKata ? 'ペア・チーム名と選手を\n入力してください' : 'チーム名とオーダーを\n入力してください',
          style: TextStyle(
            fontSize: AppFontSize.display,
            fontWeight: AppFontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TeamRegistrationAutocompleteField(
          controller: widget.teamNameController,
          focusNode: widget.teamNameFocusNode,
          suggestions: widget.teamNameSuggestions,
          labelText: isKata
              ? 'チーム・ペア名 (例: 〇〇道場 または 佐藤・鈴木)'
              : 'チーム名 (例: 〇〇剣友会A)',
          hintText: '登録済みリストから選択',
          fillColor: inputBgColor,
          borderColor: borderColor,
          textColor: textColor,
          subTextColor: themeColors.primaryAccent,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildSectionTitle(isKata ? 'ペア選手編成（タップして選択）' : 'オーダー編成（タップして選択）'),
        if (isKata) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: AppRadius.medium,
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isRoleSectionExpanded = !_isRoleSectionExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 18,
                            color: themeColors.primaryAccent,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '役職表記: ',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _kataRoleLabels[widget.kataRoleOption] ??
                                  '表示なし（選手）',
                              style: TextStyle(
                                fontSize: AppFontSize.caption,
                                fontWeight: AppFontWeight.bold,
                                color: themeColors.primaryAccent,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _isRoleSectionExpanded ? '閉じる' : '変更・入替',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              color: themeColors.primaryAccent,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                          Icon(
                            _isRoleSectionExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: themeColors.primaryAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isRoleSectionExpanded) ...[
                    Divider(height: 1, thickness: 1, color: borderColor),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _kataRoleLabels.entries.map((entry) {
                          return AppChoiceChip(
                            label: Text(entry.value),
                            selected: widget.kataRoleOption == entry.key,
                            selectedColor: themeColors.primaryAccent.withValues(
                              alpha: 0.25,
                            ),
                            onSelected: (s) {
                              if (s) {
                                widget.onKataRoleOptionChanged?.call(entry.key);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: inputBgColor,
            borderRadius: AppRadius.medium,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: AppKendoColors.transparent,
            child: Column(
              children: List.generate(playerCount, (index) {
                final bool isSubstitute =
                    index >= (playerCount - substituteCount);
                final bool isMoreThan7 = matchType.contains('それ以上');
                final bool isRoleNone = posNames[index] == '選手';
                final String avatarText = isSubstitute
                    ? '補'
                    : (isRoleNone
                          ? (isKata ? '${index + 1}' : '選')
                          : (posNames[index].isNotEmpty
                                ? posNames[index].substring(0, 1)
                                : '選'));
                final String subtitleText = isSubstitute
                    ? '補欠'
                    : (isRoleNone
                          ? (isKata ? 'ペア選手 ${index + 1}' : '選手')
                          : posNames[index]);

                return Column(
                  children: [
                    ListTile(
                      onTap: () => onSelectPlayer(index),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: AppSpacing.md,
                      ),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: isSubstitute
                            ? (isDark
                                  ? const Color(
                                      0xFFFF9800,
                                    ).withValues(alpha: 0.2)
                                  : const Color(0xFFFFF3E0))
                            : themeColors.softAccent,
                        child: Text(
                          avatarText,
                          style: TextStyle(
                            color: isSubstitute
                                ? (isDark
                                      ? const Color(0xFFFFB74D)
                                      : const Color(0xFFE65100))
                                : themeColors.primaryAccent,
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.subhead,
                          ),
                        ),
                      ),
                      title: Text(
                        tempSelectedPlayers[index] ?? '未選択',
                        style: TextStyle(
                          fontSize: AppFontSize.headline,
                          fontWeight: AppFontWeight.bold,
                          color: tempSelectedPlayers[index] == null
                              ? context.appColors.subTextColor
                              : textColor,
                        ),
                      ),
                      subtitle: Text(
                        subtitleText,
                        style: TextStyle(
                          color: isSubstitute
                              ? (isDark
                                    ? const Color(0xFFFFB74D)
                                    : const Color(0xFFE65100))
                              : themeColors.primaryAccent,
                          fontSize: AppFontSize.small,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      trailing: isSubstitute
                          ? IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: AppKendoColors.redAccent,
                              ),
                              tooltip: 'この補欠枠を削除',
                              onPressed: () => onRemoveSubstitute(index),
                            )
                          : (isMoreThan7 && playerCount > 3
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: AppKendoColors.redAccent,
                                    ),
                                    tooltip: 'この選手枠を削除',
                                    onPressed: () =>
                                        onRemovePlayerSlot?.call(index),
                                  )
                                : const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: AppKendoColors.grey,
                                  )),
                    ),
                    if (index < playerCount - 1)
                      Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: isDark
                            ? const Color(0xFF38383A)
                            : const Color(0xFFF2F2F7),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
        if (matchType.contains('それ以上')) ...[
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onAddPlayerSlot,
              icon: Icon(
                Icons.person_add_alt_1,
                color: themeColors.primaryAccent,
                size: 18,
              ),
              label: Text(
                '選手枠を追加 ($playerCount名)',
                style: TextStyle(
                  color: themeColors.primaryAccent,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : themeColors.primaryAccent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                backgroundColor: isDark
                    ? const Color(0xFF1C1C1E)
                    : themeColors.softAccent,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
        ] else if (substituteCount < 4 &&
            !matchType.contains('個人戦') &&
            !isKata) ...[
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onAddSubstitute,
              icon: Icon(
                Icons.person_add_alt_1,
                color: themeColors.primaryAccent,
                size: 18,
              ),
              label: Text(
                '補欠を追加 ($substituteCount/4)',
                style: TextStyle(
                  color: themeColors.primaryAccent,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : themeColors.primaryAccent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                backgroundColor: isDark
                    ? const Color(0xFF1C1C1E)
                    : themeColors.softAccent,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
