import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_dialog_helper.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

/// ⏱️ 試合時間 ＆ 基本形式設定セクション
class MatchRuleTimeSection extends StatelessWidget {
  final double matchTime;
  final bool isRunningTime;
  final bool isIpponShobu;
  final int ipponLimit;
  final int hansokuLimit;
  final String renseikaiType;
  final TextEditingController? overallTimeController;
  final Color primaryAccent;
  final bool isDark;
  final String Function(double) formatMinutes;

  final ValueChanged<double> onMatchTimeChanged;
  final ValueChanged<bool> onRunningTimeChanged;
  final ValueChanged<bool> onIpponShobuChanged;
  final ValueChanged<int>? onIpponLimitChanged;
  final ValueChanged<int>? onHansokuLimitChanged;
  final ValueChanged<String>? onRenseikaiTypeChanged;
  final ValueChanged<int>? onOverallTimeChanged;

  const MatchRuleTimeSection({
    super.key,
    required this.matchTime,
    required this.isRunningTime,
    required this.isIpponShobu,
    required this.ipponLimit,
    required this.hansokuLimit,
    required this.renseikaiType,
    this.overallTimeController,
    required this.primaryAccent,
    required this.isDark,
    required this.formatMinutes,
    required this.onMatchTimeChanged,
    required this.onRunningTimeChanged,
    required this.onIpponShobuChanged,
    this.onIpponLimitChanged,
    this.onHansokuLimitChanged,
    this.onRenseikaiTypeChanged,
    this.onOverallTimeChanged,
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

    final isTimeBased = renseikaiType == '時間制';
    final currentOverallMins =
        int.tryParse(overallTimeController?.text ?? '') ?? 30;

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
            '⏱️ 試合時間 ＆ 基本形式',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 進行形式（一試合制 / 時間制）
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                '進行形式: ',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  color: context.appColors.subTextColor,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              AppChoiceChip(
                selected: !isTimeBased,
                label: const Text('一試合制 (デフォルト)'),
                onSelected: (selected) {
                  if (selected && onRenseikaiTypeChanged != null) {
                    onRenseikaiTypeChanged!('一試合制');
                  }
                },
              ),
              AppChoiceChip(
                selected: isTimeBased,
                label: const Text('時間制'),
                onSelected: (selected) {
                  if (selected && onRenseikaiTypeChanged != null) {
                    onRenseikaiTypeChanged!('時間制');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 時間制の場合の全体制限時間
          if (isTimeBased) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.08),
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: primaryAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '全体の制限時間: $currentOverallMins分',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: primaryAccent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final m in [15, 20, 30, 40, 50, 60])
                        AppChoiceChip(
                          selected: currentOverallMins == m,
                          label: Text('$m分'),
                          onSelected: (selected) {
                            if (selected) {
                              overallTimeController?.text = m.toString();
                              if (onOverallTimeChanged != null) {
                                onOverallTimeChanged!(m);
                              }
                            }
                          },
                        ),
                      AppActionChip(
                        icon: Icons.edit,
                        label: const Text('カスタム'),
                        onPressed: () =>
                            MatchRuleDialogHelper.showCustomMinutesDialog(
                              context,
                              title: '全体の制限時間の指定',
                              currentMinutes: currentOverallMins,
                              onConfirmed: (m) {
                                overallTimeController?.text = m.toString();
                                if (onOverallTimeChanged != null) {
                                  onOverallTimeChanged!(m);
                                }
                              },
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // 試合時間チップ
          Text(
            '各試合の時間: ${formatMinutes(matchTime)}',
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
              for (final t in [1.5, 2.0, 3.0, 4.0, 5.0])
                AppChoiceChip(
                  selected: matchTime == t,
                  label: Text('${t == t.toInt() ? t.toInt() : t}分'),
                  onSelected: (selected) {
                    if (selected) onMatchTimeChanged(t);
                  },
                ),
              AppActionChip(
                icon: Icons.edit,
                label: const Text('カスタム'),
                onPressed: () => MatchRuleDialogHelper.showCustomTimeDialog(
                  context,
                  title: '試合時間の指定',
                  currentTime: matchTime,
                  onConfirmed: onMatchTimeChanged,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),

          // 時間計測方式（通し計測）
          InkWell(
            onTap: () => onRunningTimeChanged(!isRunningTime),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '通し時間（空回し）にする',
                        style: TextStyle(fontSize: AppFontSize.body),
                      ),
                      Text(
                        isRunningTime
                            ? '反則や合気等で時計を止めず連続計測します'
                            : '主審の「やめ」等で時計をストップします',
                        style: TextStyle(
                          fontSize: AppFontSize.nano,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: isRunningTime,
                  activeColor: primaryAccent,
                  onChanged: onRunningTimeChanged,
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xl),

          // 勝負形式（一本勝負）
          InkWell(
            onTap: () {
              final nextVal = !isIpponShobu;
              onIpponShobuChanged(nextVal);
              if (nextVal && onIpponLimitChanged != null) {
                onIpponLimitChanged!(1);
              } else if (!nextVal && onIpponLimitChanged != null) {
                onIpponLimitChanged!(2);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '一本勝負形式にする',
                        style: TextStyle(fontSize: AppFontSize.body),
                      ),
                      Text(
                        isIpponShobu ? '先に1本取った選手が勝者となります' : '通常の3本勝負（2本先取）です',
                        style: TextStyle(
                          fontSize: AppFontSize.nano,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: isIpponShobu,
                  activeColor: primaryAccent,
                  onChanged: (v) {
                    onIpponShobuChanged(v);
                    if (v && onIpponLimitChanged != null) {
                      onIpponLimitChanged!(1);
                    } else if (!v && onIpponLimitChanged != null) {
                      onIpponLimitChanged!(2);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xl),

          // 勝敗本数上限（得点制限）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '勝敗本数制限（得点制限）',
                      style: TextStyle(fontSize: AppFontSize.body),
                    ),
                    Text(
                      ipponLimit == 1
                          ? '1本先取で勝利（一本勝負）'
                          : (ipponLimit == 3 ? '3本先取で勝利' : '2本先取で勝利（通常）'),
                      style: TextStyle(
                        fontSize: AppFontSize.nano,
                        color: context.appColors.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: AppSpacing.xxs,
                children: [
                  for (final count in [1, 2, 3])
                    AppChoiceChip(
                      selected: ipponLimit == count,
                      label: Text('$count本'),
                      onSelected: (s) {
                        if (s && onIpponLimitChanged != null) {
                          onIpponLimitChanged!(count);
                          if (count == 1) {
                            onIpponShobuChanged(true);
                          } else {
                            onIpponShobuChanged(false);
                          }
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),

          // 反則累積上限
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '反則累積上限',
                      style: TextStyle(fontSize: AppFontSize.body),
                    ),
                    Text(
                      hansokuLimit == 1 ? '反則1回で相手に1本' : '反則2回で相手に1本 (通常)',
                      style: TextStyle(
                        fontSize: AppFontSize.nano,
                        color: context.appColors.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  AppChoiceChip(
                    selected: hansokuLimit == 2,
                    label: const Text('2回'),
                    onSelected: (s) {
                      if (s && onHansokuLimitChanged != null) {
                        onHansokuLimitChanged!(2);
                      }
                    },
                  ),
                  AppChoiceChip(
                    selected: hansokuLimit == 1,
                    label: const Text('1回'),
                    onSelected: (s) {
                      if (s && onHansokuLimitChanged != null) {
                        onHansokuLimitChanged!(1);
                      }
                    },
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
