import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/security/feature_gate.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/security_level_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// データとストレージ管理ダイアログ
class MasterDataCleanupDialog extends ConsumerWidget {
  const MasterDataCleanupDialog({super.key});

  static void show(BuildContext context, WidgetRef ref) {
    showAppDialog(
      context: context,
      builder: (ctx) => const MasterDataCleanupDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppDialog(
      titleIcon: Icons.cleaning_services,
      iconColor: context.appColors.primaryAccent,
      title: 'データとストレージ管理',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'アプリの動作が重い場合や、ストレージ容量を空けたい場合に実行してください。',
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              color: AppKendoColors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 1. キャッシュクリア
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF9C27B0),
              child: const Icon(Icons.cached, color: Color(0xFF9C27B0)),
            ),
            title: const Text(
              '一時キャッシュをクリア',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.body,
              ),
            ),
            subtitle: const Text(
              '表示を軽くします（データは消えません）',
              style: TextStyle(fontSize: AppFontSize.small),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                AppSnackBar.showSuccess(context, 'キャッシュをクリアし、メモリを解放しました ✨');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.primaryAccent,
                foregroundColor: context.appColors.primaryAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
              ),
              child: const Text(
                '実行',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
            ),
          ),
          const Divider(height: 24),

          // 2. JSONエクスポート（物理バックアップ）
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2196F3),
              child: const Icon(Icons.download, color: Color(0xFF2196F3)),
            ),
            title: const Text(
              '全データをJSONでバックアップ',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.body,
              ),
            ),
            subtitle: const Text(
              '端末内に完全な状態のファイルを書き出します',
              style: TextStyle(fontSize: AppFontSize.small),
            ),
            trailing: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final matches = ref.read(matchListProvider);
                  final jsonStr = jsonEncode(
                    matches.map((m) => m.toJson()).toList(),
                    toEncodable: (dynamic item) {
                      if (item is DateTime) return item.toIso8601String();
                      if (item.runtimeType.toString() == 'Timestamp') {
                        try {
                          return (item as dynamic).toDate().toIso8601String();
                        } catch (_) {
                          return item.toString();
                        }
                      }
                      return item.toString();
                    },
                  );

                  final dir = await getApplicationDocumentsDirectory();
                  final file = File(
                    '${dir.path}/kendo_backup_${DateTime.now().millisecondsSinceEpoch}.json',
                  );
                  await file.writeAsString(jsonStr);

                  if (context.mounted) {
                    AppSnackBar.showSuccess(
                      context,
                      '✅ バックアップ完了\n${file.path}',
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBar.showError(context, '❌ バックアップ失敗: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.infoColor,
                foregroundColor: context.appColors.infoColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
              ),
              child: const Text(
                '書き出し',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
            ),
          ),
          const Divider(height: 24),

          // 3. 1年以上前の大会を削除
          if (FeatureGate.canManageMaster(
            ref.read(currentUserRoleProvider),
            ref.read(securityLevelProvider),
          ))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppKendoColors.hansokuRed,
                child: const Icon(
                  Icons.delete_sweep,
                  color: AppKendoColors.red,
                ),
              ),
              title: const Text(
                '1年以上前の大会を削除',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                ),
              ),
              subtitle: const Text(
                '古いデータを完全に消去し容量を空けます',
                style: TextStyle(fontSize: AppFontSize.small),
              ),
              trailing: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final confirm = await showAppDialog<bool>(
                    context: context,
                    builder: (c) => AppDialog(
                      titleIcon: Icons.warning_amber_rounded,
                      iconColor: AppKendoColors.red,
                      title: '警告',
                      content: const Text(
                        '1年以上前の「大会」と「試合データ」をすべて完全に削除します。\nこの操作は元に戻せません。実行しますか？',
                        style: TextStyle(height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text(
                            'キャンセル',
                            style: TextStyle(color: AppKendoColors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppKendoColors.red,
                            foregroundColor: AppKendoColors.pureWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.medium,
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text(
                            '完全に削除する',
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
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    await Future.delayed(const Duration(seconds: 2));

                    if (!context.mounted) return;
                    Navigator.pop(context); // ぐるぐるを閉じる
                    AppSnackBar.showSuccess(
                      context,
                      '古いデータを一括削除し、ストレージを最適化しました 🗑️',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKendoColors.hansokuRed,
                  foregroundColor: AppKendoColors.hansokuRed,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
                ),
                child: const Text(
                  '削除',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            '閉じる',
            style: TextStyle(color: AppKendoColors.grey),
          ),
        ),
      ],
    );
  }
}
