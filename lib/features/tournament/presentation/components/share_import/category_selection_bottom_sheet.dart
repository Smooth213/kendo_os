import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/category_cascade_selector_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 🏆 大会部門（カテゴリ）詳細選択ボトムシート
class CategorySelectionBottomSheet extends StatefulWidget {
  final String title;
  final String initialCategory;
  final Color? accentColor;

  const CategorySelectionBottomSheet({
    super.key,
    required this.title,
    required this.initialCategory,
    this.accentColor,
  });

  static const List<String> allMajorCategories = [
    '初心者',
    '幼年',
    '小学生',
    '中学生',
    '高校生',
    '大学・一般',
    'その他',
  ];

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String initialCategory,
    Color? accentColor,
  }) {
    return showAppBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => CategorySelectionBottomSheet(
        title: title,
        initialCategory: initialCategory,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<CategorySelectionBottomSheet> createState() =>
      _CategorySelectionBottomSheetState();
}

class _CategorySelectionBottomSheetState
    extends State<CategorySelectionBottomSheet> {
  late String _selectedMajorCategory;
  late String _selectedMinorCategory;
  late String _customCategoryName;

  @override
  void initState() {
    super.initState();
    final parsed = TeamRegistrationCategoryParser.parseCategoryToState(
      widget.initialCategory,
    );
    _selectedMajorCategory = parsed.majorCategory;
    _selectedMinorCategory = parsed.minorCategory;

    String customInit = '';
    if (_selectedMajorCategory == 'その他') {
      final clean = widget.initialCategory.replaceAll('の部', '').trim();
      if (!['その他', '混成', '混合', '自由'].contains(clean) && clean.isNotEmpty) {
        customInit = clean;
      }
    }
    _customCategoryName = customInit;
  }

  String get _currentGeneratedCategory {
    if (_selectedMajorCategory == 'その他') {
      final custom = _customCategoryName.trim();
      if (custom.isNotEmpty) {
        return custom.endsWith('の部') ? custom : '$customの部';
      }
      if (_selectedMinorCategory == '全体') {
        return 'その他の部';
      }
      return '$_selectedMinorCategoryの部';
    }
    return TeamRegistrationCategoryParser.formatCategoryName(
      majorCategory: _selectedMajorCategory,
      minorCategory: _selectedMinorCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? context.appColors.primaryAccent;
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final generatedCategory = _currentGeneratedCategory;

    return AppBottomSheetContent(
      title: widget.title,
      titleIcon: Icons.category,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryCascadeSelectorView(
              selectedMajorCategory: _selectedMajorCategory,
              selectedMinorCategory: _selectedMinorCategory,
              customCategoryName: _customCategoryName,
              themeColors: themeColors,
              onCategoryChanged:
                  ({
                    required majorCategory,
                    required minorCategory,
                    customCategoryName,
                  }) {
                    setState(() {
                      _selectedMajorCategory = majorCategory;
                      _selectedMinorCategory = minorCategory;
                      if (customCategoryName != null) {
                        _customCategoryName = customCategoryName;
                      }
                    });
                  },
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.mediumValue),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: accent, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '設定されるカテゴリ名',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: subTextColor,
                          ),
                        ),
                        Text(
                          generatedCategory,
                          style: TextStyle(
                            fontSize: AppFontSize.headline,
                            fontWeight: AppFontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: () {
                  Navigator.of(context).pop(generatedCategory);
                },
                color: accent,
                icon: Icons.check,
                label: 'この部門に設定',
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
