import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 試合形式設定: 適用ルールの手動切替トグルセクション（通常戦 / 上位戦）
class MatchFormatManualRuleToggleSection extends StatelessWidget {
  final bool useAdvancedRule;
  final bool isCurrentMatchAdvanced;
  final AppThemeColors themeColors;
  final bool isDark;
  final void Function(String type) onSetManualRoundType;

  const MatchFormatManualRuleToggleSection({
    super.key,
    required this.useAdvancedRule,
    required this.isCurrentMatchAdvanced,
    required this.themeColors,
    required this.isDark,
    required this.onSetManualRoundType,
  });

  @override
  Widget build(BuildContext context) {
    if (!useAdvancedRule) {
      return const SizedBox.shrink();
    }

    final isAdvancedToggle = isCurrentMatchAdvanced && useAdvancedRule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '適用ルール（自動判別・手動切替）',
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.bodySmall,
            color: AppKendoColors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => onSetManualRoundType('normal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !isAdvancedToggle
                      ? themeColors.primaryAccent
                      : (isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7)),
                  foregroundColor: !isAdvancedToggle
                      ? const Color(0xFFFFFFFF)
                      : (isDark
                            ? AppKendoColors.white60
                            : const Color(0xFF000000)),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                    side: BorderSide(
                      color: !isAdvancedToggle
                          ? AppKendoColors.transparent
                          : (isDark
                                ? const Color(0xFF38383A)
                                : const Color(0x33000000)),
                    ),
                  ),
                ),
                child: const Text(
                  '通常戦のルール',
                  style: TextStyle(fontWeight: AppFontWeight.semiBold),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: () => onSetManualRoundType('advanced'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAdvancedToggle
                      ? AppKendoColors.teal
                      : (isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7)),
                  foregroundColor: isAdvancedToggle
                      ? const Color(0xFFFFFFFF)
                      : (isDark
                            ? AppKendoColors.white60
                            : const Color(0xFF000000)),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                    side: BorderSide(
                      color: isAdvancedToggle
                          ? AppKendoColors.transparent
                          : (isDark
                                ? const Color(0xFF38383A)
                                : const Color(0x33000000)),
                    ),
                  ),
                ),
                child: const Text(
                  '上位戦のルール',
                  style: TextStyle(fontWeight: AppFontWeight.semiBold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
