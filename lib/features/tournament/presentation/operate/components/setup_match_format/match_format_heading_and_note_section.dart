import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/text_input_helper.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 試合場・進行見出しおよび試合メモの入力セクション
class MatchFormatHeadingAndNoteSection extends StatelessWidget {
  final AppThemeColors themeColors;
  final TextEditingController courtController;
  final TextEditingController noteController;
  final ValueChanged<String> onToggleHeadingPreset;
  final bool isDark;
  final InputDecoration Function({
    required String labelText,
    required String hintText,
    Widget? prefixIcon,
  })
  buildTextFieldDecoration;

  const MatchFormatHeadingAndNoteSection({
    super.key,
    required this.themeColors,
    required this.courtController,
    required this.noteController,
    required this.onToggleHeadingPreset,
    required this.isDark,
    required this.buildTextFieldDecoration,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppKendoColors.pureWhite
        : const Color(0xFF000000);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : themeColors.cardBackground,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : themeColors.separatorColor,
        ),
        boxShadow: [
          BoxShadow(
            color: AppKendoColors.pureBlack.withValues(
              alpha: isDark ? 0.2 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stadium, size: 18, color: themeColors.primaryAccent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '試合場・進行見出しの一括設定',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                  color: textColor,
                ),
              ),
              const Spacer(),
              if (courtController.text.isNotEmpty)
                TextButton.icon(
                  icon: Icon(
                    Icons.clear,
                    size: 14,
                    color: themeColors.primaryAccent,
                  ),
                  label: Text(
                    'クリア',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      color: themeColors.primaryAccent,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    courtController.clear();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: courtController,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: textColor,
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.semiBold,
            ),
            decoration: buildTextFieldDecoration(
              labelText: '試合場・進行の見出し',
              hintText: '例: 準決勝, 第1試合場, 23試合目',
              prefixIcon: Icon(
                Icons.edit_location_alt,
                color: themeColors.primaryAccent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 13,
                color: themeColors.subTextColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '※ここに入力した試合場・進行見出しは、メモ（詳細情報）に保存・表示されます',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: themeColors.subTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '🏟️ 試合場（コート）を選択',
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: AppFontWeight.bold,
              color: themeColors.subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['第1試合場', '第2試合場', '第3試合場', '部内戦コート'].map((preset) {
              final isSelected = courtController.text
                  .split(',')
                  .map((e) => e.trim())
                  .contains(preset);
              return AppFilterChip(
                selected: isSelected,
                label: Text(
                  preset,
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.bold,
                    color: isSelected
                        ? (isDark
                              ? AppKendoColors.pureWhite
                              : themeColors.primaryAccent)
                        : (isDark
                              ? themeColors.textColor
                              : themeColors.primaryAccent),
                  ),
                ),
                onSelected: (_) {
                  onToggleHeadingPreset(preset);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '🏆 回戦・ラウンド・試合順を選択',
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: AppFontWeight.bold,
              color: themeColors.subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...[
                '1回戦',
                '2回戦',
                '準決勝',
                '決勝戦',
                'Aリーグ',
                'Bリーグ',
                '3試合目',
                '5試合目',
              ].map((preset) {
                final isSelected = courtController.text
                    .split(',')
                    .map((e) => e.trim())
                    .contains(preset);
                return AppFilterChip(
                  selected: isSelected,
                  label: Text(
                    preset,
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                      color: isSelected
                          ? (isDark
                                ? AppKendoColors.pureWhite
                                : themeColors.primaryAccent)
                          : (isDark
                                ? themeColors.textColor
                                : themeColors.primaryAccent),
                    ),
                  ),
                  onSelected: (_) {
                    onToggleHeadingPreset(preset);
                  },
                );
              }),
              AppActionChip(
                label: Text(
                  '， (カンマ)',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.bold,
                    color: isDark
                        ? AppKendoColors.cyanAccent
                        : themeColors.primaryAccent,
                  ),
                ),
                icon: Icons.add,
                iconColor: isDark
                    ? AppKendoColors.cyanAccent
                    : themeColors.primaryAccent,
                onPressed: () => TextInputHelper.insertComma(courtController),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: themeColors.separatorColor),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  '📝 試合のメモ・詳細コメント',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 14),
                label: const Text(
                  'カンマ（,）',
                  style: TextStyle(fontSize: AppFontSize.caption),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => TextInputHelper.insertComma(noteController),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            controller: noteController,
            maxLines: 2,
            style: TextStyle(color: textColor),
            decoration: buildTextFieldDecoration(
              labelText: '試合のメモ・詳細コメント',
              hintText: 'メモや追記事項があれば入力してください',
              prefixIcon: Icon(
                Icons.edit_note,
                color: themeColors.primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
