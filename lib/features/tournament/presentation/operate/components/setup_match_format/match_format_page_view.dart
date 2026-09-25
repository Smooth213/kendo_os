import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_category_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_section_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 対戦フォーマット設定の PageView（カテゴリ選択ステップ ＆ ルール選択ステップ）
class MatchFormatPageView extends StatelessWidget {
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final String tournamentId;
  final String category;
  final MatchFormatFormState state;
  final AppThemeColors themeColors;
  final bool isDark;
  final bool isCurrentMatchAdvanced;
  final TextEditingController courtController;
  final TextEditingController noteController;
  final TextEditingController winPointController;
  final TextEditingController lossPointController;
  final TextEditingController drawPointController;
  final TextEditingController overallTimeController;
  final void Function(String major, String minor) onCategoryChanged;
  final ValueChanged<TeamModel> onTeamSelected;
  final Future<void> Function(TeamModel team) onEditTeam;
  final Future<void> Function(TeamModel team) onDeleteTeam;
  final void Function(String ruleKey, String scene, CategoryRuleSet ruleSet)
  onRuleSelected;
  final void Function(String scene, CategoryRuleSet ruleSet)
  onRuleSceneSelected;
  final ValueChanged<String> onSetManualRoundType;
  final ValueChanged<String> onHeadingPresetToggled;
  final VoidCallback onClearCourt;

  const MatchFormatPageView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.tournamentId,
    required this.category,
    required this.state,
    required this.themeColors,
    required this.isDark,
    required this.isCurrentMatchAdvanced,
    required this.courtController,
    required this.noteController,
    required this.winPointController,
    required this.lossPointController,
    required this.drawPointController,
    required this.overallTimeController,
    required this.onCategoryChanged,
    required this.onTeamSelected,
    required this.onEditTeam,
    required this.onDeleteTeam,
    required this.onRuleSelected,
    required this.onRuleSceneSelected,
    required this.onSetManualRoundType,
    required this.onHeadingPresetToggled,
    required this.onClearCourt,
  });

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: onPageChanged,
      children: [
        MatchFormatCategoryStep(
          tournamentId: tournamentId,
          category: category,
          selectedMajorCategory: state.selectedMajorCategory,
          selectedMinorCategory: state.selectedMinorCategory,
          selectedTeamId: state.selectedTeamId,
          majorCategories: MatchFormatSetupHelper.majorCategories,
          getMinorCategories: MatchFormatSetupHelper.getMinorCategories,
          onCategoryChanged: onCategoryChanged,
          onTeamSelected: onTeamSelected,
          onAdjustOrder: onEditTeam,
          onEditTeam: onEditTeam,
          onDeleteTeam: onDeleteTeam,
          onNavigateToTeamRegistration: () =>
              context.push('/team-registration/$tournamentId?initialPage=2'),
          themeColors: themeColors,
          isDark: isDark,
          buildSectionTitle: (t) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              t,
              style: TextStyle(
                fontSize: AppFontSize.subhead,
                fontWeight: AppFontWeight.bold,
                color: themeColors.primaryAccent,
              ),
            ),
          ),
        ),
        MatchFormatRuleStep(
          tournamentId: tournamentId,
          category: category,
          selectedRuleScene: state.selectedRuleScene,
          selectedRuleKey: state.selectedRuleKey,
          isCurrentMatchAdvanced: isCurrentMatchAdvanced,
          hasExtension: state.hasExtension,
          extTime: state.extTime,
          extCount: state.extCount,
          matchTime: state.matchTime,
          isRunningTime: state.isRunningTime,
          isRenseikai: state.isRenseikai,
          renseikaiType: state.renseikaiType,
          matchType: state.matchType,
          isIpponShobu: state.isIpponShobu,
          ipponLimit: state.ipponLimit,
          hansokuLimit: state.hansokuLimit,
          hasHantei: state.hasHantei,
          kachinukiUnlimitedType: state.kachinukiUnlimitedType,
          hasLeagueDaihyo: state.hasLeagueDaihyo,
          isDaihyoIpponShobu: state.isDaihyoIpponShobu,
          daihyoMatchTime: state.daihyoMatchTime,
          daihyoHasExtension: state.daihyoHasExtension,
          daihyoEnchoCount: state.daihyoEnchoCount,
          daihyoEnchoTime: state.daihyoEnchoTime,
          daihyoHasHantei: state.daihyoHasHantei,
          winPoint: double.tryParse(winPointController.text) ?? 0,
          lossPoint: double.tryParse(lossPointController.text) ?? 0,
          drawPoint: double.tryParse(drawPointController.text) ?? 0,
          overallTimeMinutes: int.tryParse(overallTimeController.text) ?? 30,
          courtController: courtController,
          noteController: noteController,
          themeColors: themeColors,
          onRuleSelected: onRuleSelected,
          onRuleSceneSelected: onRuleSceneSelected,
          onSetManualRoundType: onSetManualRoundType,
          onHeadingPresetToggled: onHeadingPresetToggled,
          onClearCourt: onClearCourt,
          buildTextFieldDecoration:
              ({required labelText, hintText, prefixIcon, suffixText}) =>
                  MatchFormatSetupHelper.buildTextFieldDecoration(
                    themeColors: themeColors,
                    labelText: labelText,
                    hintText: hintText,
                    prefixIcon: prefixIcon,
                    suffixText: suffixText,
                  ),
          buildSectionHeader: (title, accent) =>
              MatchFormatSectionHeader(title: title, accentColor: accent),
          formatMinutesText: CategoryRuleMatchHelper.formatMinutes,
        ),
      ],
    );
  }
}
