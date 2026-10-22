import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// アナウンス用定型文カテゴリ定義
enum AnnounceChipCategory {
  progress('☕ 進行・休憩', [
    '休憩',
    '昼休憩',
    '小休止',
    '試合再開',
    '一時中断',
    '休み',
    '繰り上げ進行',
    '進行遅れ',
  ]),
  officials('⚖️ 審判・役員', [
    '審判',
    '時計係',
    '記録係',
    '審判交代',
    '審判会議',
    '係員集合',
    '監督会議',
    '計時・掲示交代',
  ]),
  venue('📍 会場・移動', ['コート移動', '試合順変更', '会場変更', '本部前集合', '武道場', 'サブアリーナ']),
  alerts('📢 呼出・緊急', ['【連絡】', '【重要】', '【緊急】', '選手呼出', '忘れ物', '整列']),
  rounds('🏆 回戦・ラウンド', [
    '1回戦',
    '2回戦',
    '3回戦',
    '準々決勝',
    '準決勝',
    '決勝戦',
    '代表戦',
    '順位決定戦',
  ]);

  final String label;
  final List<String> chips;
  const AnnounceChipCategory(this.label, this.chips);
}

/// 🥋 アナウンス用 クイック入力チップ（横並びカテゴリタブ ＆ アコーディオン開閉）
class TimelineAnnounceQuickChips extends StatefulWidget {
  final ValueChanged<String> onChipSelected;
  final bool isDark;

  const TimelineAnnounceQuickChips({
    super.key,
    required this.onChipSelected,
    required this.isDark,
  });

  @override
  State<TimelineAnnounceQuickChips> createState() =>
      _TimelineAnnounceQuickChipsState();
}

class _TimelineAnnounceQuickChipsState
    extends State<TimelineAnnounceQuickChips> {
  AnnounceChipCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. 横スクロール カテゴリタブバー ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AnnounceChipCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (_selectedCategory == cat) {
                        _selectedCategory = null; // トグルで閉じる
                      } else {
                        _selectedCategory = cat;
                      }
                    });
                  },
                  borderRadius: AppRadius.medium,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? themeColors.primaryAccent
                          : (widget.isDark
                                ? const Color(0xFF2C2C2E)
                                : themeColors.cardBackground),
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: isSelected
                            ? themeColors.primaryAccent
                            : (widget.isDark
                                  ? const Color(0xFF38383A)
                                  : const Color(0x22000000)),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: themeColors.primaryAccent.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: isSelected
                                ? AppFontWeight.bold
                                : AppFontWeight.regular,
                            color: isSelected
                                ? AppKendoColors.pureWhite
                                : context.appColors.textColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Icon(
                          isSelected
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 16,
                          color: isSelected
                              ? AppKendoColors.pureWhite
                              : context.appColors.subTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ── 2. アコーディオン展開チップコンテナ ──
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _selectedCategory == null
              ? const SizedBox.shrink()
              : Container(
                  margin: const EdgeInsets.only(top: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF1E1E20)
                        : themeColors.primaryAccent.withValues(alpha: 0.04),
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: themeColors.primaryAccent.withValues(
                        alpha: widget.isDark ? 0.4 : 0.2,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 13,
                            color: themeColors.primaryAccent,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            'タップしてタイトル/本文に即反映:',
                            style: TextStyle(
                              fontSize: AppFontSize.micro,
                              fontWeight: AppFontWeight.bold,
                              color: themeColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedCategory!.chips.map((chipText) {
                          return AppActionChip(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            label: Text(
                              chipText,
                              style: TextStyle(
                                fontSize: AppFontSize.caption,
                                fontWeight: AppFontWeight.bold,
                                color: context.appColors.textColor,
                              ),
                            ),
                            backgroundColor: widget.isDark
                                ? const Color(0xFF2C2C2E)
                                : AppKendoColors.pureWhite,
                            side: BorderSide(
                              color: widget.isDark
                                  ? const Color(0xFF48484A)
                                  : const Color(0x33000000),
                            ),
                            onPressed: () => widget.onChipSelected(chipText),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
