import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_heading_and_note_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_summary_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

class MatchFormatRuleStep extends ConsumerWidget {
  final String tournamentId;
  final String category;
  final String selectedRuleScene;
  final bool isCurrentMatchAdvanced;
  final bool hasExtension;
  final double extTime;
  final int extCount;
  final double matchTime;
  final bool isRunningTime;
  final bool isRenseikai;
  final String renseikaiType;
  final String matchType;
  final bool isIpponShobu;
  final int ipponLimit;
  final int hansokuLimit;
  final bool hasHantei;
  final String kachinukiUnlimitedType;
  final bool hasLeagueDaihyo;
  final bool isDaihyoIpponShobu;
  final double daihyoMatchTime;
  final bool daihyoHasExtension;
  final int daihyoEnchoCount;
  final double daihyoEnchoTime;
  final bool daihyoHasHantei;
  final double winPoint;
  final double lossPoint;
  final double drawPoint;
  final int overallTimeMinutes;
  final TextEditingController courtController;
  final TextEditingController noteController;
  final AppThemeColors themeColors;
  final void Function(String scene, CategoryRuleSet ruleSet)
  onRuleSceneSelected;
  final void Function(String type) onSetManualRoundType;
  final void Function(String heading) onHeadingPresetToggled;
  final VoidCallback onClearCourt;
  final InputDecoration Function({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    String? suffixText,
  })
  buildTextFieldDecoration;
  final Widget Function(String title, Color accentColor) buildSectionHeader;
  final String Function(double minutes) formatMinutesText;

