import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 新規試合作成画面における「試合場・進行見出し」および「試合メモ」入力統合カード（純粋UIコンポーネント）
class NewMatchHeadingNotesCard extends StatelessWidget {
  final TextEditingController courtController;
  final TextEditingController noteController;
  final bool isDark;
  final VoidCallback onClearCourt;
  final ValueChanged<String> onHeadingPresetToggled;

  static const List<String> courtPresets = [
    '第1試合場',
    '第2試合場',
    '第3試合場',
    '部内戦コート',
  ];

  static const List<String> roundPresets = [
    '1回戦',
    '2回戦',
    '準決勝',
    '決勝戦',
    'Aリーグ',
    'Bリーグ',
    '3試合目',
    '5試合目',
  ];

  const NewMatchHeadingNotesCard({
    super.key,
    required this.courtController,
    required this.noteController,
    required this.isDark,
    required this.onClearCourt,
    required this.onHeadingPresetToggled,
  });

  @override
  Widget build(BuildContext context) {
    final selectedItems = courtController.text
        .split(',')
        .map((e) => e.trim())
        .toSet();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
        ),
        boxShadow: [
          BoxShadow(
            color: AppKendoColors.pureBlack.withAlpha(isDark ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stadium,
                size: 18,
                color: isDark
                    ? AppKendoColors.cyanAccent
                    : const Color(0xFF3F51B5),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '試合場・進行見出しの設定',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.textColor,
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
          AppTextField(
            controller: courtController,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: context.appColors.textColor,
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.semiBold,
            ),
            decoration: InputDecoration(
              labelText: '試合場・進行の見出し',
              hintText: '例: 準決勝, 第1試合場, 23試合目',
              hintStyle: const TextStyle(fontSize: AppFontSize.bodyMedium),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : const Color(0x33000000),
                ),
              ),
            ),
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
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0xDE000000),
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
                label: Text(
                  preset,
                  style: const TextStyle(fontSize: AppFontSize.caption),
                ),
                onSelected: (_) {
                  onHeadingPresetToggled(preset);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            '🏆 回戦・ラウンド・試合順を選択',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0xDE000000),
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
                label: Text(
                  preset,
                  style: const TextStyle(fontSize: AppFontSize.caption),
                ),
                onSelected: (_) {
                  onHeadingPresetToggled(preset);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: noteController,
            maxLines: 2,
            style: TextStyle(color: context.appColors.textColor),
            decoration: InputDecoration(
              labelText: '試合のメモ・詳細コメント',
              hintText: 'メモや追記事項があれば入力してください',
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : context.appColors.separatorColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
