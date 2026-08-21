import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_advanced_tabs_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_bottom_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_form_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_multi_scene_tabs_card.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 部門別ルール編集ビュー
class CategoryRuleEditorView extends StatelessWidget {
  final String category;
  final AppThemeColors themeColors;
  final bool enableLiquidGlass;

  // 全般設定
  final String editingMatchType;
  final bool isMultiScene;
  final bool useAdvancedRule;
  final bool editingIsRenseikai;
  final ValueChanged<String> onMatchTypeChanged;
  final ValueChanged<bool> onMultiSceneChanged;
  final ValueChanged<bool> onUseAdvancedRuleChanged;

  // マルチシーン設定
  final bool useRenseikaiRule;
  final bool useHonsenRule;
  final bool useMoushiawaseRule;
  final double renseikaiTime;
  final bool renseikaiIsRunningTime;
  final bool renseikaiHasHantei;
  final String renseikaiType;
  final int renseikaiOverallTime;
  final double moushiawaseTime;
  final bool moushiawaseIsRunningTime;
  final bool moushiawaseHasHantei;
  final String moushiawaseType;
  final int moushiawaseOverallTime;

  final ValueChanged<bool> onUseRenseikaiRuleChanged;
  final ValueChanged<bool> onUseHonsenRuleChanged;
  final ValueChanged<bool> onUseMoushiawaseRuleChanged;
  final ValueChanged<double> onRenseikaiTimeChanged;
  final ValueChanged<bool> onRenseikaiRunningChanged;
  final ValueChanged<bool> onRenseikaiHanteiChanged;
  final ValueChanged<String> onRenseikaiTypeChanged;
  final ValueChanged<int> onRenseikaiOverallTimeChanged;
  final ValueChanged<double> onMoushiawaseTimeChanged;
  final ValueChanged<bool> onMoushiawaseRunningChanged;
  final ValueChanged<bool> onMoushiawaseHanteiChanged;
  final ValueChanged<String> onMoushiawaseTypeChanged;
  final ValueChanged<int> onMoushiawaseOverallTimeChanged;

  // 通常戦ルールパラメータ
  final double normalTime;
  final bool normalIsRunningTime;
  final int normalIpponLimit;
  final int normalHansokuLimit;
  final bool normalHasHantei;
  final bool normalHasExtension;
  final bool normalIsEnchoUnlimited;
  final double normalEnchoTime;
  final int normalEnchoCount;
  final String normalKachinukiUnlimitedType;
  final bool normalHasLeagueDaihyo;
  final bool normalIsDaihyoIpponShobu;
  final double normalWinPoint;
  final double normalLossPoint;
  final double normalDrawPoint;
  final String normalRenseikaiType;
  final int normalOverallTime;
  final double normalDaihyoMatchTime;
  final bool normalDaihyoHasExtension;
  final double normalDaihyoEnchoTime;
  final int normalDaihyoEnchoCount;
  final bool normalDaihyoHasHantei;

  // 上位戦ルールパラメータ
  final double advancedTime;
  final bool advancedIsRunningTime;
  final int advancedIpponLimit;
  final int advancedHansokuLimit;
  final bool advancedHasHantei;
  final bool advancedHasExtension;
  final bool advancedIsEnchoUnlimited;
  final double advancedEnchoTime;
  final int advancedEnchoCount;
  final String advancedKachinukiUnlimitedType;
  final bool advancedHasLeagueDaihyo;
  final bool advancedIsDaihyoIpponShobu;
  final double advancedWinPoint;
  final double advancedLossPoint;
  final double advancedDrawPoint;
  final String advancedRenseikaiType;
  final int advancedOverallTime;
  final double advancedDaihyoMatchTime;
  final bool advancedDaihyoHasExtension;
  final double advancedDaihyoEnchoTime;
  final int advancedDaihyoEnchoCount;
  final bool advancedDaihyoHasHantei;
  final TextEditingController keywordsController;

