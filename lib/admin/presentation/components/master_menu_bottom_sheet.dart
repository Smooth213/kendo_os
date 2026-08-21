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

/// 選手マスタ画面の管理メニューボトムシート（データクリーンアップ・一括進級）
class MasterMenuBottomSheet {
  static void show(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAppBottomSheet(
      context: context,
      builder: (ctx) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.appColors.cardBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xlargeValue),
          ),
        ),
        child: Material(
          color: AppKendoColors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0x8A000000),
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppKendoColors.purple.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      Icons.cleaning_services,
                      color: const Color(0xFF9C27B0),
                    ),
                  ),
                  title: Text(
                    'データとストレージ管理',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF38383A)
                        : context.appColors.separatorColor,
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppKendoColors.indigo.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(Icons.school, color: const Color(0xFF3F51B5)),
                  ),
                  title: Text(
                    '新年度の一括進級',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
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
      ),
    );
  }

  static void _showPromoteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        titleIcon: Icons.school,
        iconColor: context.appColors.primaryAccent,
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
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: AppKendoColors.pureWhite,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
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
        builder: (_) => const Center(child: CircularProgressIndicator()),
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
