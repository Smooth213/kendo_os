import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// オーダー設定画面におけるポジション別選手スロット（純粋UIコンポーネント）
class OrderSetupPositionSlot extends StatelessWidget {
  final int index;
  final String posName;
  final String playerName;
  final String? teamName;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool showOpponentField;
  final String opponentPlayerName;
  final ValueChanged<String>? onOpponentChanged;
  final VoidCallback? onVacantPressed;

  const OrderSetupPositionSlot({
    super.key,
    required this.index,
    required this.posName,
    required this.playerName,
    this.teamName,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.showOpponentField,
    required this.opponentPlayerName,
    this.onOpponentChanged,
    this.onVacantPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;
    final primaryAccent = context.appColors.primaryAccent;
    final softAccent = context.appColors.softAccent;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : context.appColors.cardBackground,
        border: Border.all(
          color: isSelected
              ? primaryAccent
              : (isDark ? const Color(0xFF38383A) : const Color(0x33000000)),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.mediumValue),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isSelected
                        ? softAccent
                        : (isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFEEEEEE)),
                    child: Text(
                      posName.isNotEmpty ? posName.substring(0, 1) : '',
                      style: TextStyle(
                        color: isSelected ? primaryAccent : subTextColor,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName != null && teamName!.isNotEmpty
                              ? '$teamName : $posName'
                              : posName,
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            color: primaryAccent,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        Text(
                          playerName,
                          style: TextStyle(
                            fontSize: AppFontSize.headline,
                            fontWeight: AppFontWeight.bold,
                            color: isSelected ? textColor : subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.modernValue,
                      vertical: AppSpacing.subValue,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? softAccent
                          : (isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF5F5F5)),
                      borderRadius: AppRadius.round,
                    ),
                    child: Text(
                      isSelected ? '変更' : '選択',
                      style: TextStyle(
                        color: isSelected ? primaryAccent : subTextColor,
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.drag_handle,
                        color: subTextColor.withValues(alpha: 0.6),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showOpponentField) ...[
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF2F2F7),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.mediumValue),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: TextFormField(
                key: ValueKey('opp_${index}_$opponentPlayerName'),
                initialValue: opponentPlayerName,
                onChanged: onOpponentChanged,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: '対戦相手 ($posName)',
                  labelStyle: TextStyle(color: subTextColor),
                  hintText: '相手選手名（任意）',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF8E8E93),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : context.appColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF38383A)
                          : const Color(0x33000000),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF38383A)
                          : const Color(0x33000000),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: BorderSide(color: primaryAccent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  isDense: true,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    size: 20,
                    color: AppKendoColors.blueGrey,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        minimumSize: Size.zero,
                        backgroundColor: AppKendoColors.hansokuRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.sub,
                        ),
                      ),
                      icon: const Icon(
                        Icons.block,
                        color: AppKendoColors.pureWhite,
                        size: 14,
                      ),
                      label: const Text(
                        '欠員',
                        style: TextStyle(
                          color: AppKendoColors.pureWhite,
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.small,
                        ),
                      ),
                      onPressed: onVacantPressed,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
