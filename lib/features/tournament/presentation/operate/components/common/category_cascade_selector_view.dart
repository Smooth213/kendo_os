import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🏆 大分類 ＋ 直下連動サブコンテナの共通カテゴリセレクタ
class CategoryCascadeSelectorView extends StatelessWidget {
  final String selectedMajorCategory;
  final String selectedMinorCategory;
  final String customCategoryName;
  final Map<String, int>? registeredOtherCategoryCounts;
  final AppThemeColors themeColors;
  final void Function({
    required String majorCategory,
    required String minorCategory,
    String? customCategoryName,
  })
  onCategoryChanged;

  static const List<String> majorCategories = [
    '初心者',
    '幼年',
    '小学生',
    '中学生',
    '高校生',
    '大学・一般',
    'その他',
  ];

  const CategoryCascadeSelectorView({
    super.key,
    required this.selectedMajorCategory,
    required this.selectedMinorCategory,
    required this.themeColors,
    required this.onCategoryChanged,
    this.customCategoryName = '',
    this.registeredOtherCategoryCounts,
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
    if (major == 'その他') {
      return ['混成', '混合', '自由', '全体'];
    }
    return ['全体'];
  }

  /// 大分類・小分類・カスタム名から統一された正式カテゴリ名を生成
  static String buildCategoryName({
    required String major,
    required String minor,
    String? customName,
  }) {
    if (major == 'その他') {
      if (customName != null && customName.trim().isNotEmpty) {
        final clean = customName.trim();
        return clean.endsWith('の部') ? clean : '$cleanの部';
      }
      return minor == '全体' ? 'その他の部' : '$minorの部';
    }
    if (minor == '全体') {
      return '$majorの部';
    }
    return '$major$minorの部';
  }

  void _handleMajorSelected(String major) {
    if (major == selectedMajorCategory) return;
    final minors = getMinorCategories(major);
    String defaultMinor = '全体';
    if (major == '小学生') {
      defaultMinor = '低学年';
    } else if (major == 'その他') {
      defaultMinor = '混成';
    }
    onCategoryChanged(
      majorCategory: major,
      minorCategory: minors.contains(defaultMinor)
          ? defaultMinor
          : minors.first,
      customCategoryName: customCategoryName,
    );
  }

  void _handleMinorSelected(String minor) {
    onCategoryChanged(
      majorCategory: selectedMajorCategory,
      minorCategory: minor,
      customCategoryName: selectedMajorCategory == 'その他'
          ? ''
          : customCategoryName,
    );
  }

  void _handleRegisteredCategorySelected(String catName) {
    final cleanName = catName.replaceAll('の部', '').trim();
    final basicMinors = ['混成', '混合', '自由'];
    if (basicMinors.contains(cleanName)) {
      onCategoryChanged(
        majorCategory: 'その他',
        minorCategory: cleanName,
        customCategoryName: '',
      );
    } else if (cleanName == 'その他' || cleanName.isEmpty) {
      onCategoryChanged(
        majorCategory: 'その他',
        minorCategory: '全体',
        customCategoryName: '',
      );
    } else {
      onCategoryChanged(
        majorCategory: 'その他',
        minorCategory: '混成',
        customCategoryName: cleanName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = themeColors.primaryAccent;
    final minorList = getMinorCategories(selectedMajorCategory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 大分類チップ一覧
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: majorCategories.map((major) {
            final isSel = selectedMajorCategory == major;
            return AppChoiceChip(
              label: Text(major),
              selected: isSel,
              selectedColor: accentColor.withValues(alpha: 0.25),
              onSelected: (s) {
                if (s) _handleMajorSelected(major);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. 直下連動サブコンテナ（小分類）
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: themeColors.softAccent.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.mediumValue),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 登録済みその他カテゴリ一覧（実績が存在する場合のみ上段に表示）
              if (selectedMajorCategory == 'その他' &&
                  registeredOtherCategoryCounts != null &&
                  registeredOtherCategoryCounts!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.group, size: 16, color: accentColor),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '登録済みのカテゴリから選択：',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: registeredOtherCategoryCounts!.entries.map((entry) {
                    final catName = entry.key;
                    final count = entry.value;
                    final cleanRegistered = catName.replaceAll('の部', '').trim();
                    final currentFullCat = buildCategoryName(
                      major: selectedMajorCategory,
                      minor: selectedMinorCategory,
                      customName: customCategoryName,
                    );
                    final cleanCurrent = currentFullCat
                        .replaceAll('の部', '')
                        .trim();
                    final isSel = cleanRegistered == cleanCurrent;

                    return AppChoiceChip(
                      icon: Icons.group,
                      label: Text('$catName ($count)'),
                      selected: isSel,
                      selectedColor: accentColor.withValues(alpha: 0.25),
                      onSelected: (s) {
                        if (s) _handleRegisteredCategorySelected(catName);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: accentColor.withValues(alpha: 0.2), height: 1),
                const SizedBox(height: AppSpacing.md),
              ],

              // 基本区分・新規入力セクション
              Row(
                children: [
                  Icon(
                    selectedMajorCategory == 'その他'
                        ? Icons.tune
                        : Icons.subdirectory_arrow_right,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    selectedMajorCategory == 'その他'
                        ? '基本区分から選択・新規手入力：'
                        : '「$selectedMajorCategory」の詳細区分を選択：',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: minorList.map((minor) {
                  final isSel =
                      selectedMinorCategory == minor &&
                      (selectedMajorCategory != 'その他' ||
                          customCategoryName.trim().isEmpty);
                  String label = minor;
                  if (selectedMajorCategory == '小学生') {
                    if (minor == '低学年') label = '低学年 (1-4年)';
                    if (minor == '高学年') label = '高学年 (5-6年)';
                  }
                  return AppChoiceChip(
                    label: Text(label),
                    selected: isSel,
                    selectedColor: accentColor.withValues(alpha: 0.25),
                    onSelected: (s) {
                      if (s) _handleMinorSelected(minor);
                    },
                  );
                }).toList(),
              ),
              if (selectedMajorCategory == 'その他') ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: ValueKey('custom_cat_$customCategoryName'),
                  initialValue: customCategoryName,
                  scrollPadding: AppTextField.defaultScrollPadding,
                  decoration: InputDecoration(
                    labelText: 'カスタム部門名を入力（任意）',
                    hintText: '例: 小中学生混成、東西対抗、オープン など',
                    prefixIcon: Icon(Icons.edit_note, color: accentColor),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.mediumValue),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  onChanged: (text) {
                    onCategoryChanged(
                      majorCategory: selectedMajorCategory,
                      minorCategory: selectedMinorCategory,
                      customCategoryName: text,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
