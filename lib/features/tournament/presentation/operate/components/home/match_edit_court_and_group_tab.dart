import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 試合編集シート: 試合場（コート）・進行見出し・詳細メモ設定タブ
class MatchEditCourtAndGroupTab extends StatelessWidget {
  final AppThemeColors themeColors;
  final TextEditingController courtController;
  final TextEditingController noteController;
  final bool isDark;
  final Color textColor;
  final ValueChanged<String> onToggleHeadingPreset;
  final VoidCallback onClearCourt;

  const MatchEditCourtAndGroupTab({
    super.key,
    required this.themeColors,
    required this.courtController,
    required this.noteController,
    required this.isDark,
    required this.textColor,
    required this.onToggleHeadingPreset,
    required this.onClearCourt,
  });

  static const List<String> courtPresets = [
    '第1試合場',
    '第2試合場',
    '第3試合場',
    '部内戦コート',
  ];

  static const List<String> roundPresets = [
    '1回戦',
    '2回戦',
    '3回戦',
    '準決勝',
    '決勝戦',
    '1試合目',
    '2試合目',
    '3試合目',
    'Aリーグ',
    'Bリーグ',
  ];

  @override
  Widget build(BuildContext context) {
    final currentText = courtController.text;
    final selectedItems = currentText.split(',').map((e) => e.trim()).toSet();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.roundValue),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: themeColors.primaryAccent.withAlpha(isDark ? 25 : 12),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: themeColors.primaryAccent.withAlpha(isDark ? 80 : 40),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.stadium,
                    size: 18,
                    color: themeColors.primaryAccent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '試合場・進行見出しの一括設定',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  if (courtController.text.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.clear, size: 14),
                      label: const Text(
                        'クリア',
                        style: TextStyle(fontSize: AppFontSize.caption),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onClearCourt,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInputSection(
                controller: courtController,
                label: '試合場・進行見出し (カンマ区切り)',
                hint: '例: 第1試合場, 1回戦, 3試合目 (未入力時は空欄になります)',
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0x8A000000),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '※ここに入力した試合場・進行見出しは、メモ（詳細情報）に保存・表示されます',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : const Color(0x8A000000),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '🏟️ 試合場（コート）を選択',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xDE000000),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: courtPresets.map((preset) {
                  final isSelected = selectedItems.contains(preset);
                  return AppFilterChip(
                    selected: isSelected,
                    label: Text(preset),
                    onSelected: (_) => onToggleHeadingPreset(preset),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text(
                '🏆 回戦・ラウンド・試合順を選択',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: roundPresets.map((preset) {
                  final isSelected = selectedItems.contains(preset);
                  return AppFilterChip(
                    selected: isSelected,
                    label: Text(preset),
                    onSelected: (_) => onToggleHeadingPreset(preset),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildInputSection(
          controller: noteController,
          label: '📝 試合のメモ・詳細コメント',
          hint: '注意事項や備考を入力',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildInputSection({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.small,
            fontWeight: AppFontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: AppFontSize.body),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0x33000000),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0x33000000),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: themeColors.primaryAccent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
