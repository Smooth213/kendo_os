import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 🥋 プログラム管理画面の単一・一括削除ダイアログヘルパー
class ProgramDeleteDialogHelper {
  ProgramDeleteDialogHelper._();

  /// 単一プログラムの削除確認と実行
  static Future<void> confirmSingleDelete({
    required BuildContext context,
    required WidgetRef ref,
    required ProgramModel program,
  }) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'プログラムの削除',
        titleIcon: Icons.warning_amber_rounded,
        iconColor: AppKendoColors.red,
        content: Text('「${program.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '削除',
              style: TextStyle(
                color: AppKendoColors.red,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(programRepositoryProvider).deleteProgram(program);
    }
  }

  /// 選択した複数プログラムの一括削除確認と実行
  static Future<void> confirmBulkDelete({
    required BuildContext context,
    required WidgetRef ref,
    required List<ProgramModel> allPrograms,
    required Set<String> selectedProgramIds,
    required VoidCallback onDeleted,
  }) async {
    final targets = allPrograms
        .where((p) => selectedProgramIds.contains(p.id))
        .toList();
    if (targets.isEmpty) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'プログラムの一括削除',
        titleIcon: Icons.warning_amber_rounded,
        iconColor: AppKendoColors.red,
        content: Text('選択した ${targets.length}件のプログラムを削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'すべて削除',
              style: TextStyle(
                color: AppKendoColors.red,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(programRepositoryProvider);
        for (final program in targets) {
          await repo.deleteProgram(program);
        }
        onDeleted();
        if (context.mounted) {
          AppSnackBar.showSuccess(context, '${targets.length}件のプログラムを削除しました');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.showError(context, '削除エラー: $e');
        }
      }
    }
  }
}
