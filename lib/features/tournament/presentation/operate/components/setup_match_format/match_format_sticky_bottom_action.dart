import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

class MatchFormatStickyBottomAction extends ConsumerWidget {
  final int currentPage;
  final bool isLastPage;
  final AppThemeColors themeColors;
  final VoidCallback onPrevious;
  final VoidCallback onNextOrComplete;

  const MatchFormatStickyBottomAction({
    super.key,
    required this.currentPage,
    required this.isLastPage,
    required this.themeColors,
    required this.onPrevious,
    required this.onNextOrComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );

    final bottomColor = enableLiquidGlass
        ? AppKendoColors.transparent
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));
    final borderColor = enableLiquidGlass
        ? AppKendoColors.transparent
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
      child: Row(
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
              onPressed: onNextOrComplete,
              color: themeColors.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              icon: isLastPage ? Icons.check_circle : Icons.navigate_next,
              label: isLastPage ? 'このルールで枠を作成' : '次へ進む',
              expandContent: false,
            ),
          ),
        ],
      ),
    );
  }
}
