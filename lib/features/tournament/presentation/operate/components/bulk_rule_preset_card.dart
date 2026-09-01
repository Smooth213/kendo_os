import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 一括ルール編集シートにおける「部門別ルールから一括セット」プリセット選択カード（純粋UIコンポーネント）
class BulkRulePresetCard extends StatelessWidget {
  final Map<String, CategoryRuleSet> categoryRules;
  final String? selectedCategoryRuleName;
  final String selectedSceneType;
  final Color primaryAccent;
  final bool isDark;
  final Color textColor;
  final void Function(String catName, CategoryRuleSet ruleSet) onSelectCategory;
  final void Function(String sceneKey, MatchRule targetRule) onSelectScene;

  const BulkRulePresetCard({
    super.key,
    required this.categoryRules,
    required this.selectedCategoryRuleName,
    required this.selectedSceneType,
    required this.primaryAccent,
    required this.isDark,
    required this.textColor,
    required this.onSelectCategory,
    required this.onSelectScene,
  });

  String _formatRuleSummary(MatchRule r) {
    final timeStr = r.matchTimeMinutes.truncateToDouble() == r.matchTimeMinutes
        ? r.matchTimeMinutes.toInt().toString()
        : r.matchTimeMinutes.toString();
    final formatStr = r.isIpponShobu ? '1本' : '3本';
    return '$timeStr分・$formatStr';
  }

  Widget _buildSceneSubChip({
    required String sceneKey,
    required String label,
    required MatchRule targetRule,
  }) {
    final isSelected = selectedSceneType == sceneKey;
    return AppChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelectScene(sceneKey, targetRule);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (categoryRules.isEmpty) return const SizedBox.shrink();

    final selectedRuleSet = selectedCategoryRuleName != null
        ? categoryRules[selectedCategoryRuleName]
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: primaryAccent.withAlpha(isDark ? 25 : 12),
        borderRadius: AppRadius.large,
        border: Border.all(color: primaryAccent.withAlpha(isDark ? 80 : 40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: primaryAccent),
              const SizedBox(width: 6),
              Text(
                '試合ルール設定から一括セット',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 1段目: 部門名選択チップ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categoryRules.entries.map((entry) {
                final catName = entry.key;
                final ruleSet = entry.value;
                final isSel = selectedCategoryRuleName == catName;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppChoiceChip(
                    label: Text(catName),
                    selected: isSel,
                    onSelected: (selected) {
                      if (selected) {
                        onSelectCategory(catName, ruleSet);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // 2段目: 選択中部門のシーンサブチップ（本戦・錬成・申合せ・決勝戦）
          if (selectedRuleSet != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '試合シーン・ルール用途を選択:',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                fontWeight: AppFontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 1) 本戦 (通常)
                  if (selectedRuleSet.useHonsenRule)
                    _buildSceneSubChip(
                      sceneKey: 'normal',
                      label:
                          '🏆 本戦 (${_formatRuleSummary(selectedRuleSet.normalRule)})',
                      targetRule: selectedRuleSet.normalRule,
                    ),

                  // 2) 錬成 (練習試合)
                  if (selectedRuleSet.useRenseikaiRule) ...[
                    const SizedBox(width: 6),
                    _buildSceneSubChip(
                      sceneKey: 'renseikai',
                      label:
                          '⚔️ 錬成 (${_formatRuleSummary(selectedRuleSet.renseikaiRule)})',
                      targetRule: selectedRuleSet.renseikaiRule,
                    ),
                  ],

                  // 3) 申合せ
                  if (selectedRuleSet.useMoushiawaseRule) ...[
                    const SizedBox(width: 6),
                    _buildSceneSubChip(
                      sceneKey: 'moushiawase',
                      label:
                          '🤝 申合せ (${_formatRuleSummary(selectedRuleSet.moushiawaseRule)})',
                      targetRule: selectedRuleSet.moushiawaseRule,
                    ),
                  ],

                  // 4) 決勝・準決勝
                  if (selectedRuleSet.useAdvancedRule) ...[
                    const SizedBox(width: 6),
                    _buildSceneSubChip(
                      sceneKey: 'advanced',
                      label:
                          '🔥 決勝・準決勝 (${_formatRuleSummary(selectedRuleSet.advancedRule)})',
                      targetRule: selectedRuleSet.advancedRule,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
