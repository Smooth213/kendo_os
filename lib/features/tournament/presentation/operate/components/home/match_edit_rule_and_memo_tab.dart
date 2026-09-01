import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/match_rule_setting_form.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 試合編集シートの試合ルール設定タブ（MatchRuleSettingForm統合・全ルール編集対応版）
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
    required this.isRunningTime,
    required this.isIpponShobu,
    this.ipponLimit = 2,
    this.hansokuLimit = 2,
    required this.hasExtension,
    required this.enchoTime,
    required this.enchoCount,
    required this.isEnchoUnlimited,
    required this.hasHantei,
    required this.hasRepresentativeMatch,
    required this.isDaihyoIpponShobu,
    this.daihyoMatchTime = 0.0,
    required this.daihyoHasExtension,
    required this.daihyoEnchoTime,
    required this.daihyoEnchoCount,
    required this.isDaihyoEnchoUnlimited,
    required this.daihyoHasHantei,
    required this.renseikaiType,
    this.overallTimeController,
    this.isKachinuki = false,
    this.kachinukiUnlimitedType = '大将対大将',
    this.isLeague = false,
    this.winPoint = 3.0,
    this.lossPoint = 0.0,
    this.drawPoint = 1.0,
    required this.onPresetSelected,
    required this.onMatchTimeChanged,
    required this.onRunningTimeChanged,
    required this.onIpponShobuChanged,
    this.onIpponLimitChanged,
    this.onHansokuLimitChanged,
    required this.onExtensionChanged,
    required this.onEnchoTimeChanged,
    required this.onEnchoCountChanged,
    required this.onEnchoUnlimitedChanged,
    required this.onHanteiChanged,
    required this.onRepresentativeMatchChanged,
    required this.onDaihyoIpponShobuChanged,
    required this.onDaihyoMatchTimeChanged,
    required this.onDaihyoExtensionChanged,
    required this.onDaihyoEnchoTimeChanged,
    required this.onDaihyoEnchoCountChanged,
    required this.onDaihyoEnchoUnlimitedChanged,
    required this.onDaihyoHanteiChanged,
    required this.onRenseikaiTypeChanged,
    this.onOverallTimeChanged,
    this.onKachinukiChanged,
    this.onKachinukiUnlimitedTypeChanged,
    this.onLeagueChanged,
    this.onWinPointChanged,
    this.onLossPointChanged,
    this.onDrawPointChanged,
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
  final bool isRunningTime;
  final bool isIpponShobu;
  final int ipponLimit;
  final int hansokuLimit;
  final bool hasExtension;
  final double enchoTime;
  final int enchoCount;
  final bool isEnchoUnlimited;
  final bool hasHantei;

  final bool hasRepresentativeMatch;
  final bool isDaihyoIpponShobu;
  final double daihyoMatchTime;
  final bool daihyoHasExtension;
  final double daihyoEnchoTime;
  final int daihyoEnchoCount;
  final bool isDaihyoEnchoUnlimited;
  final bool daihyoHasHantei;

  final String renseikaiType;
  final TextEditingController? overallTimeController;

  final bool isKachinuki;
  final String kachinukiUnlimitedType;
  final bool isLeague;
  final double winPoint;
  final double lossPoint;
  final double drawPoint;

  final void Function(MatchRule rule, String key) onPresetSelected;
  final ValueChanged<double> onMatchTimeChanged;
  final ValueChanged<bool> onRunningTimeChanged;
  final ValueChanged<bool> onIpponShobuChanged;
  final ValueChanged<int>? onIpponLimitChanged;
  final ValueChanged<int>? onHansokuLimitChanged;
  final ValueChanged<bool> onExtensionChanged;
  final ValueChanged<double> onEnchoTimeChanged;
  final ValueChanged<int> onEnchoCountChanged;
  final ValueChanged<bool> onEnchoUnlimitedChanged;
  final ValueChanged<bool> onHanteiChanged;

  final ValueChanged<bool> onRepresentativeMatchChanged;
  final ValueChanged<bool> onDaihyoIpponShobuChanged;
  final ValueChanged<double> onDaihyoMatchTimeChanged;
  final ValueChanged<bool> onDaihyoExtensionChanged;
  final ValueChanged<double> onDaihyoEnchoTimeChanged;
  final ValueChanged<int> onDaihyoEnchoCountChanged;
  final ValueChanged<bool> onDaihyoEnchoUnlimitedChanged;
  final ValueChanged<bool> onDaihyoHanteiChanged;
  final ValueChanged<String> onRenseikaiTypeChanged;
  final ValueChanged<int>? onOverallTimeChanged;

  final ValueChanged<bool>? onKachinukiChanged;
  final ValueChanged<String>? onKachinukiUnlimitedTypeChanged;
  final ValueChanged<bool>? onLeagueChanged;
  final ValueChanged<double>? onWinPointChanged;
  final ValueChanged<double>? onLossPointChanged;
  final ValueChanged<double>? onDrawPointChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourneyId = tournamentId ?? match.tournamentId ?? '';
    final asyncTourney = ref.watch(tournamentProvider(tourneyId));
    final categoryRules = asyncTourney.valueOrNull?.categoryRules ?? {};

    final matchCategory = match.category;

    final List<Widget> presetChips = [];
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
        presetChips.add(
          AppChoiceChip(
            selected: isSelected,
            icon: Icons.account_balance,
            label: Text(
              '本戦ルール (${MatchRuleSettingForm.formatMinutes(ruleSet.normalRule.matchTimeMinutes)})',
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
        presetChips.add(
          AppChoiceChip(
            selected: isSelected,
            icon: Icons.flash_on,
            label: Text(
              '錬成ルール (${MatchRuleSettingForm.formatMinutes(ruleSet.renseikaiRule.matchTimeMinutes)})',
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
        presetChips.add(
          AppChoiceChip(
            selected: isSelected,
            icon: Icons.handshake,
            label: Text(
              '申合せルール (${MatchRuleSettingForm.formatMinutes(ruleSet.moushiawaseRule.matchTimeMinutes)})',
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

    // 試合ルール設定に登録がない場合のフォールバックチップ
    if (presetChips.isEmpty) {
      presetChips.addAll([
        AppChoiceChip(
          selected: selectedPresetKey == 'honsen',
          icon: Icons.account_balance,
          label: Text(
            '本戦ルール (${MatchRuleSettingForm.formatMinutes(matchTime)})',
          ),
          onSelected: (selected) {
            if (selected) {
              onPresetSelected(
                MatchRule(
                  matchScene: 'honsen',
                  matchTimeMinutes: matchTime > 0 ? matchTime : 3.0,
                  isRunningTime: false,
                  isIpponShobu: false,
                  hasHantei: true,
                  enchoTimeMinutes: 2.0,
                  enchoCount: 1,
                  isEnchoUnlimited: false,
                  hasRepresentativeMatch: true,
                  isDaihyoIpponShobu: true,
                  daihyoMatchTimeMinutes: 0.0,
                  daihyoHasExtension: true,
                  daihyoEnchoTimeMinutes: 3.0,
                  daihyoEnchoCount: -2,
                  daihyoHasHantei: false,
                  renseikaiType: '一試合制',
                ),
                'honsen',
              );
            }
          },
        ),
        AppChoiceChip(
          selected: selectedPresetKey == 'renseikai',
          icon: Icons.flash_on,
          label: Text(
            '錬成会ルール (${MatchRuleSettingForm.formatMinutes(matchTime)})',
          ),
          onSelected: (selected) {
            if (selected) {
              onPresetSelected(
                MatchRule(
                  matchScene: 'renseikai',
                  isRenseikai: true,
                  matchTimeMinutes: matchTime > 0 ? matchTime : 3.0,
                  isRunningTime: true,
                  isIpponShobu: false,
                  hasHantei: false,
                  enchoTimeMinutes: 0.0,
                  enchoCount: 0,
                  isEnchoUnlimited: false,
                  hasRepresentativeMatch: false,
                  isDaihyoIpponShobu: false,
                  daihyoMatchTimeMinutes: 0.0,
                  daihyoHasExtension: false,
                  daihyoEnchoTimeMinutes: 0.0,
                  daihyoEnchoCount: 0,
                  daihyoHasHantei: false,
                  renseikaiType: '一試合制',
                ),
                'renseikai',
              );
            }
          },
        ),
        AppChoiceChip(
          selected: selectedPresetKey == 'moushiawase',
          icon: Icons.handshake,
          label: Text(
            '申合せルール (${MatchRuleSettingForm.formatMinutes(matchTime)})',
          ),
          onSelected: (selected) {
            if (selected) {
              onPresetSelected(
                MatchRule(
                  matchScene: 'moushiawase',
                  matchTimeMinutes: matchTime > 0 ? matchTime : 3.0,
                  isRunningTime: true,
                  isIpponShobu: false,
                  hasHantei: false,
                  enchoTimeMinutes: 0.0,
                  enchoCount: 0,
                  isEnchoUnlimited: false,
                  hasRepresentativeMatch: false,
                  isDaihyoIpponShobu: false,
                  daihyoMatchTimeMinutes: 0.0,
                  daihyoHasExtension: false,
                  daihyoEnchoTimeMinutes: 0.0,
                  daihyoEnchoCount: 0,
                  daihyoHasHantei: false,
                  renseikaiType: '一試合制',
                ),
                'moushiawase',
              );
            }
          },
        ),
      ]);
    }

    final cardBgColor = isDark
        ? const Color(0xFF1E293B)
        : Theme.of(context).cardColor;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // 🏷️ 上部ワンタップ選択エリア
        Container(
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
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: primaryAccent),
                  const SizedBox(width: 6),
                  Text(
                    '🏷️ 試合ルール設定からワンタップ選択',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: AppFontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: presetChips,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 🥋 統一ルール設定フォーム（全項目対応）
        MatchRuleSettingForm(
          isDantai: isDantai,
          selectedSceneKey: selectedPresetKey ?? 'honsen',
          matchTime: matchTime,
          isRunningTime: isRunningTime,
          isIpponShobu: isIpponShobu,
          ipponLimit: ipponLimit,
          hansokuLimit: hansokuLimit,
          hasExtension: hasExtension,
          enchoTime: enchoTime,
          enchoCount: enchoCount,
          isEnchoUnlimited: isEnchoUnlimited,
          hasHantei: hasHantei,
          hasRepresentativeMatch: hasRepresentativeMatch,
          isDaihyoIpponShobu: isDaihyoIpponShobu,
          daihyoMatchTime: daihyoMatchTime,
          daihyoHasExtension: daihyoHasExtension,
          daihyoEnchoTime: daihyoEnchoTime,
          daihyoEnchoCount: daihyoEnchoCount,
          isDaihyoEnchoUnlimited: isDaihyoEnchoUnlimited,
          daihyoHasHantei: daihyoHasHantei,
          renseikaiType: renseikaiType,
          overallTimeController: overallTimeController,
          isKachinuki: isKachinuki,
          kachinukiUnlimitedType: kachinukiUnlimitedType,
          isLeague: isLeague,
          winPoint: winPoint,
          lossPoint: lossPoint,
          drawPoint: drawPoint,
          primaryAccent: primaryAccent,
          isDark: isDark,
          onMatchTimeChanged: onMatchTimeChanged,
          onRunningTimeChanged: onRunningTimeChanged,
          onIpponShobuChanged: onIpponShobuChanged,
          onIpponLimitChanged: onIpponLimitChanged,
          onHansokuLimitChanged: onHansokuLimitChanged,
          onExtensionChanged: onExtensionChanged,
          onEnchoTimeChanged: onEnchoTimeChanged,
          onEnchoCountChanged: onEnchoCountChanged,
          onEnchoUnlimitedChanged: onEnchoUnlimitedChanged,
          onHanteiChanged: onHanteiChanged,
          onRepresentativeMatchChanged: onRepresentativeMatchChanged,
          onDaihyoIpponShobuChanged: onDaihyoIpponShobuChanged,
          onDaihyoMatchTimeChanged: onDaihyoMatchTimeChanged,
          onDaihyoExtensionChanged: onDaihyoExtensionChanged,
          onDaihyoEnchoTimeChanged: onDaihyoEnchoTimeChanged,
          onDaihyoEnchoCountChanged: onDaihyoEnchoCountChanged,
          onDaihyoEnchoUnlimitedChanged: onDaihyoEnchoUnlimitedChanged,
          onDaihyoHanteiChanged: onDaihyoHanteiChanged,
          onRenseikaiTypeChanged: onRenseikaiTypeChanged,
          onOverallTimeChanged: onOverallTimeChanged,
          onKachinukiChanged: onKachinukiChanged,
          onKachinukiUnlimitedTypeChanged: onKachinukiUnlimitedTypeChanged,
          onLeagueChanged: onLeagueChanged,
          onWinPointChanged: onWinPointChanged,
          onLossPointChanged: onLossPointChanged,
          onDrawPointChanged: onDrawPointChanged,
        ),
      ],
    );
  }
}
