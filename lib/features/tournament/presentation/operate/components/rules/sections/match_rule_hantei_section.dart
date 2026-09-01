import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

/// ⚖️ 判定（ハンテイ）ルール設定セクション
class MatchRuleHanteiSection extends StatelessWidget {
  final bool hasHantei;
  final Color primaryAccent;
  final bool isDark;
  final ValueChanged<bool> onHanteiChanged;

  const MatchRuleHanteiSection({
    super.key,
    required this.hasHantei,
    required this.primaryAccent,
    required this.isDark,
    required this.onHanteiChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = context.appColors.textColor;
    final cardBgColor = isDark
        ? const Color(0xFF1E293B)
        : context.appColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : context.appColors.separatorColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: AppRadius.large,
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚖️ 判定（ハンテイ）ルール',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () => onHanteiChanged(!hasHantei),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '判定の適用',
                        style: TextStyle(fontSize: AppFontSize.body),
                      ),
                      Text(
                        hasHantei
                            ? '時間終了時または延長終了時に審判判定を行います'
                            : '判定は行いません（引き分けとなります）',
                        style: TextStyle(
                          fontSize: AppFontSize.nano,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: hasHantei,
                  activeColor: primaryAccent,
                  onChanged: onHanteiChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
