import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_summary_card.dart';

/// 部門別詳細ルール確認ボトムシート（純粋UIコンポーネント）
class CategoryRuleDetailBottomSheet extends StatelessWidget {
  final String categoryName;
  final CategoryRuleSet ruleSet;
  final bool isDark;

  const CategoryRuleDetailBottomSheet({
    super.key,
    required this.categoryName,
    required this.ruleSet,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required String categoryName,
    required CategoryRuleSet ruleSet,
    required bool isDark,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => CategoryRuleDetailBottomSheet(
        categoryName: categoryName,
        ruleSet: ruleSet,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        final List<Widget> sections = [];

        if (ruleSet.isMultiScene) {
          if (ruleSet.useRenseikaiRule) {
            sections.add(
              CategoryRuleSummaryCard(
                title:
                    '${KendoSceneHelper.getIconLabel(KendoMatchScene.renseikai)}ルール',
                rule: ruleSet.renseikaiRule,
                accentColor: KendoSceneHelper.getColor(
                  KendoMatchScene.renseikai,
                  isDark: isDark,
                ),
                matchType: '錬成',
                isDark: isDark,
              ),
            );
          }
          if (ruleSet.useHonsenRule) {
            if (sections.isNotEmpty) {
              sections.add(const Divider(height: 32));
            }
            sections.add(
              CategoryRuleSummaryCard(
                title:
                    '${KendoSceneHelper.getIconLabel(KendoMatchScene.honsen)}ルール',
                rule: ruleSet.normalRule,
                accentColor: KendoSceneHelper.getColor(
                  KendoMatchScene.honsen,
                  isDark: isDark,
                ),
                matchType: ruleSet.matchType,
                isDark: isDark,
              ),
            );
          }
          if (ruleSet.useMoushiawaseRule) {
            if (sections.isNotEmpty) {
              sections.add(const Divider(height: 32));
            }
            sections.add(
              CategoryRuleSummaryCard(
                title:
                    '${KendoSceneHelper.getIconLabel(KendoMatchScene.moushiawase)}ルール',
                rule: ruleSet.moushiawaseRule,
                accentColor: KendoSceneHelper.getColor(
                  KendoMatchScene.moushiawase,
                  isDark: isDark,
                ),
                matchType: '錬成',
                isDark: isDark,
              ),
            );
          }
        } else {
          sections.add(
            CategoryRuleSummaryCard(
              title: '通常戦ルール',
              rule: ruleSet.normalRule,
              accentColor: themeColors.primaryAccent,
              matchType: ruleSet.matchType,
              isDark: isDark,
            ),
          );

          if (ruleSet.useAdvancedRule) {
            sections.add(const SizedBox(height: AppSpacing.sm));
            sections.add(const Divider());
            sections.add(
              CategoryRuleSummaryCard(
                title: '上位戦（準決勝・決勝等）ルール',
                rule: ruleSet.advancedRule,
                accentColor: themeColors.primaryAccent,
                matchType: ruleSet.matchType,
                isDark: isDark,
              ),
            );
            sections.add(const SizedBox(height: AppSpacing.sm));
            sections.add(
              CategoryRuleSummaryCard.buildDetailRow(
                context,
                '上位戦 適用ワード',
                ruleSet.advancedKeywords.join('、'),
                isDark,
              ),
            );
          }
        }

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(
                    top: AppSpacing.compact,
                    bottom: AppSpacing.roundValue,
                  ),
                  decoration: BoxDecoration(
                    color: themeColors.separatorColor,
                    borderRadius: AppRadius.capsule,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.gavel_rounded,
                    color: themeColors.primaryAccent,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '$categoryName のルール設定',
                      style: TextStyle(
                        fontSize: AppFontSize.headline,
                        fontWeight: AppFontWeight.bold,
                        color: themeColors.textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              ...sections,

              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColors.separatorColor,
                    foregroundColor: themeColors.textColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                  child: const Text(
                    '閉じる',
                    style: TextStyle(fontWeight: AppFontWeight.semiBold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
