import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/admin/presentation/components/master_data_cleanup_dialog.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';

/// 選手マスタ画面の管理メニューボトムシート（データクリーンアップ・一括進級）
class MasterMenuBottomSheet {
  static void show(BuildContext context, WidgetRef ref) {
    final themeColors = context.appColors;

    showAppBottomSheet(
      context: context,
      builder: (ctx) => AppBottomSheetContent(
        showDragHandle: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppKendoColors.purple.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.cleaning_services,
                    color: AppKendoColors.purple,
                  ),
                ),
                title: Text(
                  'データとストレージ管理',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                ),
                subtitle: const Text(
                  'キャッシュクリアやデータのエクスポート・整理を行います',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: AppKendoColors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showAppDialog(
                    context: context,
                    builder: (dialogCtx) => const MasterDataCleanupDialog(),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Divider(height: 1, color: themeColors.separatorColor),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppKendoColors.indigo.withValues(alpha: 0.1),
                  child: const Icon(Icons.school, color: AppKendoColors.indigo),
                ),
                title: Text(
                  '新年度の一括進級',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                ),
                subtitle: const Text(
                  'すべての選手の学年を1つ繰り上げます',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: AppKendoColors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPromoteConfirmDialog(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showPromoteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final themeColors = context.appColors;

    final confirm = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        titleIcon: Icons.school,
        iconColor: themeColors.primaryAccent,
        title: '新年度の一括進級',
        content: const Text(
          'すべての選手の学年を1つ繰り上げます。\n（例：小学6年 ➔ 中学1年）\n\n※この操作は取り消せません。本当によろしいですか？',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppKendoColors.purple,
              foregroundColor: AppKendoColors.pureWhite,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.medium,
              ),
              elevation: 0,
            ),
            child: const Text(
              '一括進級を実行',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      showAppDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: AppLoadingIndicator()),
      );
      try {
        await ref.read(playerRepositoryProvider).promoteAllPlayers();
        if (!context.mounted) return;
        Navigator.pop(context);
        AppSnackBar.showSuccess(context, '一括進級が完了しました🌸');
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context);
        AppSnackBar.showError(context, 'エラーが発生しました: $e');
      }
    }
  }
}
