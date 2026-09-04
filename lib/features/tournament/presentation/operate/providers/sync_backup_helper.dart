import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/utils/kendo_compute_helper.dart';
import 'package:kendo_os/shared/utils/payload_compression_helper.dart';
import 'package:path_provider/path_provider.dart';

/// 🧵 【Phase 4】Isolate内で実行される重いJSONエンコード処理
String _encodeMatchesToJsonString(List<Map<String, dynamic>> rawList) {
  return jsonEncode(
    rawList,
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
}

/// 自動バックアップ及び古い未送信データのクリーンアップヘルパー
class SyncBackupHelper {
  static Future<void> autoBackupToJson(List<MatchModel> matches) async {
    if (kIsWeb || matches.isEmpty) return;

    try {
      // 🧵 【Phase 4】重計算Isolate分離: 大量試合データのJSONエンコードを別スレッドで実行
      final rawList = matches.map((m) => m.toJson()).toList();
      final jsonStr = await KendoComputeHelper.run(
        _encodeMatchesToJsonString,
        rawList,
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/kendo_autobackup.json');
      await file.writeAsString(jsonStr);

      // 📶 【Phase 9】通信パケット・同期ペイロード極小化（Gzip圧縮）: バックアップをGzip圧縮保存
      final compressedBytes = PayloadCompressionHelper.compressString(jsonStr);
      final gzFile = File('${dir.path}/kendo_autobackup.json.gz');
      await gzFile.writeAsBytes(compressedBytes);

      final savings = PayloadCompressionHelper.calculateSavingsPercent(
        originalSize: jsonStr.length,
        compressedSize: compressedBytes.length,
      );
      debugPrint(
        '💾 [Auto Backup] 自動バックアップ完了: ${file.path} (Gzip圧縮版: ${gzFile.path}, 削減率: ${savings.toStringAsFixed(1)}%)',
      );
    } catch (e) {
      debugPrint('🔥 [Auto Backup] 自動バックアップ失敗: $e');
    }
  }

  /// 📶 【Phase 9】Gzip圧縮バックアップファイルからデータを読み出し
  static Future<String?> loadCompressedBackup(File gzFile) async {
    try {
      if (!await gzFile.exists()) return null;
      final bytes = await gzFile.readAsBytes();
      return PayloadCompressionHelper.decompressToString(bytes);
    } catch (e) {
      debugPrint('🔥 [Auto Backup] Gzipバックアップ読み込み失敗: $e');
      return null;
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
