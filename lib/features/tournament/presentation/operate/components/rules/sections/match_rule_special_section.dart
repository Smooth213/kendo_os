import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_dialog_helper.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

/// ⚔️ 特殊形式（勝ち抜き戦・リーグ勝ち点）設定セクション
class MatchRuleSpecialSection extends StatelessWidget {
  final bool isKachinuki;
  final String kachinukiUnlimitedType;
  final bool isLeague;
  final double winPoint;
  final double lossPoint;
  final double drawPoint;
  final Color primaryAccent;
  final bool isDark;

  final ValueChanged<bool>? onKachinukiChanged;
  final ValueChanged<String>? onKachinukiUnlimitedTypeChanged;
  final ValueChanged<bool>? onLeagueChanged;
  final ValueChanged<double>? onWinPointChanged;
  final ValueChanged<double>? onLossPointChanged;
  final ValueChanged<double>? onDrawPointChanged;

  const MatchRuleSpecialSection({
    super.key,
    required this.isKachinuki,
    required this.kachinukiUnlimitedType,
    required this.isLeague,
    required this.winPoint,
    required this.lossPoint,
    required this.drawPoint,
    required this.primaryAccent,
    required this.isDark,
    this.onKachinukiChanged,
    this.onKachinukiUnlimitedTypeChanged,
    this.onLeagueChanged,
    this.onWinPointChanged,
    this.onLossPointChanged,
    this.onDrawPointChanged,
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
            '⚔️ 特殊形式 ＆ リーグ順位決定ルール',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 勝ち抜き戦
          InkWell(
            onTap: () {
              if (onKachinukiChanged != null) {
                onKachinukiChanged!(!isKachinuki);
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
                        '勝ち抜き戦形式',
                        style: TextStyle(fontSize: AppFontSize.body),
                      ),
                      Text(
                        isKachinuki ? '勝者が続けて次の相手と対戦します' : '通常の対戦形式です',
                        style: TextStyle(
                          fontSize: AppFontSize.nano,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: isKachinuki,
                  activeColor: primaryAccent,
                  onChanged: onKachinukiChanged,
                ),
              ],
            ),
          ),
          if (isKachinuki) ...[
            const Divider(height: AppSpacing.md),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  '大将戦の形式: ',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: context.appColors.subTextColor,
                  ),
                ),
                AppChoiceChip(
                  selected: kachinukiUnlimitedType == '大将対大将',
                  label: const Text('大将対大将 (無制限)'),
                  onSelected: (s) {
                    if (s && onKachinukiUnlimitedTypeChanged != null) {
                      onKachinukiUnlimitedTypeChanged!('大将対大将');
                    }
                  },
                ),
                AppChoiceChip(
                  selected: kachinukiUnlimitedType != '大将対大将',
                  label: const Text('通常形式'),
                  onSelected: (s) {
                    if (s && onKachinukiUnlimitedTypeChanged != null) {
                      onKachinukiUnlimitedTypeChanged!('通常');
                    }
                  },
                ),
              ],
            ),
          ],
          const Divider(height: AppSpacing.xl),

          // リーグ戦設定
          InkWell(
            onTap: () {
              if (onLeagueChanged != null) {
                onLeagueChanged!(!isLeague);
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
                        'リーグ戦（勝点集計ルール）',
                        style: TextStyle(fontSize: AppFontSize.body),
                      ),
                      Text(
                        isLeague ? '勝点による順位決定を適用します' : 'トーナメント・通常勝敗ルールです',
                        style: TextStyle(
                          fontSize: AppFontSize.nano,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: isLeague,
                  activeColor: primaryAccent,
                  onChanged: onLeagueChanged,
                ),
              ],
            ),
          ),
          if (isLeague) ...[
            const Divider(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '勝ち（点）: $winPoint',
                        style: TextStyle(
                          fontSize: AppFontSize.nano,
                          fontWeight: AppFontWeight.bold,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          for (final pt in [3.0, 2.0, 1.0])
                            AppChoiceChip(
                              selected: winPoint == pt,
                              label: Text('$pt'),
                              onSelected: (s) {
                                if (s && onWinPointChanged != null) {
                                  onWinPointChanged!(pt);
                                }
                              },
                            ),
                          AppActionChip(
                            icon: Icons.edit,
                            label: const Text('カスタム'),
                            onPressed: () =>
                                MatchRuleDialogHelper.showCustomPointDialog(
                                  context,
                                  title: '勝ち点の設定',
                                  currentPoint: winPoint,
                                  onConfirmed: (p) {
                                    if (onWinPointChanged != null) {
                                      onWinPointChanged!(p);
                                    }
                                  },
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '引き分け（点）: $drawPoint',
                        style: TextStyle(
                          fontSize: AppFontSize.nano,
                          fontWeight: AppFontWeight.bold,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          for (final pt in [1.0, 0.5, 0.0])
                            AppChoiceChip(
                              selected: drawPoint == pt,
                              label: Text('$pt'),
                              onSelected: (s) {
                                if (s && onDrawPointChanged != null) {
                                  onDrawPointChanged!(pt);
                                }
                              },
                            ),
                          AppActionChip(
                            icon: Icons.edit,
                            label: const Text('カスタム'),
                            onPressed: () =>
                                MatchRuleDialogHelper.showCustomPointDialog(
                                  context,
                                  title: '引き分け点の設定',
                                  currentPoint: drawPoint,
                                  onConfirmed: (p) {
                                    if (onDrawPointChanged != null) {
                                      onDrawPointChanged!(p);
                                    }
                                  },
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '負け（点）: $lossPoint',
                        style: TextStyle(
                          fontSize: AppFontSize.nano,
                          fontWeight: AppFontWeight.bold,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          for (final pt in [0.0, -1.0])
                            AppChoiceChip(
                              selected: lossPoint == pt,
                              label: Text('$pt'),
                              onSelected: (s) {
                                if (s && onLossPointChanged != null) {
                                  onLossPointChanged!(pt);
                                }
                              },
                            ),
                          AppActionChip(
                            icon: Icons.edit,
                            label: const Text('カスタム'),
                            onPressed: () =>
                                MatchRuleDialogHelper.showCustomPointDialog(
                                  context,
                                  title: '負け点の設定',
                                  currentPoint: lossPoint,
                                  onConfirmed: (p) {
                                    if (onLossPointChanged != null) {
                                      onLossPointChanged!(p);
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
            ),
          ],
        ],
      ),
    );
  }
}
