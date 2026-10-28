import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_court_slot_picker.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_heading_format_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_private_note_accordion.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 新規試合作成画面用の試合場・進行見出し＆メモ設定カード
class NewMatchHeadingNotesCard extends StatelessWidget {
  final TextEditingController courtController;
  final TextEditingController noteController;
  final bool isDark;
  final VoidCallback onClearCourt;
  final ValueChanged<String> onHeadingPresetToggled;

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
    final themeColors = context.appColors;

    return ListenableBuilder(
      listenable: courtController,
      builder: (context, _) {
        final currentCourtNumber = MatchHeadingFormatHelper.extractCourtNumber(
          courtController.text,
        );
        final currentMatchOrder = MatchHeadingFormatHelper.extractMatchOrder(
          courtController.text,
        );

        return AppGlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: AppRadius.large,
          border: Border.all(
            color: themeColors.hairlineBorder,
            width: AppBorderWidth.hairline,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ヘッダー ──
              Row(
                children: [
                  Icon(
                    Icons.stadium,
                    size: 18,
                    color: themeColors.primaryAccent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '試合場・進行見出しの設定',
                        style: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          color: themeColors.textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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

              // ── 🔢 試合場・試合順の数値スロット（案B: ＋/－ & テンキー入力） ──
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
              const SizedBox(height: AppSpacing.md),

              // ── 🏆 回戦・ラウンドを選択 ──
              Text(
                '🏆 回戦・ラウンドを選択',
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
                children: roundPresets.map((preset) {
                  final isSelected = courtController.text
                      .split(',')
                      .map((e) => e.trim())
                      .contains(preset);
                  return AppFilterChip(
                    selected: isSelected,
                    label: Text(
                      preset,
                      style: const TextStyle(fontSize: AppFontSize.caption),
                    ),
                    onSelected: (_) {
                      final newText = MatchHeadingFormatHelper.toggleRound(
                        currentText: courtController.text,
                        roundPreset: preset,
                        courtNumber: currentCourtNumber,
                        matchOrder: currentMatchOrder,
                      );
                      courtController.text = newText;
                      onHeadingPresetToggled(newText);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── 見出しプレビュー（手入力・微調整） ──
              AppTextField(
                controller: courtController,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: themeColors.textColor,
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.semiBold,
                ),
                decoration: InputDecoration(
                  labelText: '試合場・進行の見出しプレビュー',
                  hintText: '例: 第1試合場, 準決勝',
                  hintStyle: const TextStyle(fontSize: AppFontSize.small),
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
              const SizedBox(height: AppSpacing.sm),

              // ── 📝 運営メモ・特記事項（折りたたみアコーディオン） ──
              MatchPrivateNoteAccordion(
                noteController: noteController,
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }
}