  const MatchFormatRuleStep({
    super.key,
    required this.tournamentId,
    required this.category,
    required this.selectedRuleScene,
    required this.isCurrentMatchAdvanced,
    required this.hasExtension,
    required this.extTime,
    required this.extCount,
    required this.matchTime,
    required this.isRunningTime,
    required this.isRenseikai,
    required this.renseikaiType,
    required this.matchType,
    required this.isIpponShobu,
    required this.ipponLimit,
    required this.hansokuLimit,
    required this.hasHantei,
    required this.kachinukiUnlimitedType,
    required this.hasLeagueDaihyo,
    required this.isDaihyoIpponShobu,
    required this.daihyoMatchTime,
    required this.daihyoHasExtension,
    required this.daihyoEnchoCount,
    required this.daihyoEnchoTime,
    required this.daihyoHasHantei,
    required this.winPoint,
    required this.lossPoint,
    required this.drawPoint,
    required this.overallTimeMinutes,
    required this.courtController,
    required this.noteController,
    required this.themeColors,
    required this.onRuleSceneSelected,
    required this.onSetManualRoundType,
    required this.onHeadingPresetToggled,
    required this.onClearCourt,
    required this.buildTextFieldDecoration,
    required this.buildSectionHeader,
    required this.formatMinutesText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;

    final categoryName = category;
    final asyncTourney = ref.watch(tournamentProvider(tournamentId));
    final tournament = asyncTourney.valueOrNull;
    final ruleSet = CategoryRuleMatchHelper.findRuleSetForCategoryAndType(
      tournament?.categoryRules ?? {},
      categoryName,
      matchType: matchType,
    );

    final displayRuleName = selectedRuleScene == 'renseikai'
        ? '⚔️ 錬成会ルール'
        : (selectedRuleScene == 'moushiawase'
              ? '🤝 申し合わせルール'
              : (selectedRuleScene == 'advanced'
                    ? '⭐ 上位戦ルール'
                    : '🏆 本戦（通常戦）ルール'));

    final isAdvanced =
        selectedRuleScene == 'advanced' || isCurrentMatchAdvanced;

    String getExtensionText() {
      if (!hasExtension) return 'なし';
      final extTimeStr = extTime == -2.0 ? '時間無制限' : formatMinutesText(extTime);
      final extCountStr = extCount == -2 ? '回数無制限' : '最大$extCount回';
      return 'あり ($extTimeStr / $extCountStr)';
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(
          '適用ルールの確認と\n詳細情報の入力',
          style: TextStyle(
            fontSize: AppFontSize.titleLarge,
            fontWeight: AppFontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (ruleSet != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.subValue),
            child: Text(
              'この部門（$categoryName）に設定されているルールを選択:',
              style: const TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.bodySmall,
                color: AppKendoColors.grey,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (ruleSet.isMultiScene) ...[
                if (ruleSet.useRenseikaiRule)
                  AppChoiceChip(
                    label: const Text('⚔️ 錬成会ルール'),
                    selected: selectedRuleScene == 'renseikai',
                    onSelected: (selected) {
                      if (selected) {
                        onRuleSceneSelected('renseikai', ruleSet);
                      }
                    },
                  ),
                if (ruleSet.useHonsenRule)
                  AppChoiceChip(
                    label: const Text('🏆 本戦ルール'),
                    selected: selectedRuleScene == 'honsen',
                    onSelected: (selected) {
                      if (selected) {
                        onRuleSceneSelected('honsen', ruleSet);
                      }
                    },
                  ),
                if (ruleSet.useMoushiawaseRule)
                  AppChoiceChip(
                    label: const Text('🤝 申し合わせルール'),
                    selected: selectedRuleScene == 'moushiawase',
                    onSelected: (selected) {
                      if (selected) {
                        onRuleSceneSelected('moushiawase', ruleSet);
                      }
                    },
                  ),
              ] else if (ruleSet.useHonsenRule) ...[
                AppChoiceChip(
                  label: const Text('🏆 通常戦ルール'),
                  selected: selectedRuleScene == 'honsen',
                  onSelected: (selected) {
                    if (selected) {
                      onRuleSceneSelected('honsen', ruleSet);
                    }
                  },
                ),
              ],
              if (ruleSet.useAdvancedRule)
                AppChoiceChip(
                  label: const Text('⭐ 上位戦ルール'),
                  selected: selectedRuleScene == 'advanced',
                  onSelected: (selected) {
                    if (selected) onRuleSceneSelected('advanced', ruleSet);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        MatchFormatRuleSummaryCard(
          displayRuleName: displayRuleName,
          isAdvanced: isAdvanced,
          themeColors: themeColors,
          isRenseikai: isRenseikai,
          renseikaiType: renseikaiType,
          matchTime: matchTime,
          overallTimeMinutes: overallTimeMinutes.toString(),
          matchType: matchType,
          isRunningTime: isRunningTime,
          isIpponShobu: isIpponShobu,
          ipponLimit: ipponLimit,
          hansokuLimit: hansokuLimit,
          extensionText: getExtensionText(),
          hasHantei: hasHantei,
          kachinukiUnlimitedType: kachinukiUnlimitedType,
          hasLeagueDaihyo: hasLeagueDaihyo,
          isDaihyoIpponShobu: isDaihyoIpponShobu,
          daihyoMatchTime: daihyoMatchTime,
          daihyoHasExtension: daihyoHasExtension,
          daihyoEnchoCount: daihyoEnchoCount,
          daihyoEnchoTime: daihyoEnchoTime,
          daihyoHasHantei: daihyoHasHantei,
          winPoint: winPoint,
          lossPoint: lossPoint,
          drawPoint: drawPoint,
          formatMinutesText: formatMinutesText,
          buildSectionHeader: (title, color) =>
              buildSectionHeader(title, color),
        ),
        const SizedBox(height: AppSpacing.xl),

        // 適用ルールの手動切替トグル (useAdvancedRule が有効な場合のみ)
        Builder(
          builder: (context) {
            final asyncTourney = ref.watch(tournamentProvider(tournamentId));
            return asyncTourney.maybeWhen(
              data: (tournament) {
                if (tournament == null) return const SizedBox.shrink();
                final ruleSet = tournament.categoryRules[categoryName];
                if (ruleSet == null || !ruleSet.useAdvancedRule) {
                  return const SizedBox.shrink();
                }

                final isAdvancedToggle = isCurrentMatchAdvanced;

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
                              style: TextStyle(
                                fontWeight: AppFontWeight.semiBold,
                              ),
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
                              style: TextStyle(
                                fontWeight: AppFontWeight.semiBold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),

        MatchFormatHeadingAndNoteSection(
          courtController: courtController,
          noteController: noteController,
          themeColors: themeColors,
          isDark: isDark,
          onToggleHeadingPreset: onHeadingPresetToggled,
          buildTextFieldDecoration: buildTextFieldDecoration,
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
