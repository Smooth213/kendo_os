import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 選手マスタ画面の単一・一括削除ダイアログヘルパー
class MasterDeleteDialogHelper {
  static void confirmSingleDelete(
    BuildContext context,
    WidgetRef ref,
    PlayerModel player,
  ) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: '削除の確認',
        content: const Text('選手データを完全に削除します。この操作は取り消せません。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final dojoId = ref.read(currentDojoIdProvider);
              final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
              final firestore = ref.read(firestoreProvider);
              await firestore
                  .collection('organizations')
                  .doc(safeDojoId)
                  .collection('players')
                  .doc(player.id)
                  .delete();
            },
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
  }

  static void confirmBulkDelete({
    required BuildContext context,
    required WidgetRef ref,
    required Set<String> selectedPlayerIds,
    required VoidCallback onDeleted,
  }) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: '一括削除の確認',
        content: Text(
          '${selectedPlayerIds.length}人の選手データを完全に削除します。この操作は取り消せません。よろしいですか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              final idsToDelete = selectedPlayerIds.toList();
              Navigator.pop(ctx);

              final dojoId = ref.read(currentDojoIdProvider);
              final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
              final firestore = ref.read(firestoreProvider);
              final batch = firestore.batch();

              for (final id in idsToDelete) {
                final docRef = firestore
                    .collection('organizations')
                    .doc(safeDojoId)
                    .collection('players')
                    .doc(id);
                batch.delete(docRef);
              }

              await batch.commit();
              onDeleted();
            },
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
  }
}
