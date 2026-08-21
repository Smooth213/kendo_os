import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_advanced_settings_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_individual_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_renseikai_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_team_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_time_stepper_tile.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// ルール入力フォームセクション（通常戦 / 上位戦）
class CategoryRuleFormSection extends StatelessWidget {
  final String title;
  final bool isNormal;
  final AppThemeColors themeColors;
  final String matchType;
  final bool isRenseikai;
  final String categoryKey;

  final double matchTime;
  final bool isRunningTime;
  final int ipponLimit;
  final int hansokuLimit;
  final bool hasHantei;
  final bool hasExtension;
  final bool isEnchoUnlimited;
  final double enchoTime;
  final int enchoCount;
  final String kachinukiUnlimitedType;
  final bool hasLeagueDaihyo;
  final bool isDaihyoIpponShobu;
  final double winPoint;
  final double lossPoint;
  final double drawPoint;
  final String renseikaiType;
  final int overallTime;

  final double daihyoMatchTime;
  final bool daihyoHasExtension;
  final double daihyoEnchoTime;
  final int daihyoEnchoCount;
  final bool daihyoHasHantei;

  final TextEditingController? keywordsController;
  final String Function(double) formatMinutes;

  final ValueChanged<double> onMatchTimeChanged;
  final ValueChanged<bool> onIsRunningTimeChanged;
  final ValueChanged<String> onRenseikaiTypeChanged;
  final ValueChanged<int> onOverallTimeChanged;
  final ValueChanged<String> onKachinukiUnlimitedTypeChanged;

  final ValueChanged<bool> onHasExtensionChanged;
  final ValueChanged<bool> onIsEnchoUnlimitedChanged;
  final ValueChanged<int> onEnchoCountChanged;
  final ValueChanged<double> onEnchoTimeChanged;
  final ValueChanged<bool> onHasHanteiChanged;

  final ValueChanged<bool> onHasLeagueDaihyoChanged;
  final ValueChanged<bool> onIsDaihyoIpponShobuChanged;
  final ValueChanged<double> onDaihyoMatchTimeChanged;
  final ValueChanged<bool> onDaihyoHasExtensionChanged;
  final ValueChanged<double> onDaihyoEnchoTimeChanged;
  final ValueChanged<int> onDaihyoEnchoCountChanged;
  final ValueChanged<bool> onDaihyoHasHanteiChanged;

  final ValueChanged<double> onWinPointChanged;
  final ValueChanged<double> onLossPointChanged;
  final ValueChanged<double> onDrawPointChanged;

  final ValueChanged<int> onIpponLimitChanged;
  final ValueChanged<int> onHansokuLimitChanged;
  final ValueChanged<List<String>> onKeywordsChanged;

  const CategoryRuleFormSection({
    super.key,
    required this.title,
    required this.isNormal,
    required this.themeColors,
    required this.matchType,
    required this.isRenseikai,
    required this.categoryKey,
    required this.matchTime,
    required this.isRunningTime,
    required this.ipponLimit,
    required this.hansokuLimit,
    required this.hasHantei,
    required this.hasExtension,
    required this.isEnchoUnlimited,
    required this.enchoTime,
    required this.enchoCount,
    required this.kachinukiUnlimitedType,
    required this.hasLeagueDaihyo,
    required this.isDaihyoIpponShobu,
    required this.winPoint,
    required this.lossPoint,
    required this.drawPoint,
    required this.renseikaiType,
    required this.overallTime,
    required this.daihyoMatchTime,
    required this.daihyoHasExtension,
    required this.daihyoEnchoTime,
    required this.daihyoEnchoCount,
    required this.daihyoHasHantei,
    this.keywordsController,
    required this.formatMinutes,
    required this.onMatchTimeChanged,
    required this.onIsRunningTimeChanged,
    required this.onRenseikaiTypeChanged,
    required this.onOverallTimeChanged,
    required this.onKachinukiUnlimitedTypeChanged,
    required this.onHasExtensionChanged,
    required this.onIsEnchoUnlimitedChanged,
    required this.onEnchoCountChanged,
    required this.onEnchoTimeChanged,
    required this.onHasHanteiChanged,
    required this.onHasLeagueDaihyoChanged,
    required this.onIsDaihyoIpponShobuChanged,
    required this.onDaihyoMatchTimeChanged,
    required this.onDaihyoHasExtensionChanged,
    required this.onDaihyoEnchoTimeChanged,
    required this.onDaihyoEnchoCountChanged,
    required this.onDaihyoHasHanteiChanged,
    required this.onWinPointChanged,
    required this.onLossPointChanged,
    required this.onDrawPointChanged,
    required this.onIpponLimitChanged,
    required this.onHansokuLimitChanged,
    required this.onKeywordsChanged,
  });

