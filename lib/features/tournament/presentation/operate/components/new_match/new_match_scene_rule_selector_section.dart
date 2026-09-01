import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// ⚔️ 新規試合作成用 シーン別ルール選択セクション（純粋UIコンポーネント）
class NewMatchSceneRuleSelectorSection extends StatelessWidget {
  final Map<String, CategoryRuleSet> categoryRules;
  final String category;
  final String selectedScene;
  final ValueChanged<String> onSceneSelected;
  final bool isDark;

  const NewMatchSceneRuleSelectorSection({
    super.key,
    required this.categoryRules,
    required this.category,
    required this.selectedScene,
    required this.onSceneSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cleanCategory = category.trim();
    final ruleSet = CategoryRuleMatchHelper.findRuleSetForCategoryAndType(
      categoryRules,
      cleanCategory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '現在適用するルール（タップして選択）',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: AppKendoColors.grey,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            if (ruleSet != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: AppRadius.medium,
                  border: Border.all(color: context.appColors.primaryAccent),
                ),
                child: Text(
                  '部門ルール適用中: $cleanCategory',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: context.appColors.primaryAccent,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (ruleSet != null && ruleSet.isMultiScene) ...[
          _buildRuleCard(
            context: context,
            sceneId: 'renseikai',
            title: '⚔️ 錬成ルール（午前・練習試合）',
            subText:
                '時間: ${ruleSet.renseikaiRule.matchTimeMinutes.toStringAsFixed(0)}分 (${ruleSet.renseikaiRule.isRunningTime ? '流し' : '正式'}) / 引き分け: ${ruleSet.renseikaiRule.hasHantei ? 'あり' : 'なし'} / ${ruleSet.renseikaiRule.renseikaiType}',
            accentColor: KendoSceneHelper.getColor(
              KendoMatchScene.renseikai,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            context: context,
            sceneId: 'honsen',
            title: '🏆 本戦ルール（午後・トーナメント）',
            subText:
                '時間: ${ruleSet.normalRule.matchTimeMinutes.toStringAsFixed(0)}分 (${ruleSet.normalRule.isRunningTime ? '流し' : '正式'}) / 延長: ${ruleSet.normalRule.isEnchoUnlimited ? '無制限' : (ruleSet.normalRule.enchoCount > 0 ? 'あり' : 'なし')}',
            accentColor: KendoSceneHelper.getColor(
              KendoMatchScene.honsen,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            context: context,
            sceneId: 'moushiawase',
            title: '🤝 申合せルール（終了後・自由戦）',
            subText:
                '時間: ${ruleSet.moushiawaseRule.matchTimeMinutes.toStringAsFixed(0)}分 (${ruleSet.moushiawaseRule.isRunningTime ? '流し' : '正式'}) / 引き分け: ${ruleSet.moushiawaseRule.hasHantei ? 'あり' : 'なし'}',
            accentColor: KendoSceneHelper.getColor(
              KendoMatchScene.moushiawase,
              isDark: isDark,
            ),
          ),
        ] else if (ruleSet != null) ...[
          _buildRuleCard(
            context: context,
            sceneId: 'honsen',
            title: '🏆 本戦（通常戦）ルール',
            subText:
                '時間: ${ruleSet.normalRule.matchTimeMinutes.toStringAsFixed(0)}分 (${ruleSet.normalRule.isRunningTime ? '流し' : '正式'}) / 延長: ${ruleSet.normalRule.isEnchoUnlimited ? '無制限' : (ruleSet.normalRule.enchoCount > 0 ? 'あり' : 'なし')}',
            accentColor: KendoSceneHelper.getColor(
              KendoMatchScene.honsen,
              isDark: isDark,
            ),
          ),
        ] else ...[
          _buildRuleCard(
            context: context,
            sceneId: 'renseikai',
            title: '⚔️ 錬成（練習試合）',
            subText: '2分流し / 引き分けあり',
            accentColor: KendoSceneHelper.getColor(
              KendoMatchScene.renseikai,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            context: context,
            sceneId: 'honsen',
            title: '🏆 本戦（通常戦）',
            subText: '3分正式 / 代表戦・勝敗重視',
            accentColor: KendoSceneHelper.getColor(
              KendoMatchScene.honsen,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            context: context,
            sceneId: 'moushiawase',
            title: '🤝 申合せ（自由対戦）',
            subText: '2分流し / 引き分けあり',
            accentColor: KendoSceneHelper.getColor(
              KendoMatchScene.moushiawase,
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRuleCard({
    required BuildContext context,
    required String sceneId,
    required String title,
    required String subText,
    required Color accentColor,
  }) {
    final isSelected = selectedScene == sceneId;

    return Material(
      color: AppKendoColors.transparent,
      child: InkWell(
        onTap: () => onSceneSelected(sceneId),
        borderRadius: AppRadius.medium,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? accentColor.withValues(alpha: 0.25)
                      : accentColor.withValues(alpha: 0.08))
                : (isDark
                      ? context.appColors.cardBackground
                      : context.appColors.cardBackground.withValues(
                          alpha: 0.05,
                        )),
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark
                        ? context.appColors.separatorColor
                        : context.appColors.separatorColor.withValues(
                            alpha: 0.2,
                          )),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? accentColor : AppKendoColors.grey,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: AppFontWeight.bold,
                        color: isSelected
                            ? (isDark ? const Color(0xFFFFFFFF) : accentColor)
                            : (context.appColors.subTextColor),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subText,
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        color: isSelected
                            ? (isDark
                                  ? context.appColors.textColor.withValues(
                                      alpha: 0.7,
                                    )
                                  : accentColor)
                            : context.appColors.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
