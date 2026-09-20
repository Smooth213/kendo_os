import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// ルール編集画面 対象部門情報 ＆ 試合方式 ＆ シーン/上位戦切り替えヘッダー
class CategoryRuleEditorHeaderCard extends StatelessWidget {
  final String category;
  final Color textColor;
  final String matchType;
  final bool isMultiScene;
  final bool useAdvancedRule;
  final TextEditingController subtitleController;
  final TextEditingController commentController;
  final Map<String, CategoryRuleSet>? allCategoryRules;
  final ValueChanged<String>? onSubtitleChanged;
  final ValueChanged<String>? onCommentChanged;
  final ValueChanged<String> onMatchTypeChanged;
  final ValueChanged<bool> onMultiSceneChanged;
  final ValueChanged<bool> onUseAdvancedRuleChanged;

  const CategoryRuleEditorHeaderCard({
    super.key,
    required this.category,
    required this.textColor,
    required this.matchType,
    required this.isMultiScene,
    required this.useAdvancedRule,
    required this.subtitleController,
    required this.commentController,
    this.allCategoryRules,
    this.onSubtitleChanged,
    this.onCommentChanged,
    required this.onMatchTypeChanged,
    required this.onMultiSceneChanged,
    required this.onUseAdvancedRuleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedCategory = allCategoryRules != null
        ? CategoryRuleMatchHelper.resolveDisplayCategory(
            category: category,
            subtitle: subtitleController.text,
            allCategoryRules: allCategoryRules!,
          )
        : category;
    final isSuffixOmitted = resolvedCategory != category;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppKendoColors.indigo.withValues(alpha: 0.05),
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: AppKendoColors.indigo.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppKendoColors.indigo),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '対象部門',
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        color: AppKendoColors.indigo,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          resolvedCategory,
                          style: TextStyle(
                            fontSize: AppFontSize.headline,
                            fontWeight: AppFontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (isSuffixOmitted) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.subValue,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppKendoColors.indigo.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: AppRadius.capsule,
                            ),
                            child: const Text(
                              '連番省略中',
                              style: TextStyle(
                                fontSize: AppFontSize.caption,
                                color: AppKendoColors.indigo,
                                fontWeight: AppFontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // サブタイトル入力欄
        AppTextField(
          controller: subtitleController,
          onChanged: onSubtitleChanged,
          decoration: InputDecoration(
            labelText: '🏷️ サブタイトル（任意）',
            hintText: '例: 決勝トーナメント、予選リーグ、第1コート用など',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            fillColor: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
            filled: true,
            helperText: subtitleController.text.trim().isNotEmpty
                ? '表示名プレビュー: ${CategoryRuleMatchHelper.formatDisplayTitle(category: category, subtitle: subtitleController.text, allCategoryRules: allCategoryRules)}'
                : '部門名の後ろに付与される名称です',
            helperStyle: TextStyle(
              color: subtitleController.text.trim().isNotEmpty
                  ? AppKendoColors.indigo
                  : null,
              fontWeight: subtitleController.text.trim().isNotEmpty
                  ? AppFontWeight.bold
                  : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // コメント入力欄
        AppTextField(
          controller: commentController,
          onChanged: onCommentChanged,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            labelText: '💬 ルールコメント・特記事項（任意）',
            hintText: '例: 3人制・代表戦あり、判定優先、竹刀36以下など',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            fillColor: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
            filled: true,
            helperText: 'ルール一覧や詳細シートに特記事項として表示されます',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          '試合方式',
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.body,
            color: AppKendoColors.indigo,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: matchType,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            fillColor: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
            filled: true,
          ),
          items: const [
            DropdownMenuItem(value: '個人戦', child: Text('個人戦')),
            DropdownMenuItem(value: '団体戦', child: Text('団体戦 (トーナメント)')),
            DropdownMenuItem(value: 'リーグ個人戦', child: Text('リーグ個人戦')),
            DropdownMenuItem(value: 'リーグ団体戦', child: Text('リーグ団体戦')),
            DropdownMenuItem(value: '勝ち抜き戦', child: Text('勝ち抜き戦 (団体戦)')),
          ],
          onChanged: (val) {
            if (val != null) onMatchTypeChanged(val);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            '⚔️ 遠征マルチシーンルール（錬成・本戦・申合せ）',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.subhead,
            ),
          ),
          subtitle: const Text('ONにすると、1つの部門に「錬成」「本戦」「申合せ」の各ルールを個別に定義できます。'),
          value: isMultiScene,
          activeThumbColor: AppKendoColors.ipponGold,
          onChanged: onMultiSceneChanged,
        ),
        const Divider(height: 16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            '準決勝・決勝は別ルールにする',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.subhead,
            ),
          ),
          subtitle: const Text('ONにすると、上位戦用の特別ルールを別途定義できます。'),
          value: useAdvancedRule,
          activeThumbColor: AppKendoColors.indigo,
          onChanged: onUseAdvancedRuleChanged,
        ),
        const Divider(height: 32),
      ],
    );
  }
}
