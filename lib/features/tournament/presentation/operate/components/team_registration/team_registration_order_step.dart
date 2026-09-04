import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_autocomplete_field.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// チーム登録画面 ページ2: チーム名入力＆オーダー編成
class TeamRegistrationOrderStep extends ConsumerWidget {
  final int playerCount;
  final List<String> posNames;
  final List<PlayerModel> players;
  final TextEditingController teamNameController;
  final FocusNode teamNameFocusNode;
  final List<String> teamNameSuggestions;
  final Map<int, String> tempSelectedPlayers;
  final int substituteCount;
  final String matchType;
  final AppThemeColors themeColors;
  final void Function(int index) onSelectPlayer;
  final void Function(int index) onRemoveSubstitute;
  final VoidCallback onAddSubstitute;

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
    required this.themeColors,
    required this.onSelectPlayer,
    required this.onRemoveSubstitute,
    required this.onAddSubstitute,
  });

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppFontSize.subhead,
          fontWeight: AppFontWeight.bold,
          color: themeColors.primaryAccent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final inputBgColor = themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          'チーム名とオーダーを\n入力してください',
          style: TextStyle(
            fontSize: AppFontSize.display,
            fontWeight: AppFontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TeamRegistrationAutocompleteField(
          controller: teamNameController,
          focusNode: teamNameFocusNode,
          suggestions: teamNameSuggestions,
          labelText: 'チーム名 (例: 〇〇剣友会A)',
          hintText: 'タップして登録済みリストから選択',
          fillColor: inputBgColor,
          borderColor: borderColor,
          textColor: textColor,
          subTextColor: themeColors.primaryAccent,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildSectionTitle('オーダー編成（タップして選択）'),
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
                          isSubstitute ? '補' : posNames[index].substring(0, 1),
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
                        posNames[index],
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
                          : const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppKendoColors.grey,
                            ),
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
        if (substituteCount < 4 && !matchType.contains('個人戦')) ...[
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
