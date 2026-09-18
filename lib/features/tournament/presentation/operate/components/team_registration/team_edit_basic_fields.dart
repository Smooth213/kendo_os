import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// チーム編集ボトムシート: 基本情報（チーム名・部門・試合形式）入力ウィジェット
class TeamEditBasicFields extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final accentColor = themeColors.primaryAccent;

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
          controller: teamNameController,
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
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.mediumValue),
              borderSide: BorderSide(color: borderColor),
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

        const SizedBox(height: AppSpacing.lg),

        // 2. 所属部門（カテゴリ）
        Text(
          '所属部門（カテゴリ）',
          style: TextStyle(
            fontSize: AppFontSize.subhead,
            fontWeight: AppFontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.subValue,
          runSpacing: AppSpacing.subValue,
          children: candidateCategories.map((cat) {
            final isSel = selectedCategory == cat;
            return AppChoiceChip(
              label: Text(cat),
              selected: isSel,
              selectedColor: accentColor.withValues(alpha: 0.2),
              onSelected: (_) => onCategoryChanged(cat),
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 3. 試合形式
        Text(
          '試合形式',
          style: TextStyle(
            fontSize: AppFontSize.subhead,
            fontWeight: AppFontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.subValue,
          runSpacing: AppSpacing.subValue,
          children: matchTypes.map((type) {
            final isSel = matchType == type;
            return AppChoiceChip(
              label: Text(type),
              selected: isSel,
              selectedColor: accentColor.withValues(alpha: 0.2),
              onSelected: (_) => onMatchTypeChanged(type),
            );
          }).toList(),
        ),
      ],
    );
  }
}
