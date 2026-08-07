import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class InfiniteStreakLeaderboard extends ConsumerWidget {
  const InfiniteStreakLeaderboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaks = ref.watch(bunaiksenInfiniteStreakProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    if (streaks.isEmpty || !streaks.values.any((v) => v > 0)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          'まだ連勝記録はありません',
          style: TextStyle(color: themeColors.hintColor),
        ),
      );
    }

    // 連勝数で降順にソートし、Top3を抽出
    final sorted = streaks.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.where((e) => e.value > 0).take(3).toList();

    return Column(
      children: top.asMap().entries.map((entry) {
        final index = entry.key;
        final e = entry.value;
        final isTop = index == 0;

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.military_tech,
            color: isTop ? Colors.amber : themeColors.subTextColor,
          ),
          title: Text(
            e.key,
            style: TextStyle(
              fontWeight: isTop ? AppFontWeight.bold : FontWeight.normal,
              color: themeColors.textColor,
            ),
          ),
          trailing: Text(
            '${e.value} 連勝',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              color: isTop ? Colors.red.shade600 : themeColors.textColor,
              fontSize: AppFontSize.bodyMedium,
            ),
          ),
        );
      }).toList(),
    );
  }
}
