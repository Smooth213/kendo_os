import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 大会クイックハブ内の最上部大判プログラムバナー
class TournamentQuickHubBanner extends StatelessWidget {
  final String tournamentId;
  final bool isViewerMode;
  final AppThemeColors themeColors;
  final bool isDark;

  const TournamentQuickHubBanner({
    super.key,
    required this.tournamentId,
    required this.isViewerMode,
    required this.themeColors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptics.light();
        Navigator.pop(context);
        ProgramBottomSheet.show(
          context,
          tournamentId: tournamentId,
          isViewerMode: isViewerMode,
        );
      },
      borderRadius: AppRadius.large,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                : [
                    themeColors.primaryAccent.withValues(alpha: 0.08),
                    themeColors.primaryAccent.withValues(alpha: 0.03),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.large,
          border: Border.all(
            color: themeColors.primaryAccent.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: themeColors.primaryAccent.withValues(alpha: 0.15),
                borderRadius: AppRadius.medium,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: themeColors.primaryAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '大会プログラム・進行表',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: themeColors.textColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.subValue),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.subValue,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppKendoColors.pink.withValues(alpha: 0.2),
                          borderRadius: AppRadius.full,
                        ),
                        child: const Text(
                          '手書きペン対応',
                          style: TextStyle(
                            fontSize: AppFontSize.badge,
                            fontWeight: AppFontWeight.bold,
                            color: AppKendoColors.pink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'タップして素早くプレビュー＆メモ記入',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: themeColors.subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: themeColors.subTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
