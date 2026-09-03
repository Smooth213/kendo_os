import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_form_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';

/// 部門別ルールのフォームセクション（通常戦 / 上位戦）構築ビルダー
class CategoryRuleFormSectionBuilder {
  const CategoryRuleFormSectionBuilder._();

  static Widget build({
    required CategoryRuleEditorView view,
    required String title,
    required bool isNormal,
  }) {
    return CategoryRuleFormSection(
      title: title,
      isNormal: isNormal,
      themeColors: view.themeColors,
      matchType: view.editingMatchType,
      isRenseikai: view.editingIsRenseikai,
      categoryKey: view.category,
      matchTime: isNormal ? view.normalTime : view.advancedTime,
      isRunningTime: isNormal
          ? view.normalIsRunningTime
          : view.advancedIsRunningTime,
      ipponLimit: isNormal ? view.normalIpponLimit : view.advancedIpponLimit,
      hansokuLimit: isNormal
          ? view.normalHansokuLimit
          : view.advancedHansokuLimit,
      hasHantei: isNormal ? view.normalHasHantei : view.advancedHasHantei,
      hasExtension: isNormal
          ? view.normalHasExtension
          : view.advancedHasExtension,
      isEnchoUnlimited: isNormal
          ? view.normalIsEnchoUnlimited
          : view.advancedIsEnchoUnlimited,
      enchoTime: isNormal ? view.normalEnchoTime : view.advancedEnchoTime,
      enchoCount: isNormal ? view.normalEnchoCount : view.advancedEnchoCount,
      kachinukiUnlimitedType: isNormal
          ? view.normalKachinukiUnlimitedType
          : view.advancedKachinukiUnlimitedType,
      hasLeagueDaihyo: isNormal
          ? view.normalHasLeagueDaihyo
          : view.advancedHasLeagueDaihyo,
      isDaihyoIpponShobu: isNormal
          ? view.normalIsDaihyoIpponShobu
          : view.advancedIsDaihyoIpponShobu,
      winPoint: isNormal ? view.normalWinPoint : view.advancedWinPoint,
      lossPoint: isNormal ? view.normalLossPoint : view.advancedLossPoint,
      drawPoint: isNormal ? view.normalDrawPoint : view.advancedDrawPoint,
      renseikaiType: isNormal
          ? view.normalRenseikaiType
          : view.advancedRenseikaiType,
      overallTime: isNormal ? view.normalOverallTime : view.advancedOverallTime,
      daihyoMatchTime: isNormal
          ? view.normalDaihyoMatchTime
          : view.advancedDaihyoMatchTime,
      daihyoHasExtension: isNormal
          ? view.normalDaihyoHasExtension
          : view.advancedDaihyoHasExtension,
      daihyoEnchoTime: isNormal
          ? view.normalDaihyoEnchoTime
          : view.advancedDaihyoEnchoTime,
      daihyoEnchoCount: isNormal
          ? view.normalDaihyoEnchoCount
          : view.advancedDaihyoEnchoCount,
      daihyoHasHantei: isNormal
          ? view.normalDaihyoHasHantei
          : view.advancedDaihyoHasHantei,
      keywordsController: isNormal ? null : view.keywordsController,
      formatMinutes: CategoryRuleMatchHelper.formatMinutes,
      onMatchTimeChanged: isNormal
          ? view.onNormalMatchTimeChanged
          : view.onAdvancedMatchTimeChanged,
      onIsRunningTimeChanged: isNormal
          ? view.onNormalIsRunningTimeChanged
          : view.onAdvancedIsRunningTimeChanged,
      onRenseikaiTypeChanged: isNormal
          ? view.onNormalRenseikaiTypeChanged
          : view.onAdvancedRenseikaiTypeChanged,
      onOverallTimeChanged: isNormal
          ? view.onNormalOverallTimeChanged
          : view.onAdvancedOverallTimeChanged,
      onKachinukiUnlimitedTypeChanged: isNormal
          ? view.onNormalKachinukiUnlimitedTypeChanged
          : view.onAdvancedKachinukiUnlimitedTypeChanged,
      onHasExtensionChanged: isNormal
          ? view.onNormalHasExtensionChanged
          : view.onAdvancedHasExtensionChanged,
      onIsEnchoUnlimitedChanged: isNormal
          ? view.onNormalIsEnchoUnlimitedChanged
          : view.onAdvancedIsEnchoUnlimitedChanged,
      onEnchoCountChanged: isNormal
          ? view.onNormalEnchoCountChanged
          : view.onAdvancedEnchoCountChanged,
      onEnchoTimeChanged: isNormal
          ? view.onNormalEnchoTimeChanged
          : view.onAdvancedEnchoTimeChanged,
      onHasHanteiChanged: isNormal
          ? view.onNormalHasHanteiChanged
          : view.onAdvancedHasHanteiChanged,
      onHasLeagueDaihyoChanged: isNormal
          ? view.onNormalHasLeagueDaihyoChanged
          : view.onAdvancedHasLeagueDaihyoChanged,
      onIsDaihyoIpponShobuChanged: isNormal
          ? view.onNormalIsDaihyoIpponShobuChanged
          : view.onAdvancedIsDaihyoIpponShobuChanged,
      onDaihyoMatchTimeChanged: isNormal
          ? view.onNormalDaihyoMatchTimeChanged
          : view.onAdvancedDaihyoMatchTimeChanged,
      onDaihyoHasExtensionChanged: isNormal
          ? view.onNormalDaihyoHasExtensionChanged
          : view.onAdvancedDaihyoHasExtensionChanged,
      onDaihyoEnchoTimeChanged: isNormal
          ? view.onNormalDaihyoEnchoTimeChanged
          : view.onAdvancedDaihyoEnchoTimeChanged,
      onDaihyoEnchoCountChanged: isNormal
          ? view.onNormalDaihyoEnchoCountChanged
          : view.onAdvancedDaihyoEnchoCountChanged,
      onDaihyoHasHanteiChanged: isNormal
          ? view.onNormalDaihyoHasHanteiChanged
          : view.onAdvancedDaihyoHasHanteiChanged,
      onWinPointChanged: isNormal
          ? view.onNormalWinPointChanged
          : view.onAdvancedWinPointChanged,
      onLossPointChanged: isNormal
          ? view.onNormalLossPointChanged
          : view.onAdvancedLossPointChanged,
      onDrawPointChanged: isNormal
          ? view.onNormalDrawPointChanged
          : view.onAdvancedDrawPointChanged,
      onIpponLimitChanged: isNormal
          ? view.onNormalIpponLimitChanged
          : view.onAdvancedIpponLimitChanged,
      onHansokuLimitChanged: isNormal
          ? view.onNormalHansokuLimitChanged
          : view.onAdvancedHansokuLimitChanged,
      onKeywordsChanged: view.onKeywordsChanged,
    );
  }
}
