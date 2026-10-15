import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_court_slot_picker.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_heading_format_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_private_note_accordion.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/text_input_helper.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 🥋 クイック次戦作成 Step 2: 試合詳細・見出し設定（添付ファイル1準拠）
class QuickNextCourtHeadingStep extends StatelessWidget {
  final TextEditingController courtController;
  final TextEditingController? noteController;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const QuickNextCourtHeadingStep({
    super.key,
    required this.courtController,
    this.noteController,
    required this.onBack,
    required this.onNext,
  });

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'operate');
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.stadium, color: themeColors.primaryAccent, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '試合詳細・見出しの設定',
                style: TextStyle(
                  fontSize: AppFontSize.body,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '次の試合のコート番号・試合順・回戦を選択してください。',
            style: TextStyle(fontSize: AppFontSize.small, color: subTextColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: courtController,
                builder: (context, _) {
                  final currentCourtNumber =
                      MatchHeadingFormatHelper.extractCourtNumber(
                        courtController.text,
                      );
                  final currentMatchOrder =
                      MatchHeadingFormatHelper.extractMatchOrder(
                        courtController.text,
                      );

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : themeColors.cardBackground,
                      borderRadius: AppRadius.large,
                      border: Border.all(color: themeColors.separatorColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔢 試合場・試合順の数値スロット（＋/−）
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
                        const SizedBox(height: AppSpacing.lg),

                        // 🏆 回戦・ラウンドを選択
                        Text(
                          '🏆 回戦・ラウンドを選択',
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            fontWeight: AppFontWeight.bold,
                            color: subTextColor,
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
                                courtController.text =
                                    MatchHeadingFormatHelper.toggleRound(
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

                        // プレビュー
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1C1E)
                                : const Color(0xFFF2F2F7),
                            borderRadius: AppRadius.medium,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_location_alt,
                                size: 16,
                                color: themeColors.primaryAccent,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  courtController.text.isEmpty
                                      ? '見出しなし（未設定）'
                                      : courtController.text,
                                  style: TextStyle(
                                    fontSize: AppFontSize.bodySmall,
                                    fontWeight: AppFontWeight.bold,
                                    color: courtController.text.isEmpty
                                        ? subTextColor
                                        : textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (noteController != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          MatchPrivateNoteAccordion(
                            noteController: noteController!,
                            isDark: isDark,
                            labelText: '試合のメモ・詳細コメント',
                            initiallyExpanded: false,
                            trailingAction: TextButton.icon(
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
                              onPressed: () =>
                                  TextInputHelper.insertComma(noteController!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                    child: const Text('戻る'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColors.primaryAccent,
                      foregroundColor: AppKendoColors.pureWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text(
                      '対戦相手・紅白へ進む',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: AppFontSize.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
