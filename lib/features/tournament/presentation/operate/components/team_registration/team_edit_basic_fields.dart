import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/category_selection_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/category_cascade_selector_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_format_selector_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// チーム編集ボトムシート: 基本情報（チーム名・部門・試合形式）入力ウィジェット
class TeamEditBasicFields extends StatefulWidget {
  final TextEditingController teamNameController;
  final String selectedCategory;
  final String matchType;
  final List<String> candidateCategories;
  final List<String> matchTypes;
  final AppThemeColors themeColors;
  final Color borderColor;
  final void Function(String category) onCategoryChanged;
  final void Function(String matchType) onMatchTypeChanged;

  const TeamEditBasicFields({
    super.key,
    required this.teamNameController,
    required this.selectedCategory,
    required this.matchType,
    required this.candidateCategories,
    required this.matchTypes,
    required this.themeColors,
    required this.borderColor,
    required this.onCategoryChanged,
    required this.onMatchTypeChanged,
  });

  @override
  State<TeamEditBasicFields> createState() => _TeamEditBasicFieldsState();
}

class _TeamEditBasicFieldsState extends State<TeamEditBasicFields> {
  late String _selectedMajorCategory;
  late String _selectedMinorCategory;
  late String _customCategoryName;

  @override
  void initState() {
    super.initState();
    _parseInitialCategory(widget.selectedCategory);
  }

  @override
  void didUpdateWidget(covariant TeamEditBasicFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _parseInitialCategory(widget.selectedCategory);
    }
  }

  void _parseInitialCategory(String category) {
    final parsed = TeamRegistrationCategoryParser.parseCategoryToState(
      category,
    );
    _selectedMajorCategory = parsed.majorCategory;
    _selectedMinorCategory = parsed.minorCategory;

    String customInit = '';
    if (_selectedMajorCategory == 'その他') {
      final clean = category.replaceAll('の部', '').trim();
      if (!['その他', '混成', '混合', '自由'].contains(clean) && clean.isNotEmpty) {
        customInit = clean;
      }
    }
    _customCategoryName = customInit;
  }

  void _handleCategoryChanged({
    required String majorCategory,
    required String minorCategory,
    String? customCategoryName,
  }) {
    setState(() {
      _selectedMajorCategory = majorCategory;
      _selectedMinorCategory = minorCategory;
      if (customCategoryName != null) {
        _customCategoryName = customCategoryName;
      }
    });

    final newCat = CategoryCascadeSelectorView.buildCategoryName(
      major: majorCategory,
      minor: minorCategory,
      customName: customCategoryName ?? _customCategoryName,
    );
    widget.onCategoryChanged(newCat);
  }

  Future<void> _openCategoryModal(BuildContext context) async {
    final selected = await CategorySelectionBottomSheet.show(
      context: context,
      title: '所属部門（カテゴリ）の選択',
      initialCategory: widget.selectedCategory,
      accentColor: widget.themeColors.primaryAccent,
    );
    if (selected != null && mounted) {
      widget.onCategoryChanged(selected);
      _parseInitialCategory(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final accentColor = widget.themeColors.primaryAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. チーム名
        Text(
          'チーム名',
          style: TextStyle(
            fontSize: AppFontSize.subhead,
            fontWeight: AppFontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: widget.teamNameController,
          style: TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.bold,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: '例: 〇〇剣友会A, 低学年チーム',
            filled: true,
            fillColor: isDark
                ? const Color(0xFF2C2C35)
                : const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.mediumValue),
              borderSide: BorderSide(color: widget.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.mediumValue),
              borderSide: BorderSide(color: widget.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.mediumValue),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // 2. 所属部門（カテゴリ）: 共通カスケードセレクタ
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '所属部門（カテゴリ）',
              style: TextStyle(
                fontSize: AppFontSize.subhead,
                fontWeight: AppFontWeight.bold,
                color: textColor,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.smallValue),
              onTap: () => _openCategoryModal(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.subValue,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune, size: 14, color: accentColor),
                    const SizedBox(width: AppSpacing.subValue),
                    Text(
                      '全カテゴリから選択',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        CategoryCascadeSelectorView(
          selectedMajorCategory: _selectedMajorCategory,
          selectedMinorCategory: _selectedMinorCategory,
          customCategoryName: _customCategoryName,
          themeColors: widget.themeColors,
          onCategoryChanged: _handleCategoryChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.smallValue),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: accentColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '設定中: ${widget.selectedCategory.endsWith('の部') ? widget.selectedCategory : '${widget.selectedCategory}の部'}',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // 3. 試合形式: 5大分類 ＋ サブ詳細共通セレクタ
        Text(
          '試合形式',
          style: TextStyle(
            fontSize: AppFontSize.subhead,
            fontWeight: AppFontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        MatchFormatSelectorView(
          currentMatchType: widget.matchType,
          themeColors: widget.themeColors,
          onMatchTypeChanged: widget.onMatchTypeChanged,
        ),
      ],
    );
  }
}
