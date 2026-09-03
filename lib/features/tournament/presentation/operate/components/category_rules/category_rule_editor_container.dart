import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_form_state.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// ルール編集ビューへのフォーム状態バインディングを担うコンテナWidget
class CategoryRuleEditorContainer extends StatelessWidget {
  final TournamentModel tournament;
  final String category;
  final AppThemeColors themeColors;
  final bool enableLiquidGlass;
  final CategoryRulesFormState formState;
  final TextEditingController keywordsController;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final void Function(void Function()) setState;

  const CategoryRuleEditorContainer({
    super.key,
    required this.tournament,
    required this.category,
    required this.themeColors,
    required this.enableLiquidGlass,
    required this.formState,
    required this.keywordsController,
    required this.onCancel,
    required this.onSave,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryRuleEditorView(
      category: category,
      themeColors: themeColors,
      enableLiquidGlass: enableLiquidGlass,
      editingMatchType: formState.editingMatchType,
      isMultiScene: formState.isMultiScene,
      useAdvancedRule: formState.useAdvancedRule,
      editingIsRenseikai: formState.editingIsRenseikai,
      onMatchTypeChanged: (val) =>
          setState(() => formState.editingMatchType = val),
      onMultiSceneChanged: (val) =>
          setState(() => formState.isMultiScene = val),
      onUseAdvancedRuleChanged: (val) =>
          setState(() => formState.useAdvancedRule = val),
      useRenseikaiRule: formState.useRenseikaiRule,
      useHonsenRule: formState.useHonsenRule,
      useMoushiawaseRule: formState.useMoushiawaseRule,
      renseikaiTime: formState.renseikaiTime,
      renseikaiIsRunningTime: formState.renseikaiIsRunningTime,
      renseikaiHasHantei: formState.renseikaiHasHantei,
      renseikaiType: formState.renseikaiType,
      renseikaiOverallTime: formState.renseikaiOverallTime,
      moushiawaseTime: formState.moushiawaseTime,
      moushiawaseIsRunningTime: formState.moushiawaseIsRunningTime,
      moushiawaseHasHantei: formState.moushiawaseHasHantei,
      moushiawaseType: formState.moushiawaseType,
      moushiawaseOverallTime: formState.moushiawaseOverallTime,
      onUseRenseikaiRuleChanged: (val) =>
          setState(() => formState.useRenseikaiRule = val),
      onUseHonsenRuleChanged: (val) =>
          setState(() => formState.useHonsenRule = val),
      onUseMoushiawaseRuleChanged: (val) =>
          setState(() => formState.useMoushiawaseRule = val),
      onRenseikaiTimeChanged: (val) =>
          setState(() => formState.renseikaiTime = val),
      onRenseikaiRunningChanged: (val) =>
          setState(() => formState.renseikaiIsRunningTime = val),
      onRenseikaiHanteiChanged: (val) =>
          setState(() => formState.renseikaiHasHantei = val),
      onRenseikaiTypeChanged: (val) =>
          setState(() => formState.renseikaiType = val),
      onRenseikaiOverallTimeChanged: (val) =>
          setState(() => formState.renseikaiOverallTime = val),
      onMoushiawaseTimeChanged: (val) =>
          setState(() => formState.moushiawaseTime = val),
      onMoushiawaseRunningChanged: (val) =>
          setState(() => formState.moushiawaseIsRunningTime = val),
      onMoushiawaseHanteiChanged: (val) =>
          setState(() => formState.moushiawaseHasHantei = val),
      onMoushiawaseTypeChanged: (val) =>
          setState(() => formState.moushiawaseType = val),
      onMoushiawaseOverallTimeChanged: (val) =>
          setState(() => formState.moushiawaseOverallTime = val),
      normalTime: formState.normalTime,
      normalIsRunningTime: formState.normalIsRunningTime,
      normalIpponLimit: formState.normalIpponLimit,
      normalHansokuLimit: formState.normalHansokuLimit,
      normalHasHantei: formState.normalHasHantei,
      normalHasExtension: formState.normalHasExtension,
      normalIsEnchoUnlimited: formState.normalIsEnchoUnlimited,
      normalEnchoTime: formState.normalEnchoTime,
      normalEnchoCount: formState.normalEnchoCount,
      normalKachinukiUnlimitedType: formState.normalKachinukiUnlimitedType,
      normalHasLeagueDaihyo: formState.normalHasLeagueDaihyo,
      normalIsDaihyoIpponShobu: formState.normalIsDaihyoIpponShobu,
      normalWinPoint: formState.normalWinPoint,
      normalLossPoint: formState.normalLossPoint,
      normalDrawPoint: formState.normalDrawPoint,
      normalRenseikaiType: formState.normalRenseikaiType,
      normalOverallTime: formState.normalOverallTime,
      normalDaihyoMatchTime: formState.normalDaihyoMatchTime,
      normalDaihyoHasExtension: formState.normalDaihyoHasExtension,
      normalDaihyoEnchoTime: formState.normalDaihyoEnchoTime,
      normalDaihyoEnchoCount: formState.normalDaihyoEnchoCount,
      normalDaihyoHasHantei: formState.normalDaihyoHasHantei,
      advancedTime: formState.advancedTime,
      advancedIsRunningTime: formState.advancedIsRunningTime,
      advancedIpponLimit: formState.advancedIpponLimit,
      advancedHansokuLimit: formState.advancedHansokuLimit,
      advancedHasHantei: formState.advancedHasHantei,
      advancedHasExtension: formState.advancedHasExtension,
      advancedIsEnchoUnlimited: formState.advancedIsEnchoUnlimited,
      advancedEnchoTime: formState.advancedEnchoTime,
      advancedEnchoCount: formState.advancedEnchoCount,
      advancedKachinukiUnlimitedType: formState.advancedKachinukiUnlimitedType,
      advancedHasLeagueDaihyo: formState.advancedHasLeagueDaihyo,
      advancedIsDaihyoIpponShobu: formState.advancedIsDaihyoIpponShobu,
      advancedWinPoint: formState.advancedWinPoint,
      advancedLossPoint: formState.advancedLossPoint,
      advancedDrawPoint: formState.advancedDrawPoint,
      advancedRenseikaiType: formState.advancedRenseikaiType,
      advancedOverallTime: formState.advancedOverallTime,
      advancedDaihyoMatchTime: formState.advancedDaihyoMatchTime,
      advancedDaihyoHasExtension: formState.advancedDaihyoHasExtension,
      advancedDaihyoEnchoTime: formState.advancedDaihyoEnchoTime,
      advancedDaihyoEnchoCount: formState.advancedDaihyoEnchoCount,
      advancedDaihyoHasHantei: formState.advancedDaihyoHasHantei,
      keywordsController: keywordsController,
      onNormalMatchTimeChanged: (val) =>
          setState(() => formState.normalTime = val),
      onNormalIsRunningTimeChanged: (val) =>
          setState(() => formState.normalIsRunningTime = val),
      onNormalRenseikaiTypeChanged: (val) =>
          setState(() => formState.normalRenseikaiType = val),
      onNormalOverallTimeChanged: (val) =>
          setState(() => formState.normalOverallTime = val),
      onNormalKachinukiUnlimitedTypeChanged: (val) =>
          setState(() => formState.normalKachinukiUnlimitedType = val),
      onNormalHasExtensionChanged: (val) =>
          setState(() => formState.normalHasExtension = val),
      onNormalIsEnchoUnlimitedChanged: (val) =>
          setState(() => formState.normalIsEnchoUnlimited = val),
      onNormalEnchoCountChanged: (val) =>
          setState(() => formState.normalEnchoCount = val),
      onNormalEnchoTimeChanged: (val) =>
          setState(() => formState.normalEnchoTime = val),
      onNormalHasHanteiChanged: (val) =>
          setState(() => formState.normalHasHantei = val),
      onNormalHasLeagueDaihyoChanged: (val) =>
          setState(() => formState.normalHasLeagueDaihyo = val),
      onNormalIsDaihyoIpponShobuChanged: (val) =>
          setState(() => formState.normalIsDaihyoIpponShobu = val),
      onNormalDaihyoMatchTimeChanged: (val) =>
          setState(() => formState.normalDaihyoMatchTime = val),
      onNormalDaihyoHasExtensionChanged: (val) =>
          setState(() => formState.normalDaihyoHasExtension = val),
      onNormalDaihyoEnchoTimeChanged: (val) =>
          setState(() => formState.normalDaihyoEnchoTime = val),
      onNormalDaihyoEnchoCountChanged: (val) =>
          setState(() => formState.normalDaihyoEnchoCount = val),
      onNormalDaihyoHasHanteiChanged: (val) =>
          setState(() => formState.normalDaihyoHasHantei = val),
      onNormalWinPointChanged: (val) =>
          setState(() => formState.normalWinPoint = val),
      onNormalLossPointChanged: (val) =>
          setState(() => formState.normalLossPoint = val),
      onNormalDrawPointChanged: (val) =>
          setState(() => formState.normalDrawPoint = val),
      onNormalIpponLimitChanged: (val) =>
          setState(() => formState.normalIpponLimit = val),
      onNormalHansokuLimitChanged: (val) =>
          setState(() => formState.normalHansokuLimit = val),
      onAdvancedMatchTimeChanged: (val) =>
          setState(() => formState.advancedTime = val),
      onAdvancedIsRunningTimeChanged: (val) =>
          setState(() => formState.advancedIsRunningTime = val),
      onAdvancedRenseikaiTypeChanged: (val) =>
          setState(() => formState.advancedRenseikaiType = val),
      onAdvancedOverallTimeChanged: (val) =>
          setState(() => formState.advancedOverallTime = val),
      onAdvancedKachinukiUnlimitedTypeChanged: (val) =>
          setState(() => formState.advancedKachinukiUnlimitedType = val),
      onAdvancedHasExtensionChanged: (val) =>
          setState(() => formState.advancedHasExtension = val),
      onAdvancedIsEnchoUnlimitedChanged: (val) =>
          setState(() => formState.advancedIsEnchoUnlimited = val),
      onAdvancedEnchoCountChanged: (val) =>
          setState(() => formState.advancedEnchoCount = val),
      onAdvancedEnchoTimeChanged: (val) =>
          setState(() => formState.advancedEnchoTime = val),
      onAdvancedHasHanteiChanged: (val) =>
          setState(() => formState.advancedHasHantei = val),
      onAdvancedHasLeagueDaihyoChanged: (val) =>
          setState(() => formState.advancedHasLeagueDaihyo = val),
      onAdvancedIsDaihyoIpponShobuChanged: (val) =>
          setState(() => formState.advancedIsDaihyoIpponShobu = val),
      onAdvancedDaihyoMatchTimeChanged: (val) =>
          setState(() => formState.advancedDaihyoMatchTime = val),
      onAdvancedDaihyoHasExtensionChanged: (val) =>
          setState(() => formState.advancedDaihyoHasExtension = val),
      onAdvancedDaihyoEnchoTimeChanged: (val) =>
          setState(() => formState.advancedDaihyoEnchoTime = val),
      onAdvancedDaihyoEnchoCountChanged: (val) =>
          setState(() => formState.advancedDaihyoEnchoCount = val),
      onAdvancedDaihyoHasHanteiChanged: (val) =>
          setState(() => formState.advancedDaihyoHasHantei = val),
      onAdvancedWinPointChanged: (val) =>
          setState(() => formState.advancedWinPoint = val),
      onAdvancedLossPointChanged: (val) =>
          setState(() => formState.advancedLossPoint = val),
      onAdvancedDrawPointChanged: (val) =>
          setState(() => formState.advancedDrawPoint = val),
      onAdvancedIpponLimitChanged: (val) =>
          setState(() => formState.advancedIpponLimit = val),
      onAdvancedHansokuLimitChanged: (val) =>
          setState(() => formState.advancedHansokuLimit = val),
      onKeywordsChanged: (kws) =>
          setState(() => formState.editingAdvancedKeywords = kws),
      onCancel: onCancel,
      onSave: onSave,
    );
  }
}
