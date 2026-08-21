import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_single_player_select_sheet.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// クイック対戦: 赤・白選手選択セクション
class BunaiksenQuickMatchPlayerSelectSection extends StatelessWidget {
  final String redPlayer;
  final String whitePlayer;
  final ValueChanged<String> onRedPlayerSelected;
  final ValueChanged<String> onWhitePlayerSelected;
  final WidgetRef ref;

  const BunaiksenQuickMatchPlayerSelectSection({
    super.key,
    required this.redPlayer,
    required this.whitePlayer,
    required this.onRedPlayerSelected,
    required this.onWhitePlayerSelected,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    return Row(
      children: [
        // 赤選手
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppKendoColors.red.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: AppRadius.large,
              border: Border.all(
                color: const Color(0xFFE53935).withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '赤',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                    color: AppKendoColors.hansokuRed,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: () async {
                    final picked = await BunaiksenSinglePlayerSelectSheet.show(
                      context,
                      ref,
                      sideName: '赤',
                      accentColor: AppKendoColors.hansokuRed,
                    );
                    if (picked != null) {
                      onRedPlayerSelected(picked);
                    }
                  },
                  borderRadius: AppRadius.small,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFFFFFFF),
                      borderRadius: AppRadius.small,
                      border: Border.all(
                        color: AppKendoColors.hansokuRed.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            redPlayer,
                            style: TextStyle(
                              fontSize: AppFontSize.subhead,
                              fontWeight: AppFontWeight.bold,
                              color: themeColors.textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppKendoColors.hansokuRed,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'VS',
            style: TextStyle(
              fontWeight: AppFontWeight.black,
              fontSize: AppFontSize.subhead,
              color: AppKendoColors.grey,
            ),
          ),
        ),
        // 白選手
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppKendoColors.blueGrey.withValues(
                alpha: isDark ? 0.15 : 0.08,
              ),
              borderRadius: AppRadius.large,
              border: Border.all(color: const Color(0xFF607D8B), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  '白',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.7)
                        : const Color(0xFF607D8B),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: () async {
                    final picked = await BunaiksenSinglePlayerSelectSheet.show(
                      context,
                      ref,
                      sideName: '白',
                      accentColor: context.appColors.subTextColor,
                    );
                    if (picked != null) {
                      onWhitePlayerSelected(picked);
                    }
                  },
                  borderRadius: AppRadius.small,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFFFFFFF),
                      borderRadius: AppRadius.small,
                      border: Border.all(
                        color: const Color(0xFF607D8B).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            whitePlayer,
                            style: TextStyle(
                              fontSize: AppFontSize.subhead,
                              fontWeight: AppFontWeight.bold,
                              color: themeColors.textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: isDark
                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.7)
                              : const Color(0xFF607D8B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
