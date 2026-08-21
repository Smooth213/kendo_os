import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:path_provider/path_provider.dart';

/// 自動バックアップ及び古い未送信データのクリーンアップヘルパー
class SyncBackupHelper {
  static Future<void> autoBackupToJson(List<MatchModel> matches) async {
    if (kIsWeb || matches.isEmpty) return;

    try {
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
      final file = File('${dir.path}/kendo_autobackup.json');
      await file.writeAsString(jsonStr);
      debugPrint('💾 [Auto Backup] 自動バックアップ完了: ${file.path}');
    } catch (e) {
      debugPrint('🔥 [Auto Backup] 自動バックアップ失敗: $e');
    }
  }

  static Future<void> cleanupOldPendingData(
    LocalMatchRepository localRepo,
  ) async {
    try {
      final pendingMatches = await localRepo.getPendingMatches();
      final now = DateTime.now();
      for (final match in pendingMatches) {
        if (match.lastUpdatedAt != null &&
            now.difference(match.lastUpdatedAt!).inDays > 30) {
          debugPrint('🧹 [Cleanup] 30日以上経過した古い未送信データを同期対象から除外します: ${match.id}');
          await localRepo.markAsSynced(match.id);
        }
      }
    } catch (e) {
      debugPrint('🔥 [Cleanup] 古い未送信データクリーンアップエラー: $e');
    }
  }
}
