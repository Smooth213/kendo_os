import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_court_slot_picker.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_heading_format_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_private_note_accordion.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/text_input_helper.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

class MatchEditCourtAndGroupTab extends StatelessWidget {
  final TextEditingController courtController;
  final TextEditingController noteController;
  final TextEditingController? groupController;
  final VoidCallback onClearCourt;
  final ValueChanged<String> onToggleHeadingPreset;
  final bool isDark;
  final AppThemeColors? themeColors;
  final Color? textColor;

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

  const MatchEditCourtAndGroupTab({
    super.key,
    required this.courtController,
    required this.noteController,
    this.groupController,
    required this.onClearCourt,
    required this.onToggleHeadingPreset,
    required this.isDark,
    this.themeColors,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColors = themeColors ?? context.appColors;
    final effectiveTextColor = textColor ?? effectiveColors.textColor;

    return ListenableBuilder(
      listenable: courtController,
      builder: (context, _) {
        final currentCourtNumber = MatchHeadingFormatHelper.extractCourtNumber(
          courtController.text,
        );
        final currentMatchOrder = MatchHeadingFormatHelper.extractMatchOrder(
          courtController.text,
        );

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.md),
            if (groupController != null) ...[
              // ── グループ名入力セクション ──
              _buildInputSection(
                themeColors: effectiveColors,
                textColor: effectiveTextColor,
                controller: groupController!,
                label: '🏷️ グループ名 (リーグ・ブロックなど)',
                hint: '例: Aブロック, 予選Aリーグ (任意)',
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── 試合場・進行見出しの設定カード ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: effectiveColors.primaryAccent.withAlpha(
                  isDark ? 25 : 12,
                ),
                borderRadius: AppRadius.large,
                border: Border.all(
                  color: effectiveColors.primaryAccent.withAlpha(
                    isDark ? 80 : 40,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー行
                  Row(
                    children: [
                      Icon(
                        Icons.stadium,
                        size: 18,
                        color: effectiveColors.primaryAccent,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '試合場・進行見出しの一括設定',
                        style: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          color: effectiveTextColor,
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

                  // 🔢 数値スロットPicker（案B: ＋/－ & テンキー入力）
                  MatchCourtSlotPicker(
                    courtNumber: currentCourtNumber,
                    matchOrder: currentMatchOrder,
                    isDark: isDark,
                    onCourtNumberChanged: (newCourt) {
                      courtController.text =
                          MatchHeadingFormatHelper.updateHeading(
                            currentText: courtController.text,
                            courtNumber: newCourt,
                            matchOrder: currentMatchOrder,
                          );
                    },
                    onMatchOrderChanged: (newOrder) {
                      courtController.text =
                          MatchHeadingFormatHelper.updateHeading(
                            currentText: courtController.text,
                            courtNumber: currentCourtNumber,
                            matchOrder: newOrder,
                          );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 🏆 回戦・ラウンドを選択
                  Text(
                    '🏆 回戦・ラウンドを選択',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: effectiveTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...roundPresets.map((preset) {
                        final isSelected = courtController.text
                            .split(',')
                            .map((e) => e.trim())
                            .contains(preset);
                        return AppFilterChip(
                          selected: isSelected,
                          label: Text(preset),
                          onSelected: (_) {
                            onToggleHeadingPreset(preset);
                            courtController.text =
                                MatchHeadingFormatHelper.toggleRound(
                                  currentText: courtController.text,
                                  roundPreset: preset,
                                  courtNumber: currentCourtNumber,
                                  matchOrder: currentMatchOrder,
                                );
                          },
                        );
                      }),
                      AppActionChip(
                        label: Text(
                          '， (カンマ)',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.bold,
                            color: effectiveTextColor,
                          ),
                        ),
                        onPressed: () =>
                            TextInputHelper.insertComma(courtController),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 見出しプレビュー（手入力・微調整）
                  _buildInputSection(
                    themeColors: effectiveColors,
                    textColor: effectiveTextColor,
                    controller: courtController,
                    label: '試合場・進行見出しプレビュー',
                    hint: '例: 第1試合場, 3試合目, 準決勝',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 📝 試合のメモ・詳細コメント（運営メモ・特記事項） ──
            MatchPrivateNoteAccordion(
              noteController: noteController,
              isDark: isDark,
              initiallyExpanded: true,
              trailingAction: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  Icons.add,
                  size: 14,
                  color: effectiveColors.primaryAccent,
                ),
                label: Text(
                  'カンマ（,）',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: effectiveColors.primaryAccent,
                  ),
                ),
                onPressed: () => TextInputHelper.insertComma(noteController),
              ),
              buildTextFieldDecoration:
                  ({
                    required String labelText,
                    required String hintText,
                    Widget? prefixIcon,
                  }) => InputDecoration(
                    labelText: labelText,
                    hintText: hintText,
                    hintStyle: TextStyle(color: effectiveColors.hintColor),
                    prefixIcon: prefixIcon,
                    filled: true,
                    fillColor: isDark
                        ? effectiveColors.inputBackground
                        : effectiveColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(
                        color: effectiveColors.separatorColor,
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildInputSection({
    required AppThemeColors themeColors,
    required Color textColor,
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.bold,
                color: textColor,
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: AppFontSize.small),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: themeColors.hintColor,
              fontSize: AppFontSize.caption,
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1E1E20)
                : const Color(0xFFF2F2F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF38383A)
                    : const Color(0x33000000),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF38383A)
                    : const Color(0x33000000),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
