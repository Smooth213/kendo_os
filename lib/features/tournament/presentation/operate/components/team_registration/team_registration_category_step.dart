import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 🏆 チーム登録: 出場カテゴリ・試合形式選択ステップ（PAGE 1）
class TeamRegistrationCategoryStep extends StatelessWidget {
  final String selectedMajorCategory;
  final String selectedMinorCategory;
  final String selectedCategory;
  final String matchType;
  final bool showExtraMajorCategories;
  final bool showExtraMatchTypes;
  final AppThemeColors themeColors;
  final ValueChanged<String> onMajorCategoryChanged;
  final ValueChanged<String> onMinorCategoryChanged;
  final ValueChanged<String> onMatchTypeChanged;
  final VoidCallback onToggleExtraMajorCategories;
  final VoidCallback onToggleExtraMatchTypes;

  static const List<String> mainMajorCategories = ['初心者', '幼年', '小学生', '中学生'];
  static const List<String> extraMajorCategories = ['高校生', '大学・一般'];

  static const List<String> mainMatchTypes = [
    '団体戦（5人制）',
    '団体戦（3人制）',
    '勝ち抜き戦',
    '個人戦',
  ];
  static const List<String> extraMatchTypes = [
    'リーグ団体戦',
    'リーグ個人戦',
    '団体戦（7人制）',
    '団体戦（それ以上）',
  ];

  const TeamRegistrationCategoryStep({
    super.key,
    required this.selectedMajorCategory,
    required this.selectedMinorCategory,
    required this.selectedCategory,
    required this.matchType,
    required this.showExtraMajorCategories,
    required this.showExtraMatchTypes,
    required this.themeColors,
    required this.onMajorCategoryChanged,
    required this.onMinorCategoryChanged,
    required this.onMatchTypeChanged,
    required this.onToggleExtraMajorCategories,
    required this.onToggleExtraMatchTypes,
  });

  static List<String> getMinorCategories(String major) {
    if (major == '初心者' || major == '幼年') {
      return ['全体', '男子', '女子'];
    }
    if (major == '小学生') {
      return [
        '全体',
        '低学年',
        '高学年',
        '1年',
        '2年',
        '3年',
        '4年',
        '5年',
        '6年',
        '男子',
        '女子',
      ];
    }
    if (major == '中学生' || major == '高校生') {
      return ['全体', '1年', '2年', '3年', '男子', '女子'];
    }
    if (major == '大学・一般') {
      return ['全体', '大学生', '一般', 'シニア', '男子', '女子'];
    }
    return ['全体'];
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppFontSize.subhead,
          fontWeight: AppFontWeight.bold,
          color: themeColors.primaryAccent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.appColors.textColor;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(
          '出場するカテゴリと\n試合形式を選んでください',
          style: TextStyle(
            fontSize: AppFontSize.titleLarge,
            fontWeight: AppFontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // 1. 出場カテゴリ（大分類）
        _buildSectionTitle('1. 出場カテゴリ（大分類）'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...mainMajorCategories.map(
              (cat) => AppChoiceChip(
                label: Text(cat),
                selected: selectedMajorCategory == cat,
                onSelected: (s) => s ? onMajorCategoryChanged(cat) : null,
              ),
            ),
            if (showExtraMajorCategories)
              ...extraMajorCategories.map(
                (cat) => AppChoiceChip(
                  label: Text(cat),
                  selected: selectedMajorCategory == cat,
                  onSelected: (s) => s ? onMajorCategoryChanged(cat) : null,
                ),
              ),
            AppActionChip(
              icon: showExtraMajorCategories
                  ? Icons.expand_less
                  : Icons.expand_more,
              label: Text(showExtraMajorCategories ? '閉じる' : 'もっと見る'),
              onPressed: onToggleExtraMajorCategories,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // 2. 出場カテゴリ（小分類）
        _buildSectionTitle('2. 出場カテゴリ（小分類）'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: getMinorCategories(selectedMajorCategory).map((cat) {
            String label = cat;
            if (selectedMajorCategory == '小学生') {
              if (cat == '低学年') {
                label = '低学年 (1-4年)';
              }
              if (cat == '高学年') {
                label = '高学年 (5-6年)';
              }
            }
            return AppChoiceChip(
              label: Text(label),
              selected: selectedMinorCategory == cat,
              onSelected: (s) => s ? onMinorCategoryChanged(cat) : null,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 生成されるカテゴリ名のプレビュー表示
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: themeColors.softAccent,
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: themeColors.primaryAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: themeColors.primaryAccent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '生成されるカテゴリ名',
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        color: themeColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      selectedCategory,
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: AppFontSize.headline,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // 3. 試合形式
        _buildSectionTitle('3. 試合形式'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...mainMatchTypes.map(
              (type) => AppChoiceChip(
                label: Text(type),
                selected: matchType == type,
                onSelected: (s) => s ? onMatchTypeChanged(type) : null,
              ),
            ),
            if (showExtraMatchTypes)
              ...extraMatchTypes.map(
                (type) => AppChoiceChip(
                  label: Text(type),
                  selected: matchType == type,
                  onSelected: (s) => s ? onMatchTypeChanged(type) : null,
                ),
              ),
            AppActionChip(
              icon: showExtraMatchTypes ? Icons.expand_less : Icons.expand_more,
              label: Text(showExtraMatchTypes ? '閉じる' : 'もっと見る'),
              onPressed: onToggleExtraMatchTypes,
            ),
          ],
        ),
      ],
    );
  }
}
