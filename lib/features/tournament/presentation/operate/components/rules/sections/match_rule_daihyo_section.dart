import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_dialog_helper.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

/// 🥋 団体戦・代表戦ルール設定セクション
class MatchRuleDaihyoSection extends StatelessWidget {
  final bool isDantai;
  final bool hasRepresentativeMatch;
  final bool isDaihyoIpponShobu;
  final double daihyoMatchTime;
  final bool daihyoHasExtension;
  final double daihyoEnchoTime;
  final int daihyoEnchoCount;
  final bool isDaihyoEnchoUnlimited;
  final bool daihyoHasHantei;
  final Color primaryAccent;
  final bool isDark;
  final String Function(double) formatMinutes;

  final ValueChanged<bool> onRepresentativeMatchChanged;
  final ValueChanged<bool> onDaihyoIpponShobuChanged;
  final ValueChanged<double> onDaihyoMatchTimeChanged;
  final ValueChanged<bool> onDaihyoExtensionChanged;
  final ValueChanged<double> onDaihyoEnchoTimeChanged;
  final ValueChanged<int> onDaihyoEnchoCountChanged;
  final ValueChanged<bool> onDaihyoEnchoUnlimitedChanged;
  final ValueChanged<bool> onDaihyoHanteiChanged;

  const MatchRuleDaihyoSection({
    super.key,
    required this.isDantai,
    required this.hasRepresentativeMatch,
    required this.isDaihyoIpponShobu,
    required this.daihyoMatchTime,
    required this.daihyoHasExtension,
    required this.daihyoEnchoTime,
    required this.daihyoEnchoCount,
    required this.isDaihyoEnchoUnlimited,
    required this.daihyoHasHantei,
    required this.primaryAccent,
    required this.isDark,
    required this.formatMinutes,
    required this.onRepresentativeMatchChanged,
    required this.onDaihyoIpponShobuChanged,
    required this.onDaihyoMatchTimeChanged,
    required this.onDaihyoExtensionChanged,
    required this.onDaihyoEnchoTimeChanged,
    required this.onDaihyoEnchoCountChanged,
    required this.onDaihyoEnchoUnlimitedChanged,
    required this.onDaihyoHanteiChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDantai) return const SizedBox.shrink();

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
            '🥋 団体戦・代表戦ルール',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () => onRepresentativeMatchChanged(!hasRepresentativeMatch),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '代表戦の適用',
                        style: TextStyle(fontSize: AppFontSize.body),
                      ),
                      Text(
                        hasRepresentativeMatch
                            ? 'チーム勝敗同数の際に代表戦を行います'
                            : '代表戦は行いません（引き分け）',
                        style: TextStyle(
                          fontSize: AppFontSize.nano,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: hasRepresentativeMatch,
                  activeColor: primaryAccent,
                  onChanged: onRepresentativeMatchChanged,
                ),
              ],
            ),
          ),
          if (hasRepresentativeMatch) ...[
            const Divider(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.06),
                borderRadius: AppRadius.medium,
                border: Border.all(color: primaryAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sports_kabaddi,
                        color: primaryAccent,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '代表戦 詳細設定',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.bold,
                          color: primaryAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 1. 代表戦の試合時間
                  Text(
                    '代表戦の時間: ${formatMinutes(daihyoMatchTime)}',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: context.appColors.subTextColor,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      AppChoiceChip(
                        selected: daihyoMatchTime == 0.0,
                        label: const Text('制限なし'),
                        onSelected: (selected) {
                          if (selected) onDaihyoMatchTimeChanged(0.0);
                        },
                      ),
                      for (final t in [1.5, 2.0, 3.0, 4.0, 5.0])
                        AppChoiceChip(
                          selected: daihyoMatchTime == t,
                          label: Text('${t == t.toInt() ? t.toInt() : t}分'),
                          onSelected: (selected) {
                            if (selected) onDaihyoMatchTimeChanged(t);
                          },
                        ),
                      AppActionChip(
                        icon: Icons.edit,
                        label: const Text('カスタム'),
                        onPressed: () =>
                            MatchRuleDialogHelper.showCustomTimeDialog(
                              context,
                              title: '代表戦時間の指定',
                              currentTime: daihyoMatchTime > 0
                                  ? daihyoMatchTime
                                  : 3.0,
                              onConfirmed: onDaihyoMatchTimeChanged,
                            ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.md),

                  // 2. 代表戦形式（1本勝負 / 3本勝負）
                  InkWell(
                    onTap: () => onDaihyoIpponShobuChanged(!isDaihyoIpponShobu),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '代表戦は一本勝負',
                            style: TextStyle(fontSize: AppFontSize.bodySmall),
                          ),
                        ),
                        AppSwitch(
                          value: isDaihyoIpponShobu,
                          activeColor: primaryAccent,
                          onChanged: onDaihyoIpponShobuChanged,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: AppSpacing.md),

                  // 3. 代表戦延長戦
                  InkWell(
                    onTap: () => onDaihyoExtensionChanged(!daihyoHasExtension),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '代表戦の延長戦を行う',
                            style: TextStyle(fontSize: AppFontSize.bodySmall),
                          ),
                        ),
                        AppSwitch(
                          value: daihyoHasExtension,
                          activeColor: primaryAccent,
                          onChanged: onDaihyoExtensionChanged,
                        ),
                      ],
                    ),
                  ),
                  if (daihyoHasExtension) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '代表戦延長の時間: ${formatMinutes(daihyoEnchoTime)}',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: context.appColors.subTextColor,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final t in [1.0, 1.5, 2.0, 3.0])
                          AppChoiceChip(
                            selected: daihyoEnchoTime == t,
                            label: Text('${t == t.toInt() ? t.toInt() : t}分'),
                            onSelected: (selected) {
                              if (selected) onDaihyoEnchoTimeChanged(t);
                            },
                          ),
                        AppActionChip(
                          icon: Icons.edit,
                          label: const Text('カスタム'),
                          onPressed: () =>
                              MatchRuleDialogHelper.showCustomTimeDialog(
                                context,
                                title: '代表戦延長時間の指定',
                                currentTime: daihyoEnchoTime,
                                onConfirmed: onDaihyoEnchoTimeChanged,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      onTap: () => onDaihyoEnchoUnlimitedChanged(
                        !isDaihyoEnchoUnlimited,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              '代表戦延長は無制限（決着まで）',
                              style: TextStyle(fontSize: AppFontSize.nano),
                            ),
                          ),
                          AppSwitch(
                            value: isDaihyoEnchoUnlimited,
                            activeColor: primaryAccent,
                            onChanged: onDaihyoEnchoUnlimitedChanged,
                          ),
                        ],
                      ),
                    ),
                    if (!isDaihyoEnchoUnlimited) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          Text(
                            '代表戦最大延長回数: ',
                            style: TextStyle(
                              fontSize: AppFontSize.nano,
                              color: context.appColors.subTextColor,
                            ),
                          ),
                          for (final c in [1, 2, 3, 5])
                            AppChoiceChip(
                              selected: daihyoEnchoCount == c,
                              label: Text('$c回'),
                              onSelected: (selected) {
                                if (selected) onDaihyoEnchoCountChanged(c);
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                  const Divider(height: AppSpacing.md),

                  // 4. 代表戦判定
                  InkWell(
                    onTap: () => onDaihyoHanteiChanged(!daihyoHasHantei),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '代表戦の判定を行う',
                            style: TextStyle(fontSize: AppFontSize.bodySmall),
                          ),
                        ),
                        AppSwitch(
                          value: daihyoHasHantei,
                          activeColor: primaryAccent,
                          onChanged: onDaihyoHanteiChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
