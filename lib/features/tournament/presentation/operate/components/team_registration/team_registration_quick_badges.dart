import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/category_format_history_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 🏆 よく使う組み合わせ（クイックバッジ）コンポーネント
class TeamRegistrationQuickBadges extends ConsumerWidget {
  final AppThemeColors themeColors;
  final ValueChanged<CategoryFormatPresetItem> onPresetSelected;

  const TeamRegistrationQuickBadges({
    super.key,
    required this.themeColors,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 履歴と初期プリセットから上位4件を取得
    final presets = ref
        .watch(categoryFormatHistoryProvider.notifier)
        .getTopPresets(limit: 4);

    if (presets.isEmpty) return const SizedBox.shrink();

    final accentColor = themeColors.primaryAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt, size: 16, color: accentColor),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'よく使う組み合わせ（ワンタップ入力）',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: presets.map((preset) {
            return AppActionChip(
              icon: Icons.check_circle_outline,
              label: Text(
                preset.displayLabel,
                style: const TextStyle(fontWeight: AppFontWeight.bold),
              ),
              onPressed: () => onPresetSelected(preset),
            );
          }).toList(),
        ),
      ],
    );
  }
}
