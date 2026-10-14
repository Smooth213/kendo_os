import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/category_format_history_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 🏆 よく使う組み合わせ（クイックバッジ）コンポーネント
class TeamRegistrationQuickBadges extends ConsumerStatefulWidget {
  final AppThemeColors themeColors;
  final ValueChanged<CategoryFormatPresetItem> onPresetSelected;

  const TeamRegistrationQuickBadges({
    super.key,
    required this.themeColors,
    required this.onPresetSelected,
  });

  @override
  ConsumerState<TeamRegistrationQuickBadges> createState() =>
      _TeamRegistrationQuickBadgesState();
}

class _TeamRegistrationQuickBadgesState
    extends ConsumerState<TeamRegistrationQuickBadges> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // 履歴と初期プリセットから上位4件を取得
    final presets = ref
        .watch(categoryFormatHistoryProvider.notifier)
        .getTopPresets(limit: 4);

    if (presets.isEmpty) return const SizedBox.shrink();

    final themeColors = widget.themeColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final inputBgColor = themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;
    final accentColor = themeColors.primaryAccent;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: AppRadius.medium,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, size: 18, color: accentColor),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'よく使う組み合わせ（ワンタップ入力）',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _isExpanded ? '閉じる' : '開く',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: accentColor,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(height: 1, thickness: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: presets.map((preset) {
                  return AppActionChip(
                    icon: Icons.check_circle_outline,
                    label: Text(
                      preset.displayLabel,
                      style: const TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                    onPressed: () => widget.onPresetSelected(preset),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