  // ルール変更コールバック (通常戦)
  final ValueChanged<double> onNormalMatchTimeChanged;
  final ValueChanged<bool> onNormalIsRunningTimeChanged;
  final ValueChanged<String> onNormalRenseikaiTypeChanged;
  final ValueChanged<int> onNormalOverallTimeChanged;
  final ValueChanged<String> onNormalKachinukiUnlimitedTypeChanged;
  final ValueChanged<bool> onNormalHasExtensionChanged;
  final ValueChanged<bool> onNormalIsEnchoUnlimitedChanged;
  final ValueChanged<int> onNormalEnchoCountChanged;
  final ValueChanged<double> onNormalEnchoTimeChanged;
  final ValueChanged<bool> onNormalHasHanteiChanged;
  final ValueChanged<bool> onNormalHasLeagueDaihyoChanged;
  final ValueChanged<bool> onNormalIsDaihyoIpponShobuChanged;
  final ValueChanged<double> onNormalDaihyoMatchTimeChanged;
  final ValueChanged<bool> onNormalDaihyoHasExtensionChanged;
  final ValueChanged<double> onNormalDaihyoEnchoTimeChanged;
  final ValueChanged<int> onNormalDaihyoEnchoCountChanged;
  final ValueChanged<bool> onNormalDaihyoHasHanteiChanged;
  final ValueChanged<double> onNormalWinPointChanged;
  final ValueChanged<double> onNormalLossPointChanged;
  final ValueChanged<double> onNormalDrawPointChanged;
  final ValueChanged<int> onNormalIpponLimitChanged;
  final ValueChanged<int> onNormalHansokuLimitChanged;

  // ルール変更コールバック (上位戦)
  final ValueChanged<double> onAdvancedMatchTimeChanged;
  final ValueChanged<bool> onAdvancedIsRunningTimeChanged;
  final ValueChanged<String> onAdvancedRenseikaiTypeChanged;
  final ValueChanged<int> onAdvancedOverallTimeChanged;
  final ValueChanged<String> onAdvancedKachinukiUnlimitedTypeChanged;
  final ValueChanged<bool> onAdvancedHasExtensionChanged;
  final ValueChanged<bool> onAdvancedIsEnchoUnlimitedChanged;
  final ValueChanged<int> onAdvancedEnchoCountChanged;
  final ValueChanged<double> onAdvancedEnchoTimeChanged;
  final ValueChanged<bool> onAdvancedHasHanteiChanged;
  final ValueChanged<bool> onAdvancedHasLeagueDaihyoChanged;
  final ValueChanged<bool> onAdvancedIsDaihyoIpponShobuChanged;
  final ValueChanged<double> onAdvancedDaihyoMatchTimeChanged;
  final ValueChanged<bool> onAdvancedDaihyoHasExtensionChanged;
  final ValueChanged<double> onAdvancedDaihyoEnchoTimeChanged;
  final ValueChanged<int> onAdvancedDaihyoEnchoCountChanged;
  final ValueChanged<bool> onAdvancedDaihyoHasHanteiChanged;
  final ValueChanged<double> onAdvancedWinPointChanged;
  final ValueChanged<double> onAdvancedLossPointChanged;
  final ValueChanged<double> onAdvancedDrawPointChanged;
  final ValueChanged<int> onAdvancedIpponLimitChanged;
  final ValueChanged<int> onAdvancedHansokuLimitChanged;
  final ValueChanged<List<String>> onKeywordsChanged;

  final VoidCallback onCancel;
  final VoidCallback onSave;

