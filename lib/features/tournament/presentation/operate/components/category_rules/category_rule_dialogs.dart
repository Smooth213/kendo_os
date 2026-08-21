import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 部門ルール管理用ダイアログ群
class CategoryRuleDialogs {
  /// 既存の未開始試合への一括適用確認ダイアログ
  static Future<String?> showBulkApplyConfirmDialog({
    required BuildContext context,
    required String category,
    required int matchCount,
  }) {
    return showAppDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        title: '作成済みの試合に一括適用しますか？',
        content: Text(
          '「$category」の未開始・進行前の試合が $matchCount 件見つかりました。\n'
          '設定したルールをこれらの既存の試合にも今すぐ適用しますか？\n'
          '（※すでに終了した試合のデータは保護されます）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'no'),
            child: const Text('適用しない（新規試合のみ）'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'yes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
              foregroundColor: AppKendoColors.pureWhite,
            ),
            child: const Text(
              '一括適用する',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// 部門削除確認ダイアログ
  static Future<bool?> showDeleteCategoryDialog({
    required BuildContext context,
    required String category,
  }) {
    return showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: '部門を削除しますか？',
        titleIcon: Icons.warning_amber_rounded,
        iconColor: AppKendoColors.red,
        content: Text('「$category」の部門および設定されているデフォルトルールをリストから削除します。よろしいですか？'),
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
              backgroundColor: AppKendoColors.hansokuRed,
              foregroundColor: AppKendoColors.pureWhite,
            ),
            child: const Text(
              '削除',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
