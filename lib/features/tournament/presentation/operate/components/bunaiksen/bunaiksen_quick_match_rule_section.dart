import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// クイック対戦: 試合時間・勝負形式設定セクション
class BunaiksenQuickMatchRuleSection extends StatelessWidget {
  final double selectedMatchTime;
  final bool selectedIsIpponShobu;
  final ValueChanged<double> onMatchTimeChanged;
  final ValueChanged<bool> onIsIpponShobuChanged;

  const BunaiksenQuickMatchRuleSection({
    super.key,
    required this.selectedMatchTime,
    required this.selectedIsIpponShobu,
    required this.onMatchTimeChanged,
    required this.onIsIpponShobuChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.modernValue),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 試合時間 (＋／－ カプセルステッパー)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xDE000000),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '試合時間',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: AppFontWeight.bold,
                      color: themeColors.textColor,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A3A3C)
                      : const Color(0xFFFFFFFF),
                  borderRadius: AppRadius.round,
                  border: Border.all(
                    color: themeColors.primaryAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 32,
                      ),
                      color: selectedMatchTime > 0.5
                          ? themeColors.primaryAccent
                          : AppKendoColors.grey,
                      onPressed: selectedMatchTime > 0.5
                          ? () => onMatchTimeChanged(
                              (selectedMatchTime - 0.5).clamp(0.5, 10.0),
                            )
                          : null,
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 54),
                      alignment: Alignment.center,
                      child: Text(
                        selectedMatchTime % 1 == 0
                            ? '${selectedMatchTime.toInt()}分'
                            : '$selectedMatchTime分',
                        style: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.body,
                          color: themeColors.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 32,
                      ),
                      color: selectedMatchTime < 10.0
                          ? themeColors.primaryAccent
                          : AppKendoColors.grey,
                      onPressed: selectedMatchTime < 10.0
                          ? () => onMatchTimeChanged(
                              (selectedMatchTime + 0.5).clamp(0.5, 10.0),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 勝負形式 (3本勝負 / 1本勝負)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 16,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xDE000000),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '勝負形式',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: AppFontWeight.bold,
                      color: themeColors.textColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // 3本勝負
                  InkWell(
                    onTap: () => onIsIpponShobuChanged(false),
                    borderRadius: AppRadius.large,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.modernValue,
                        vertical: AppSpacing.subValue,
                      ),
                      decoration: BoxDecoration(
                        color: !selectedIsIpponShobu
                            ? themeColors.primaryAccent
                            : (isDark
                                  ? const Color(0xFF3A3A3C)
                                  : const Color(0xFFFFFFFF)),
                        borderRadius: AppRadius.large,
                        border: Border.all(
                          color: !selectedIsIpponShobu
                              ? themeColors.primaryAccent
                              : const Color(0x33000000),
                        ),
                      ),
                      child: Text(
                        '3本勝負',
                        style: TextStyle(
                          fontSize: AppFontSize.small,
                          fontWeight: !selectedIsIpponShobu
                              ? AppFontWeight.bold
                              : AppFontWeight.regular,
                          color: !selectedIsIpponShobu
                              ? AppKendoColors.pureWhite
                              : themeColors.textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // 1本勝負
                  InkWell(
                    onTap: () => onIsIpponShobuChanged(true),
                    borderRadius: AppRadius.large,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.modernValue,
                        vertical: AppSpacing.subValue,
                      ),
                      decoration: BoxDecoration(
                        color: selectedIsIpponShobu
                            ? themeColors.primaryAccent
                            : (isDark
                                  ? const Color(0xFF3A3A3C)
                                  : const Color(0xFFFFFFFF)),
                        borderRadius: AppRadius.large,
                        border: Border.all(
                          color: selectedIsIpponShobu
                              ? themeColors.primaryAccent
                              : const Color(0x33000000),
                        ),
                      ),
                      child: Text(
                        '1本勝負',
                        style: TextStyle(
                          fontSize: AppFontSize.small,
                          fontWeight: selectedIsIpponShobu
                              ? AppFontWeight.bold
                              : AppFontWeight.regular,
                          color: selectedIsIpponShobu
                              ? AppKendoColors.pureWhite
                              : themeColors.textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