  const CategoryRuleEditorView({
    super.key,
    required this.category,
    required this.themeColors,
    required this.enableLiquidGlass,
    required this.editingMatchType,
    required this.isMultiScene,
    required this.useAdvancedRule,
    required this.editingIsRenseikai,
    required this.onMatchTypeChanged,
    required this.onMultiSceneChanged,
    required this.onUseAdvancedRuleChanged,
    required this.useRenseikaiRule,
    required this.useHonsenRule,
    required this.useMoushiawaseRule,
    required this.renseikaiTime,
    required this.renseikaiIsRunningTime,
    required this.renseikaiHasHantei,
    required this.renseikaiType,
    required this.renseikaiOverallTime,
    required this.moushiawaseTime,
    required this.moushiawaseIsRunningTime,
    required this.moushiawaseHasHantei,
    required this.moushiawaseType,
    required this.moushiawaseOverallTime,
    required this.onUseRenseikaiRuleChanged,
    required this.onUseHonsenRuleChanged,
    required this.onUseMoushiawaseRuleChanged,
    required this.onRenseikaiTimeChanged,
    required this.onRenseikaiRunningChanged,
    required this.onRenseikaiHanteiChanged,
    required this.onRenseikaiTypeChanged,
    required this.onRenseikaiOverallTimeChanged,
    required this.onMoushiawaseTimeChanged,
    required this.onMoushiawaseRunningChanged,
    required this.onMoushiawaseHanteiChanged,
    required this.onMoushiawaseTypeChanged,
    required this.onMoushiawaseOverallTimeChanged,
    required this.normalTime,
    required this.normalIsRunningTime,
    required this.normalIpponLimit,
    required this.normalHansokuLimit,
    required this.normalHasHantei,
    required this.normalHasExtension,
    required this.normalIsEnchoUnlimited,
    required this.normalEnchoTime,
    required this.normalEnchoCount,
    required this.normalKachinukiUnlimitedType,
    required this.normalHasLeagueDaihyo,
    required this.normalIsDaihyoIpponShobu,
    required this.normalWinPoint,
    required this.normalLossPoint,
    required this.normalDrawPoint,
    required this.normalRenseikaiType,
    required this.normalOverallTime,
    required this.normalDaihyoMatchTime,
    required this.normalDaihyoHasExtension,
    required this.normalDaihyoEnchoTime,
    required this.normalDaihyoEnchoCount,
    required this.normalDaihyoHasHantei,
    required this.advancedTime,
    required this.advancedIsRunningTime,
    required this.advancedIpponLimit,
    required this.advancedHansokuLimit,
    required this.advancedHasHantei,
    required this.advancedHasExtension,
    required this.advancedIsEnchoUnlimited,
    required this.advancedEnchoTime,
    required this.advancedEnchoCount,
    required this.advancedKachinukiUnlimitedType,
    required this.advancedHasLeagueDaihyo,
    required this.advancedIsDaihyoIpponShobu,
    required this.advancedWinPoint,
    required this.advancedLossPoint,
    required this.advancedDrawPoint,
    required this.advancedRenseikaiType,
    required this.advancedOverallTime,
    required this.advancedDaihyoMatchTime,
    required this.advancedDaihyoHasExtension,
    required this.advancedDaihyoEnchoTime,
    required this.advancedDaihyoEnchoCount,
    required this.advancedDaihyoHasHantei,
    required this.keywordsController,
    required this.onNormalMatchTimeChanged,
    required this.onNormalIsRunningTimeChanged,
    required this.onNormalRenseikaiTypeChanged,
    required this.onNormalOverallTimeChanged,
    required this.onNormalKachinukiUnlimitedTypeChanged,
    required this.onNormalHasExtensionChanged,
    required this.onNormalIsEnchoUnlimitedChanged,
    required this.onNormalEnchoCountChanged,
    required this.onNormalEnchoTimeChanged,
    required this.onNormalHasHanteiChanged,
    required this.onNormalHasLeagueDaihyoChanged,
    required this.onNormalIsDaihyoIpponShobuChanged,
    required this.onNormalDaihyoMatchTimeChanged,
    required this.onNormalDaihyoHasExtensionChanged,
    required this.onNormalDaihyoEnchoTimeChanged,
    required this.onNormalDaihyoEnchoCountChanged,
    required this.onNormalDaihyoHasHanteiChanged,
    required this.onNormalWinPointChanged,
    required this.onNormalLossPointChanged,
    required this.onNormalDrawPointChanged,
    required this.onNormalIpponLimitChanged,
    required this.onNormalHansokuLimitChanged,
    required this.onAdvancedMatchTimeChanged,
    required this.onAdvancedIsRunningTimeChanged,
    required this.onAdvancedRenseikaiTypeChanged,
    required this.onAdvancedOverallTimeChanged,
    required this.onAdvancedKachinukiUnlimitedTypeChanged,
    required this.onAdvancedHasExtensionChanged,
    required this.onAdvancedIsEnchoUnlimitedChanged,
    required this.onAdvancedEnchoCountChanged,
    required this.onAdvancedEnchoTimeChanged,
    required this.onAdvancedHasHanteiChanged,
    required this.onAdvancedHasLeagueDaihyoChanged,
    required this.onAdvancedIsDaihyoIpponShobuChanged,
    required this.onAdvancedDaihyoMatchTimeChanged,
    required this.onAdvancedDaihyoHasExtensionChanged,
    required this.onAdvancedDaihyoEnchoTimeChanged,
    required this.onAdvancedDaihyoEnchoCountChanged,
    required this.onAdvancedDaihyoHasHanteiChanged,
    required this.onAdvancedWinPointChanged,
    required this.onAdvancedLossPointChanged,
    required this.onAdvancedDrawPointChanged,
    required this.onAdvancedIpponLimitChanged,
    required this.onAdvancedHansokuLimitChanged,
    required this.onKeywordsChanged,
    required this.onCancel,
    required this.onSave,
  });

