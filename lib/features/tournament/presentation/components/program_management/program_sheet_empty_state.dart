import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 プログラム未登録時の案内コンポーネント
class ProgramSheetEmptyState extends StatelessWidget {
  final String tournamentId;
  final bool isViewerMode;
  final AppThemeColors themeColors;

  const ProgramSheetEmptyState({
    super.key,
    required this.tournamentId,
    required this.isViewerMode,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 56,
            color: themeColors.subTextColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isViewerMode
                ? '大会プログラムはまだ登録されていません'
                : 'プログラム（進行表・トーナメント表）を登録してください',
            style: TextStyle(
              color: themeColors.subTextColor,
              fontSize: AppFontSize.body,
            ),
          ),
          if (!isViewerMode) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('プログラムを追加する'),
              onPressed: () {
                FloatingDockSheetManager.close(immediate: true);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                context.push('/tournament/$tournamentId/programs');
              },
            ),
          ],
        ],
      ),
    );
  }
}
