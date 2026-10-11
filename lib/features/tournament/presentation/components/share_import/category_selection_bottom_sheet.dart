import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
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
  late TextEditingController _customController;

  static const List<String> allMajorCategories = [
    '初心者',
    '幼年',
    '小学生',
    '中学生',
    '高校生',
    '大学・一般',
    'その他',
  ];

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
    _customController = TextEditingController(text: customInit);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String get _currentGeneratedCategory {
    if (_selectedMajorCategory == 'その他') {
      final custom = _customController.text.trim();
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

  void _onMajorChanged(String major) {
    setState(() {
      _selectedMajorCategory = major;
      final minors = TeamRegistrationCategoryStep.getMinorCategories(major);
      if (!minors.contains(_selectedMinorCategory)) {
        if (major == '小学生') {
          _selectedMinorCategory = '低学年';
        } else {
          _selectedMinorCategory = '全体';
        }
      }
    });
  }

  void _onMinorChanged(String minor) {
    setState(() {
      _selectedMinorCategory = minor;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? context.appColors.primaryAccent;
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;
    final minorList = TeamRegistrationCategoryStep.getMinorCategories(
      _selectedMajorCategory,
    );
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
            Text(
              '1. 出場カテゴリ（大分類）',
              style: TextStyle(
                fontSize: AppFontSize.subhead,
                fontWeight: AppFontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: allMajorCategories.map((major) {
                final isSel = _selectedMajorCategory == major;
                return AppChoiceChip(
                  label: Text(major),
                  selected: isSel,
                  selectedColor: accent.withValues(alpha: 0.2),
                  onSelected: (sel) {
                    if (sel) _onMajorChanged(major);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '2. 出場カテゴリ（小分類）',
              style: TextStyle(
                fontSize: AppFontSize.subhead,
                fontWeight: AppFontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: minorList.map((minor) {
                String label = minor;
                if (_selectedMajorCategory == '小学生') {
                  if (minor == '低学年') label = '低学年 (1-4年)';
                  if (minor == '高学年') label = '高学年 (5-6年)';
                }
                final isSel = _selectedMinorCategory == minor;
                return AppChoiceChip(
                  label: Text(label),
                  selected: isSel,
                  selectedColor: accent.withValues(alpha: 0.2),
                  onSelected: (sel) {
                    if (sel) _onMinorChanged(minor);
                  },
                );
              }).toList(),
            ),
            if (_selectedMajorCategory == 'その他') ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _customController,
                style: TextStyle(fontSize: AppFontSize.body, color: textColor),
                decoration: const InputDecoration(
                  labelText: 'カスタム部門名（任意）',
                  hintText: '例: 小中学生混成、東西対抗、オープン など',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
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
