import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_differing_banner.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_preset_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/match_rule_setting_form.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// ⚡ ルール一括変更シート用 ルール設定フォームセクション（プリセット選択 ＆ 全項目フォーム）
class BulkRuleFormSection extends StatelessWidget {
  final Map<String, CategoryRuleSet> categoryRules;
  final String? selectedCategoryRuleName;
  final String selectedSceneType;
  final Color primaryAccent;
  final bool isDark;
  final Color textColor;
  final bool hasDifferingRules;
  final bool isDantai;
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
  final TextEditingController overallTimeController;
  final bool isKachinuki;
  final String kachinukiUnlimitedType;
  final bool isLeague;
  final double winPoint;
  final double lossPoint;
  final double drawPoint;
  final void Function(String, CategoryRuleSet) onSelectCategory;
  final void Function(String, MatchRule) onSelectScene;
  final ValueChanged<double> onMatchTimeChanged;
  final ValueChanged<bool> onRunningTimeChanged;
  final ValueChanged<bool> onIpponShobuChanged;
  final ValueChanged<int> onIpponLimitChanged;
  final ValueChanged<int> onHansokuLimitChanged;
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
  final ValueChanged<int> onOverallTimeChanged;
  final ValueChanged<bool> onKachinukiChanged;
  final ValueChanged<String> onKachinukiUnlimitedTypeChanged;
  final ValueChanged<bool> onLeagueChanged;
  final ValueChanged<double> onWinPointChanged;
  final ValueChanged<double> onLossPointChanged;
  final ValueChanged<double> onDrawPointChanged;

  const BulkRuleFormSection({
    super.key,
    required this.categoryRules,
    required this.selectedCategoryRuleName,
    required this.selectedSceneType,
    required this.primaryAccent,
    required this.isDark,
    required this.textColor,
    required this.hasDifferingRules,
    required this.isDantai,
    required this.matchTime,
    required this.isRunningTime,
    required this.isIpponShobu,
    required this.ipponLimit,
    required this.hansokuLimit,
    required this.hasExtension,
    required this.enchoTime,
    required this.enchoCount,
    required this.isEnchoUnlimited,
    required this.hasHantei,
    required this.hasRepresentativeMatch,
    required this.isDaihyoIpponShobu,
    required this.daihyoMatchTime,
    required this.daihyoHasExtension,
    required this.daihyoEnchoTime,
    required this.daihyoEnchoCount,
    required this.isDaihyoEnchoUnlimited,
    required this.daihyoHasHantei,
    required this.renseikaiType,
    required this.overallTimeController,
    required this.isKachinuki,
    required this.kachinukiUnlimitedType,
    required this.isLeague,
    required this.winPoint,
    required this.lossPoint,
    required this.drawPoint,
    required this.onSelectCategory,
    required this.onSelectScene,
    required this.onMatchTimeChanged,
    required this.onRunningTimeChanged,
    required this.onIpponShobuChanged,
    required this.onIpponLimitChanged,
    required this.onHansokuLimitChanged,
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
    required this.onOverallTimeChanged,
    required this.onKachinukiChanged,
    required this.onKachinukiUnlimitedTypeChanged,
    required this.onLeagueChanged,
    required this.onWinPointChanged,
    required this.onLossPointChanged,
    required this.onDrawPointChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // STEP 2 ヘッダー
        Text(
          'STEP 2: 新しいルールを設定',
          style: TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.bold,
            color: primaryAccent,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 部門別ルールプリセット
        if (categoryRules.isNotEmpty) ...[
          BulkRulePresetCard(
            categoryRules: categoryRules,
            selectedCategoryRuleName: selectedCategoryRuleName,
            selectedSceneType: selectedSceneType,
            primaryAccent: primaryAccent,
            isDark: isDark,
            textColor: textColor,
            onSelectCategory: onSelectCategory,
            onSelectScene: onSelectScene,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (hasDifferingRules) ...[
          BulkRuleDifferingBanner(isDark: isDark),
          const SizedBox(height: AppSpacing.md),
        ],

        // 🥋 統一ルール設定フォーム
        MatchRuleSettingForm(
          isDantai: isDantai,
          selectedSceneKey: selectedSceneType == 'renseikai'
              ? 'renseikai'
              : (selectedSceneType == 'moushiawase' ? 'moushiawase' : 'honsen'),
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