  Widget _buildFormSection(String title, bool isNormal) {
    return CategoryRuleFormSection(
      title: title,
      isNormal: isNormal,
      themeColors: themeColors,
      matchType: editingMatchType,
      isRenseikai: editingIsRenseikai,
      categoryKey: category,
      matchTime: isNormal ? normalTime : advancedTime,
      isRunningTime: isNormal ? normalIsRunningTime : advancedIsRunningTime,
      ipponLimit: isNormal ? normalIpponLimit : advancedIpponLimit,
      hansokuLimit: isNormal ? normalHansokuLimit : advancedHansokuLimit,
      hasHantei: isNormal ? normalHasHantei : advancedHasHantei,
      hasExtension: isNormal ? normalHasExtension : advancedHasExtension,
      isEnchoUnlimited: isNormal
          ? normalIsEnchoUnlimited
          : advancedIsEnchoUnlimited,
      enchoTime: isNormal ? normalEnchoTime : advancedEnchoTime,
      enchoCount: isNormal ? normalEnchoCount : advancedEnchoCount,
      kachinukiUnlimitedType: isNormal
          ? normalKachinukiUnlimitedType
          : advancedKachinukiUnlimitedType,
      hasLeagueDaihyo: isNormal
          ? normalHasLeagueDaihyo
          : advancedHasLeagueDaihyo,
      isDaihyoIpponShobu: isNormal
          ? normalIsDaihyoIpponShobu
          : advancedIsDaihyoIpponShobu,
      winPoint: isNormal ? normalWinPoint : advancedWinPoint,
      lossPoint: isNormal ? normalLossPoint : advancedLossPoint,
      drawPoint: isNormal ? normalDrawPoint : advancedDrawPoint,
      renseikaiType: isNormal ? normalRenseikaiType : advancedRenseikaiType,
      overallTime: isNormal ? normalOverallTime : advancedOverallTime,
      daihyoMatchTime: isNormal
          ? normalDaihyoMatchTime
          : advancedDaihyoMatchTime,
      daihyoHasExtension: isNormal
          ? normalDaihyoHasExtension
          : advancedDaihyoHasExtension,
      daihyoEnchoTime: isNormal
          ? normalDaihyoEnchoTime
          : advancedDaihyoEnchoTime,
      daihyoEnchoCount: isNormal
          ? normalDaihyoEnchoCount
          : advancedDaihyoEnchoCount,
      daihyoHasHantei: isNormal
          ? normalDaihyoHasHantei
          : advancedDaihyoHasHantei,
      keywordsController: isNormal ? null : keywordsController,
      formatMinutes: CategoryRuleMatchHelper.formatMinutes,
      onMatchTimeChanged: isNormal
          ? onNormalMatchTimeChanged
          : onAdvancedMatchTimeChanged,
      onIsRunningTimeChanged: isNormal
          ? onNormalIsRunningTimeChanged
          : onAdvancedIsRunningTimeChanged,
      onRenseikaiTypeChanged: isNormal
          ? onNormalRenseikaiTypeChanged
          : onAdvancedRenseikaiTypeChanged,
      onOverallTimeChanged: isNormal
          ? onNormalOverallTimeChanged
          : onAdvancedOverallTimeChanged,
      onKachinukiUnlimitedTypeChanged: isNormal
          ? onNormalKachinukiUnlimitedTypeChanged
          : onAdvancedKachinukiUnlimitedTypeChanged,
      onHasExtensionChanged: isNormal
          ? onNormalHasExtensionChanged
          : onAdvancedHasExtensionChanged,
      onIsEnchoUnlimitedChanged: isNormal
          ? onNormalIsEnchoUnlimitedChanged
          : onAdvancedIsEnchoUnlimitedChanged,
      onEnchoCountChanged: isNormal
          ? onNormalEnchoCountChanged
          : onAdvancedEnchoCountChanged,
      onEnchoTimeChanged: isNormal
          ? onNormalEnchoTimeChanged
          : onAdvancedEnchoTimeChanged,
      onHasHanteiChanged: isNormal
          ? onNormalHasHanteiChanged
          : onAdvancedHasHanteiChanged,
      onHasLeagueDaihyoChanged: isNormal
          ? onNormalHasLeagueDaihyoChanged
          : onAdvancedHasLeagueDaihyoChanged,
      onIsDaihyoIpponShobuChanged: isNormal
          ? onNormalIsDaihyoIpponShobuChanged
          : onAdvancedIsDaihyoIpponShobuChanged,
      onDaihyoMatchTimeChanged: isNormal
          ? onNormalDaihyoMatchTimeChanged
          : onAdvancedDaihyoMatchTimeChanged,
      onDaihyoHasExtensionChanged: isNormal
          ? onNormalDaihyoHasExtensionChanged
          : onAdvancedDaihyoHasExtensionChanged,
      onDaihyoEnchoTimeChanged: isNormal
          ? onNormalDaihyoEnchoTimeChanged
          : onAdvancedDaihyoEnchoTimeChanged,
      onDaihyoEnchoCountChanged: isNormal
          ? onNormalDaihyoEnchoCountChanged
          : onAdvancedDaihyoEnchoCountChanged,
      onDaihyoHasHanteiChanged: isNormal
          ? onNormalDaihyoHasHanteiChanged
          : onAdvancedDaihyoHasHanteiChanged,
      onWinPointChanged: isNormal
          ? onNormalWinPointChanged
          : onAdvancedWinPointChanged,
      onLossPointChanged: isNormal
          ? onNormalLossPointChanged
          : onAdvancedLossPointChanged,
      onDrawPointChanged: isNormal
          ? onNormalDrawPointChanged
          : onAdvancedDrawPointChanged,
      onIpponLimitChanged: isNormal
          ? onNormalIpponLimitChanged
          : onAdvancedIpponLimitChanged,
      onHansokuLimitChanged: isNormal
          ? onNormalHansokuLimitChanged
          : onAdvancedHansokuLimitChanged,
      onKeywordsChanged: onKeywordsChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.roundValue),
            children: [
              CategoryRuleEditorHeaderCard(
                category: category,
                textColor: themeColors.textColor,
                matchType: editingMatchType,
                isMultiScene: isMultiScene,
                useAdvancedRule: useAdvancedRule,
                onMatchTypeChanged: onMatchTypeChanged,
                onMultiSceneChanged: onMultiSceneChanged,
                onUseAdvancedRuleChanged: onUseAdvancedRuleChanged,
              ),
              if (isMultiScene) ...[
                CategoryRuleMultiSceneTabsCard(
                  useRenseikaiRule: useRenseikaiRule,
                  useHonsenRule: useHonsenRule,
                  useMoushiawaseRule: useMoushiawaseRule,
                  renseikaiTime: renseikaiTime,
                  renseikaiIsRunningTime: renseikaiIsRunningTime,
                  renseikaiHasHantei: renseikaiHasHantei,
                  renseikaiType: renseikaiType,
                  renseikaiOverallTime: renseikaiOverallTime,
                  moushiawaseTime: moushiawaseTime,
                  moushiawaseIsRunningTime: moushiawaseIsRunningTime,
                  moushiawaseHasHantei: moushiawaseHasHantei,
                  moushiawaseType: moushiawaseType,
                  moushiawaseOverallTime: moushiawaseOverallTime,
                  honsenRuleSection: _buildFormSection('🏆 本戦ルール', true),
                  onUseRenseikaiRuleChanged: onUseRenseikaiRuleChanged,
                  onUseHonsenRuleChanged: onUseHonsenRuleChanged,
                  onUseMoushiawaseRuleChanged: onUseMoushiawaseRuleChanged,
                  onRenseikaiTimeChanged: onRenseikaiTimeChanged,
                  onRenseikaiRunningChanged: onRenseikaiRunningChanged,
                  onRenseikaiHanteiChanged: onRenseikaiHanteiChanged,
                  onRenseikaiTypeChanged: onRenseikaiTypeChanged,
                  onRenseikaiOverallTimeChanged: onRenseikaiOverallTimeChanged,
                  onMoushiawaseTimeChanged: onMoushiawaseTimeChanged,
                  onMoushiawaseRunningChanged: onMoushiawaseRunningChanged,
                  onMoushiawaseHanteiChanged: onMoushiawaseHanteiChanged,
                  onMoushiawaseTypeChanged: onMoushiawaseTypeChanged,
                  onMoushiawaseOverallTimeChanged:
                      onMoushiawaseOverallTimeChanged,
                ),
              ] else if (!useAdvancedRule) ...[
                _buildFormSection('通常戦（本戦）ルール', true),
              ] else ...[
                CategoryRuleAdvancedTabsCard(
                  normalRuleSection: _buildFormSection('通常戦ルール', true),
                  advancedRuleSection: _buildFormSection('上位戦ルール', false),
                ),
              ],
            ],
          ),
        ),
        CategoryRuleEditorBottomBar(
          enableLiquidGlass: enableLiquidGlass,
          onCancel: onCancel,
          onSave: onSave,
        ),
      ],
    );
  }
}
