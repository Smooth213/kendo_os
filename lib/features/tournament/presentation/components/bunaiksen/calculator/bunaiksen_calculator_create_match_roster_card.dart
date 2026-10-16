import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/multi_player_select_input.dart';

/// 🥋 試合作成シート用：部員名簿選択・シャッフルカードWidget
class BunaiksenCalculatorCreateMatchRosterCard extends StatelessWidget {
  final int requiredCount;
  final List<String> selectedPlayers;
  final ValueChanged<List<String>> onChanged;
  final AppThemeColors themeColors;
  final bool isDark;

  const BunaiksenCalculatorCreateMatchRosterCard({
    super.key,
    required this.requiredCount,
    required this.selectedPlayers,
    required this.onChanged,
    required this.themeColors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedPlayers.length;
    final isMatch = selectedCount == requiredCount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isMatch
              ? AppKendoColors.green.withValues(alpha: 0.5)
              : AppKendoColors.orange.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '参加部員を選択 ($selectedCount / $requiredCount名)',
                style: const TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.bodySmall,
                ),
              ),
              if (selectedPlayers.length >= 2)
                TextButton.icon(
                  icon: const Icon(Icons.shuffle_rounded, size: 16),
                  label: const Text('シャッフル'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: themeColors.primaryAccent,
                  ),
                  onPressed: () {
                    AppHaptics.medium();
                    final shuffled = List<String>.from(selectedPlayers)
                      ..shuffle();
                    onChanged(shuffled);
                    AppSnackBar.show(context, '選手順をシャッフルしました');
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          MultiPlayerSelectInput(
            initialSelected: selectedPlayers,
            label: '部員名簿からタップして追加',
            useRootNavigator: true,
            onConfirm: (list) {
              onChanged(List<String>.from(list));
            },
          ),
          if (selectedPlayers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '確定した配置順（×タップで削除可能）:',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: context.appColors.subTextColor,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: List.generate(selectedPlayers.length, (idx) {
                final name = selectedPlayers[idx];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: themeColors.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: AppRadius.capsule,
                    border: Border.all(
                      color: themeColors.primaryAccent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${idx + 1}. $name',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: themeColors.primaryAccent,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      GestureDetector(
                        onTap: () {
                          AppHaptics.selection();
                          final updated = List<String>.from(selectedPlayers)
                            ..remove(name);
                          onChanged(updated);
                        },
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: themeColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
