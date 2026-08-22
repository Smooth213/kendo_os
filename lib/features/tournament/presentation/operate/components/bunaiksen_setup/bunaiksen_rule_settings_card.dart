import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_custom_time_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 部内戦ルール設定カード
class BunaiksenRuleSettingsCard extends ConsumerWidget {
  final MatchRule rule;
  final bool isDark;
  final AppThemeColors themeColors;

  const BunaiksenRuleSettingsCard({
    super.key,
    required this.rule,
    required this.isDark,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(dividerColor: AppKendoColors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0.0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        leading: Icon(Icons.tune, color: themeColors.primaryAccent, size: 20),
        title: Row(
          children: [
            const Text(
              '部内戦ルール設定',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.subhead,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: 2,
                alignment: WrapAlignment.end,
                children: _buildRuleBadges(rule),
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: AppRadius.large,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: themeColors.primaryAccent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '💡 設定したルールは、試合を追加したあとでも「一括ルール変更」からいつでも変更できます。',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: isDark
                              ? AppKendoColors.white60
                              : const Color(0x8A000000),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '試合時間',
                      style: TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                    DropdownButton<double?>(
                      value:
                          [
                            1.0,
                            1.5,
                            2.0,
                            2.5,
                            3.0,
                          ].contains(rule.matchTimeMinutes)
                          ? rule.matchTimeMinutes
                          : null,
                      items: [
                        const DropdownMenuItem(
                          value: 1.0,
                          child: Text('1分00秒'),
                        ),
                        const DropdownMenuItem(
                          value: 1.5,
                          child: Text('1分30秒'),
                        ),
                        const DropdownMenuItem(
                          value: 2.0,
                          child: Text('2分00秒'),
                        ),
                        const DropdownMenuItem(
                          value: 2.5,
                          child: Text('2分30秒'),
                        ),
                        const DropdownMenuItem(
                          value: 3.0,
                          child: Text('3分00秒'),
                        ),
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            '任意 (${rule.matchTimeMinutes.toInt()}分${((rule.matchTimeMinutes % 1) * 60).toInt()}秒)',
                          ),
                        ),
                      ],
                      onChanged: (v) async {
                        if (v != null) {
                          ref
                              .read(bunaiksenRuleProvider.notifier)
                              .update(
                                (state) => state.copyWith(matchTimeMinutes: v),
                              );
                        } else {
                          final customTime =
                              await BunaiksenCustomTimeDialog.show(
                                context,
                                currentTime: rule.matchTimeMinutes,
                                isDark: isDark,
                                primaryAccent: themeColors.primaryAccent,
                                subTextColor: themeColors.subTextColor,
                                hintColor: themeColors.hintColor,
                                inputBackground: themeColors.inputBackground,
                                separatorColor: themeColors.separatorColor,
                              );
                          if (customTime != null && customTime > 0) {
                            ref
                                .read(bunaiksenRuleProvider.notifier)
                                .update(
                                  (state) => state.copyWith(
                                    matchTimeMinutes: customTime,
                                  ),
                                );
                          }
                        }
                      },
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '勝敗条件',
                      style: TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                    DropdownButton<bool>(
                      value: rule.isIpponShobu,
                      items: const [
                        DropdownMenuItem(value: false, child: Text('3本勝負')),
                        DropdownMenuItem(value: true, child: Text('1本勝負')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          ref
                              .read(bunaiksenRuleProvider.notifier)
                              .update(
                                (state) => state.copyWith(
                                  isIpponShobu: v,
                                  ipponLimit: v ? 1 : 2,
                                ),
                              );
                        }
                      },
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '延長戦',
                      style: TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: rule.isEnchoUnlimited
                          ? 'unlimited'
                          : (rule.enchoTimeMinutes > 0 ? 'limited' : 'none'),
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('なし')),
                        DropdownMenuItem(
                          value: 'limited',
                          child: Text('区切りあり'),
                        ),
                        DropdownMenuItem(
                          value: 'unlimited',
                          child: Text('無制限'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == 'none') {
                          ref
                              .read(bunaiksenRuleProvider.notifier)
                              .update(
                                (state) => state.copyWith(
                                  isEnchoUnlimited: false,
                                  enchoTimeMinutes: 0.0,
                                  enchoCount: 0,
                                ),
                              );
                        } else if (v == 'limited') {
                          ref
                              .read(bunaiksenRuleProvider.notifier)
                              .update(
                                (state) => state.copyWith(
                                  isEnchoUnlimited: false,
                                  enchoTimeMinutes: state.matchTimeMinutes,
                                  enchoCount: 1,
                                ),
                              );
                        } else if (v == 'unlimited') {
                          ref
                              .read(bunaiksenRuleProvider.notifier)
                              .update(
                                (state) => state.copyWith(
                                  isEnchoUnlimited: true,
                                  enchoTimeMinutes: 0.0,
                                  enchoCount: 0,
                                ),
                              );
                        }
                      },
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '判定',
                      style: TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                    Switch(
                      value: rule.hasHantei,
                      activeTrackColor: themeColors.primaryAccent.withValues(
                        alpha: 0.5,
                      ),
                      activeThumbColor: themeColors.primaryAccent,
                      onChanged: (v) => ref
                          .read(bunaiksenRuleProvider.notifier)
                          .update((state) => state.copyWith(hasHantei: v)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ルール情報を個別のピルバッジのリストとして構築する
  List<Widget> _buildRuleBadges(MatchRule rule) {
    final badges = <Widget>[];

    // メインバッジ: 試合時間 / 勝負形式
    final shobu = rule.isIpponShobu ? '1本' : '3本';
    badges.add(_buildBadge('${_formatTime(rule.matchTimeMinutes)} / $shobu'));

    // 延長戦バッジ
    if (rule.isEnchoUnlimited) {
      badges.add(_buildBadge('延長∞'));
    } else if (rule.enchoTimeMinutes > 0) {
      badges.add(_buildBadge('延長'));
    }

    // 判定バッジ
    if (rule.hasHantei) {
      badges.add(_buildBadge('判定'));
    }

    return badges;
  }

  /// 丸付きピルバッジを生成する
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: themeColors.primaryAccent.withValues(alpha: 0.15),
        borderRadius: AppRadius.round,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppFontSize.badge,
          fontWeight: AppFontWeight.bold,
          color: themeColors.primaryAccent,
        ),
      ),
    );
  }

  /// 分数を「○分」または「○分○○秒」形式に変換する
  String _formatTime(double minutes) {
    final totalSeconds = (minutes * 60).round();
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    if (secs == 0) {
      return '$mins分';
    }
    return '$mins分${secs.toString().padLeft(2, '0')}秒';
  }
}
