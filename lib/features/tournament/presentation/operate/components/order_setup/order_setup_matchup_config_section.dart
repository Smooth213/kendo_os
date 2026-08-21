import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_team_autocomplete_field.dart';

class OrderSetupMatchupConfigSection extends StatelessWidget {
  final AppThemeColors themeColors;
  final bool isOwnTeamRed;
  final ValueChanged<bool> onIsOwnTeamRedChanged;
  final TextEditingController opponentTeamController;
  final FocusNode opponentTeamFocusNode;
  final List<String> opponentTeamSuggestions;
  final bool isDark;

  const OrderSetupMatchupConfigSection({
    super.key,
    required this.themeColors,
    required this.isOwnTeamRed,
    required this.onIsOwnTeamRedChanged,
    required this.opponentTeamController,
    required this.opponentTeamFocusNode,
    required this.opponentTeamSuggestions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = context.appColors.textColor;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;
    final subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : context.appColors.subTextColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '自チームの紅白（タスキ）',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              color: themeColors.primaryAccent,
            ),
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
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0x33000000),
              borderRadius: AppRadius.medium,
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onIsOwnTeamRedChanged(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: isOwnTeamRed
                            ? (isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFFFFFFF))
                            : Colors.transparent,
                        borderRadius: AppRadius.small,
                        boxShadow: (isOwnTeamRed && !isDark)
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
                          Icon(
                            Icons.looks_one,
                            size: 18,
                            color: isOwnTeamRed
                                ? AppKendoColors.hansokuRed
                                : (isDark
                                      ? const Color(0xFF757575)
                                      : AppKendoColors.grey),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '赤 (左側)',
                            style: TextStyle(
                              color: isOwnTeamRed
                                  ? AppKendoColors.hansokuRed
                                  : subTextColor,
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onIsOwnTeamRedChanged(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: !isOwnTeamRed
                            ? (isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFFFFFFF))
                            : AppKendoColors.transparent,
                        borderRadius: AppRadius.small,
                        boxShadow: (!isOwnTeamRed && !isDark)
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
                          Icon(
                            Icons.looks_two,
                            size: 18,
                            color: !isOwnTeamRed
                                ? (isDark
                                      ? const Color(0xFF90A4AE)
                                      : const Color(0xFF37474F))
                                : (isDark
                                      ? const Color(0xFF757575)
                                      : AppKendoColors.grey),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '白 (右側)',
                            style: TextStyle(
                              color: !isOwnTeamRed
                                  ? (isDark
                                        ? AppKendoColors.pureWhite
                                        : const Color(0xFF37474F))
                                  : subTextColor,
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.body,
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
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
              borderRadius: AppRadius.large,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield,
                      color: isDark
                          ? const Color(0xFF607D8B)
                          : const Color(0xFF607D8B),
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '相手チームの情報を入力',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        color: isDark
                            ? const Color(0xFF607D8B)
                            : const Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                OrderSetupTeamAutocompleteField(
                  controller: opponentTeamController,
                  focusNode: opponentTeamFocusNode,
                  suggestions: opponentTeamSuggestions,
                  labelText: '相手チーム名・所属名（任意）',
                  hintText: 'タップして登録済みリストから選択',
                  fillColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFFFFFFF),
                  borderColor: borderColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  primaryAccent: themeColors.primaryAccent,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
