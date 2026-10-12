import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_court_slot_picker.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_heading_format_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_private_note_accordion.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/utils/text_input_helper.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
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

  static const List<String> roundPresets = [
    '1回戦',
    '2回戦',
    '3回戦',
    '準々決勝',
    '準決勝',
    '決勝戦',
    '3位決定戦',
    'Aリーグ',
    'Bリーグ',
  ];

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

    final currentCourtNumber = MatchHeadingFormatHelper.extractCourtNumber(
      courtController.text,
    );
    final currentMatchOrder = MatchHeadingFormatHelper.extractMatchOrder(
      courtController.text,
    );

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
          // 🔼 ヘッダー（タイトル ＆ クリアボタン）
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

          // 🔢 試合場・試合順の数値スロット（案B: ＋/－ & テンキー入力）
          MatchCourtSlotPicker(
            courtNumber: currentCourtNumber,
            matchOrder: currentMatchOrder,
            isDark: isDark,
            onCourtNumberChanged: (newCourt) {
              courtController.text = MatchHeadingFormatHelper.updateHeading(
                currentText: courtController.text,
                courtNumber: newCourt,
                matchOrder: currentMatchOrder,
              );
            },
            onMatchOrderChanged: (newOrder) {
              courtController.text = MatchHeadingFormatHelper.updateHeading(
                currentText: courtController.text,
                courtNumber: currentCourtNumber,
                matchOrder: newOrder,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // 🏆 回戦・ラウンドを選択
          Text(
            '🏆 回戦・ラウンドを選択',
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
            children: roundPresets.map((preset) {
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
                  courtController.text = MatchHeadingFormatHelper.toggleRound(
                    currentText: courtController.text,
                    roundPreset: preset,
                    courtNumber: currentCourtNumber,
                    matchOrder: currentMatchOrder,
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 📝 見出しプレビュー（手入力・微調整も可能）
          AppTextField(
            controller: courtController,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: textColor,
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.semiBold,
            ),
            decoration: buildTextFieldDecoration(
              labelText: '試合場・進行の見出しプレビュー',
              hintText: '例: 第1試合場, 準決勝',
              prefixIcon: Icon(
                Icons.edit_location_alt,
                color: themeColors.primaryAccent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 📝 運営メモ・特記事項（折りたたみアコーディオン）
          MatchPrivateNoteAccordion(
            noteController: noteController,
            isDark: isDark,
            labelText: '試合のメモ・詳細コメント',
            initiallyExpanded: true,
            trailingAction: TextButton.icon(
              icon: const Icon(Icons.add, size: 14),
              label: const Text(
                'カンマ（,）',
                style: TextStyle(fontSize: AppFontSize.caption),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => TextInputHelper.insertComma(noteController),
            ),
            buildTextFieldDecoration: buildTextFieldDecoration,
          ),
        ],
      ),
    );
  }
}
