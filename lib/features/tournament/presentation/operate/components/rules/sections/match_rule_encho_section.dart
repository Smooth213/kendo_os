import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_dialog_helper.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

/// 🔄 延長戦ルール設定セクション
class MatchRuleEnchoSection extends StatelessWidget {
  final bool hasExtension;
  final double enchoTime;
  final int enchoCount;
  final bool isEnchoUnlimited;
  final Color primaryAccent;
  final bool isDark;
  final String Function(double) formatMinutes;

  final ValueChanged<bool> onExtensionChanged;
  final ValueChanged<double> onEnchoTimeChanged;
  final ValueChanged<int> onEnchoCountChanged;
  final ValueChanged<bool> onEnchoUnlimitedChanged;

  const MatchRuleEnchoSection({
    super.key,
    required this.hasExtension,
    required this.enchoTime,
    required this.enchoCount,
    required this.isEnchoUnlimited,
    required this.primaryAccent,
    required this.isDark,
    required this.formatMinutes,
    required this.onExtensionChanged,
    required this.onEnchoTimeChanged,
    required this.onEnchoCountChanged,
    required this.onEnchoUnlimitedChanged,
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
            '🔄 延長戦ルール',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () => onExtensionChanged(!hasExtension),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '延長戦を行う',
                        style: TextStyle(fontSize: AppFontSize.body),
                      ),
                      Text(
                        hasExtension
                            ? '引き分け時に勝敗決着のための延長を行います'
                            : '延長戦は行いません（引き分けまたは判定）',
                        style: TextStyle(
                          fontSize: AppFontSize.nano,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: hasExtension,
                  activeColor: primaryAccent,
                  onChanged: onExtensionChanged,
                ),
              ],
            ),
          ),
          if (hasExtension) ...[
            const Divider(height: AppSpacing.xl),
            Text(
              '延長時間: ${formatMinutes(enchoTime)}',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: context.appColors.subTextColor,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final t in [1.0, 1.5, 2.0, 3.0])
                  AppChoiceChip(
                    selected: enchoTime == t,
                    label: Text('${t == t.toInt() ? t.toInt() : t}分'),
                    onSelected: (selected) {
                      if (selected) onEnchoTimeChanged(t);
                    },
                  ),
                AppActionChip(
                  icon: Icons.edit,
                  label: const Text('カスタム'),
                  onPressed: () => MatchRuleDialogHelper.showCustomTimeDialog(
                    context,
                    title: '延長時間の指定',
                    currentTime: enchoTime,
                    onConfirmed: onEnchoTimeChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () => onEnchoUnlimitedChanged(!isEnchoUnlimited),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      '延長回数を無制限（決着まで）にする',
                      style: TextStyle(fontSize: AppFontSize.body),
                    ),
                  ),
                  AppSwitch(
                    value: isEnchoUnlimited,
                    activeColor: primaryAccent,
                    onChanged: onEnchoUnlimitedChanged,
                  ),
                ],
              ),
            ),
            if (!isEnchoUnlimited) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(
                    '最大延長回数: ',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                  for (final c in [1, 2, 3, 5])
                    AppChoiceChip(
                      selected: enchoCount == c,
                      label: Text('$c回'),
                      onSelected: (selected) {
                        if (selected) onEnchoCountChanged(c);
                      },
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