  Widget _buildSectionHeader(String headerTitle) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppKendoColors.indigo.withValues(alpha: 0.1),
        borderRadius: AppRadius.small,
      ),
      child: Text(
        headerTitle,
        style: const TextStyle(
          fontSize: AppFontSize.subhead,
          fontWeight: AppFontWeight.bold,
          color: AppKendoColors.indigo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIndividual = matchType == '個人戦' || matchType == 'リーグ個人戦';
    final isTeam = matchType == '団体戦' || matchType == 'リーグ団体戦';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        const SizedBox(height: AppSpacing.lg),

        // 1. 共通: 試合時間設定
        CategoryTimeStepperTile(
          title: '試合時間',
          subtitle: '30秒単位で自由に増減できます',
          value: matchTime,
          minValue: 0.5,
          maxValue: 15.0,
          step: 0.5,
          primaryColor: themeColors.primaryAccent,
          onChanged: onMatchTimeChanged,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            'クイック選択',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0].map((t) {
            final isSelected = matchTime == t;
            return AppChoiceChip(
              label: Text(formatMinutes(t)),
              selected: isSelected,
              onSelected: (s) {
                if (s) onMatchTimeChanged(t);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // === 形式別表示 ===
        if (isRenseikai || matchType == '勝ち抜き戦')
          CategoryRuleRenseikaiSection(
            isRenseikai: isRenseikai,
            isKachinuki: matchType == '勝ち抜き戦',
            isNormal: isNormal,
            categoryKey: categoryKey,
            isRunningTime: isRunningTime,
            renseikaiType: renseikaiType,
            overallTime: overallTime,
            kachinukiUnlimitedType: kachinukiUnlimitedType,
            onIsRunningTimeChanged: onIsRunningTimeChanged,
            onRenseikaiTypeChanged: onRenseikaiTypeChanged,
            onOverallTimeChanged: onOverallTimeChanged,
            onKachinukiUnlimitedTypeChanged: onKachinukiUnlimitedTypeChanged,
          )
        else if (isIndividual)
          CategoryRuleIndividualSection(
            isLeague: matchType == 'リーグ個人戦',
            isNormal: isNormal,
            categoryKey: categoryKey,
            themeColors: themeColors,
            hasExtension: hasExtension,
            isEnchoUnlimited: isEnchoUnlimited,
            enchoCount: enchoCount,
            enchoTime: enchoTime,
            hasHantei: hasHantei,
            winPoint: winPoint,
            lossPoint: lossPoint,
            drawPoint: drawPoint,
            onHasExtensionChanged: onHasExtensionChanged,
            onIsEnchoUnlimitedChanged: onIsEnchoUnlimitedChanged,
            onEnchoCountChanged: onEnchoCountChanged,
            onEnchoTimeChanged: onEnchoTimeChanged,
            onHasHanteiChanged: onHasHanteiChanged,
            onWinPointChanged: onWinPointChanged,
            onLossPointChanged: onLossPointChanged,
            onDrawPointChanged: onDrawPointChanged,
          )
        else if (isTeam)
          CategoryRuleTeamSection(
            isLeague: matchType == 'リーグ団体戦',
            isNormal: isNormal,
            categoryKey: categoryKey,
            themeColors: themeColors,
            hasLeagueDaihyo: hasLeagueDaihyo,
            isDaihyoIpponShobu: isDaihyoIpponShobu,
            daihyoMatchTime: daihyoMatchTime,
            daihyoHasExtension: daihyoHasExtension,
            daihyoEnchoTime: daihyoEnchoTime,
            daihyoEnchoCount: daihyoEnchoCount,
            daihyoHasHantei: daihyoHasHantei,
            winPoint: winPoint,
            lossPoint: lossPoint,
            drawPoint: drawPoint,
            onHasLeagueDaihyoChanged: onHasLeagueDaihyoChanged,
            onIsDaihyoIpponShobuChanged: onIsDaihyoIpponShobuChanged,
            onDaihyoMatchTimeChanged: onDaihyoMatchTimeChanged,
            onDaihyoHasExtensionChanged: onDaihyoHasExtensionChanged,
            onDaihyoEnchoTimeChanged: onDaihyoEnchoTimeChanged,
            onDaihyoEnchoCountChanged: onDaihyoEnchoCountChanged,
            onDaihyoHasHanteiChanged: onDaihyoHasHanteiChanged,
            onWinPointChanged: onWinPointChanged,
            onLossPointChanged: onLossPointChanged,
            onDrawPointChanged: onDrawPointChanged,
            formatMinutes: formatMinutes,
          ),

        // 2. 詳細設定（得点制限、反則数など）＆ 上位戦キーワード設定
        CategoryRuleAdvancedSettingsSection(
          isNormal: isNormal,
          categoryKey: categoryKey,
          ipponLimit: ipponLimit,
          hansokuLimit: hansokuLimit,
          keywordsController: keywordsController,
          onIpponLimitChanged: onIpponLimitChanged,
          onHansokuLimitChanged: onHansokuLimitChanged,
          onKeywordsChanged: onKeywordsChanged,
        ),
      ],
    );
  }
}
