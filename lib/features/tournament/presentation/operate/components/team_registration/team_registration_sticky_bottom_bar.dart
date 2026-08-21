import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// チーム登録画面用 最下部固定アクションバー
class TeamRegistrationStickyBottomBar extends ConsumerWidget {
  final int currentPage;
  final String? editingTeamId;
  final AppThemeColors themeColors;
  final VoidCallback onPrevious;
  final VoidCallback onPrimaryAction;
  final VoidCallback onFinishToRules;

  const TeamRegistrationStickyBottomBar({
    super.key,
    required this.currentPage,
    required this.editingTeamId,
    required this.themeColors,
    required this.onPrevious,
    required this.onPrimaryAction,
    required this.onFinishToRules,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final bottomColor = enableLiquidGlass
        ? Colors.transparent
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));
    final borderColor = enableLiquidGlass
        ? Colors.transparent
        : (isDark ? const Color(0xFF38383A) : const Color(0x33000000));

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bottomColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (currentPage > 0)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: OutlinedButton(
                    onPressed: onPrevious,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      shape: const CircleBorder(),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: themeColors.primaryAccent,
                    ),
                  ),
                ),
              Expanded(
                child: GlassButton(
                  onPressed: onPrimaryAction,
                  color: themeColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  label: currentPage == 2
                      ? (editingTeamId != null ? '変更を保存' : '登録して続けて追加')
                      : '次へ進む',
                  icon: currentPage == 2
                      ? (editingTeamId != null ? Icons.save : Icons.add_task)
                      : null,
                  expandContent: false,
                ),
              ),
            ],
          ),
          if (currentPage == 2) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: onFinishToRules,
                color: themeColors.primaryAccent,
                icon: Icons.navigate_next,
                label: '登録を完了してルール設定へ',
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                expandContent: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
