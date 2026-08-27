import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_rule_summary_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 試合編集シートの一括ルール・設定タブ
class MatchEditRuleAndMemoTab extends ConsumerWidget {
  const MatchEditRuleAndMemoTab({
    super.key,
    required this.primaryAccent,
    required this.isDark,
    required this.textColor,
    required this.tournamentId,
    required this.match,
    this.isDantai = false,
    required this.selectedPresetKey,
    required this.selectedPresetRule,
    required this.matchTime,
    required this.isIpponShobu,
    required this.hasHantei,
    required this.onPresetSelected,
    required this.onMatchTimeChanged,
    required this.onIpponShobuChanged,
    required this.onHanteiChanged,
  });

  final Color primaryAccent;
  final bool isDark;
  final Color textColor;
  final String? tournamentId;
  final MatchModel match;
  final bool isDantai;
  final String? selectedPresetKey;
  final MatchRule? selectedPresetRule;
  final double matchTime;
  final bool isIpponShobu;
  final bool hasHantei;
  final void Function(MatchRule rule, String key) onPresetSelected;
  final ValueChanged<double> onMatchTimeChanged;
  final ValueChanged<bool> onIpponShobuChanged;
  final ValueChanged<bool> onHanteiChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourneyId = tournamentId ?? match.tournamentId ?? '';
    final asyncTourney = ref.watch(tournamentProvider(tourneyId));
    final categoryRules = asyncTourney.valueOrNull?.categoryRules ?? {};

    final matchCategory = match.category;

    final List<Widget> categoryPresetChips = [];
    categoryRules.forEach((catName, ruleSet) {
      if (matchCategory != null &&
          matchCategory.isNotEmpty &&
          catName != matchCategory &&
          !catName.contains(matchCategory) &&
          !matchCategory.contains(catName)) {
        return;
      }

      // 設定が存在・有効化されているルールのみチップとして表示
      final bool hasValidHonsen =
          ruleSet.useHonsenRule && ruleSet.normalRule.matchTimeMinutes > 0;
      if (hasValidHonsen) {
        final isSelected = selectedPresetKey == 'honsen';
        categoryPresetChips.add(
          AppChoiceChip(
            selected: isSelected,
            icon: Icons.bookmark,
            label: Text(
              '本線ルール (${ruleSet.normalRule.matchTimeMinutes == ruleSet.normalRule.matchTimeMinutes.toInt() ? ruleSet.normalRule.matchTimeMinutes.toInt() : ruleSet.normalRule.matchTimeMinutes}分)',
            ),
            onSelected: (selected) {
              if (selected) {
                onPresetSelected(ruleSet.normalRule, 'honsen');
              }
            },
          ),
        );
      }

      final bool hasValidRenseikai =
          ruleSet.useRenseikaiRule &&
          ruleSet.renseikaiRule.matchTimeMinutes > 0;
      if (hasValidRenseikai) {
        final isSelected = selectedPresetKey == 'renseikai';
        categoryPresetChips.add(
          AppChoiceChip(
            selected: isSelected,
            icon: Icons.flash_on,
            label: Text(
              '錬成会ルール (${ruleSet.renseikaiRule.matchTimeMinutes == ruleSet.renseikaiRule.matchTimeMinutes.toInt() ? ruleSet.renseikaiRule.matchTimeMinutes.toInt() : ruleSet.renseikaiRule.matchTimeMinutes}分)',
            ),
            onSelected: (selected) {
              if (selected) {
                onPresetSelected(ruleSet.renseikaiRule, 'renseikai');
              }
            },
          ),
        );
      }

      final bool hasValidMoushiawase =
          ruleSet.useMoushiawaseRule &&
          ruleSet.moushiawaseRule.matchTimeMinutes > 0;
      if (hasValidMoushiawase) {
        final isSelected = selectedPresetKey == 'moushiawase';
        categoryPresetChips.add(
          AppChoiceChip(
            selected: isSelected,
            icon: Icons.handshake,
            label: Text(
              '申し合わせルール (${ruleSet.moushiawaseRule.matchTimeMinutes == ruleSet.moushiawaseRule.matchTimeMinutes.toInt() ? ruleSet.moushiawaseRule.matchTimeMinutes.toInt() : ruleSet.moushiawaseRule.matchTimeMinutes}分)',
            ),
            onSelected: (selected) {
              if (selected) {
                onPresetSelected(ruleSet.moushiawaseRule, 'moushiawase');
              }
            },
          ),
        );
      }
    });

    final currentRule = selectedPresetRule ?? const MatchRule();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.roundValue),
      children: [
        // 部門別ルールからのワンタップ選択エリア
        if (categoryPresetChips.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.modernValue),
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: primaryAccent.withAlpha(isDark ? 25 : 12),
              borderRadius: AppRadius.large,
              border: Border.all(
                color: primaryAccent.withAlpha(isDark ? 80 : 40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: primaryAccent),
                    const SizedBox(width: 6),
                    Text(
                      '🏷️ 部門別ルール設定からワンタップ選択',
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: AppFontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: 6, runSpacing: 6, children: categoryPresetChips),
              ],
            ),
          ),
        ],

        // 🛡️ 適用中ルールの全内訳表示カード
        MatchRuleSummaryCard(
          matchType: match.matchType,
          isTeamOverride: isDantai,
          currentRule: currentRule,
          matchTime: matchTime,
          isIpponShobu: isIpponShobu,
          hasHantei: hasHantei,
          primaryAccent: primaryAccent,
          isDark: isDark,
          textColor: textColor,
        ),

        // 一括ルールスイッチコントロール
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x33000000),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⏱️ ルールの詳細コントロール & 微調整',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                  color: textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('試合時間'),
                  DropdownButton<double>(
                    value: matchTime,
                    items: [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0].map((v) {
                      return DropdownMenuItem(
                        value: v,
                        child: Text('${v == v.toInt() ? v.toInt() : v}分'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        onMatchTimeChanged(v);
                      }
                    },
                  ),
                ],
              ),
              const Divider(),
              Material(
                color: AppKendoColors.transparent,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('一本勝負にする'),
                  value: isIpponShobu,
                  activeTrackColor: primaryAccent,
                  onChanged: onIpponShobuChanged,
                ),
              ),
              if (!isDantai) ...[
                const Divider(),
                Material(
                  color: AppKendoColors.transparent,
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '個人戦の判定（ハンテイ）を適用',
                      style: TextStyle(
                        color:
                            currentRule.isRenseikai ||
                                currentRule.matchScene == 'renseikai' ||
                                currentRule.matchScene == 'moushiawase'
                            ? AppKendoColors.grey
                            : textColor,
                      ),
                    ),
                    subtitle:
                        currentRule.isRenseikai ||
                            currentRule.matchScene == 'renseikai' ||
                            currentRule.matchScene == 'moushiawase'
                        ? const Text(
                            '※錬成会・申し合わせルールのため強制OFFに固定されています',
                            style: TextStyle(
                              fontSize: AppFontSize.badge,
                              color: AppKendoColors.orange,
                            ),
                          )
                        : null,
                    value: hasHantei,
                    activeTrackColor: primaryAccent,
                    onChanged: (v) {
                      final isRenseikaiOrMoushiawase =
                          currentRule.isRenseikai ||
                          currentRule.matchScene == 'renseikai' ||
                          currentRule.matchScene == 'moushiawase';
                      if (isRenseikaiOrMoushiawase) return;
                      onHanteiChanged(v);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
