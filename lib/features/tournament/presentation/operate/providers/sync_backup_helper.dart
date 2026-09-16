import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_event_cloud_codec.dart';
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

  static Future<void> performReconnectReplay({
    required LocalMatchRepository localRepo,
    required MatchRule rule,
    required RebuildMatchFromEventsUseCase rebuilder,
    required List<MatchModel> matches,
  }) async {
    try {
      int driftCount = 0;
      for (final match in matches) {
        if (match.events.isEmpty) continue;
        MatchModel rebuiltMatch = rebuilder
            .execute(match, rule)
            .copyWith(status: match.status);
        final hasDrift =
            rebuiltMatch.redScore != match.redScore ||
            rebuiltMatch.whiteScore != match.whiteScore;
        if (hasDrift) {
          driftCount++;
          debugPrint('⚠️ [Drift Monitor] 試合 ${match.id} に矛盾検知。修復します。');
          await localRepo.saveMatch(rebuiltMatch);
        }
      }

      if (driftCount > 0) {
        debugPrint('🛠️ [Self-Healing] $driftCount 件の試合を自動修復しました。');
      } else {
        debugPrint('✅ [Drift Monitor] すべての試合状態は歴史(Events)と完全に一致しています。');
      }
    } catch (e) {
      debugPrint('🔥 [Reconnect Replay] 復旧・監査プロセス中にエラーが発生しました: $e');
    }
  }

  static Future<void> setWithVersionPrecondition({
    required FirebaseFirestore firestore,
    required DocumentReference<Map<String, dynamic>> docRef,
    required Map<String, dynamic> data,
    required int? expectedRemoteVersion,
  }) async {
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final actualVersion = snapshot.exists
          ? (snapshot.data()?['version'] as num?)?.toInt() ?? 1
          : null;
      if (actualVersion != expectedRemoteVersion) {
        throw StateError(
          'Remote version changed while syncing: '
          'expected=$expectedRemoteVersion actual=$actualVersion',
        );
      }
      final eventList = data['events'] is List
          ? data['events'] as List
          : const [];
      final cloudData = Map<String, dynamic>.from(data);
      if (eventList.length > MatchEventCloudCodec.hotEventLimit) {
        cloudData['events'] = eventList
            .skip(eventList.length - MatchEventCloudCodec.hotEventLimit)
            .toList();
        cloudData['eventArchiveVersion'] = eventList.length;
        final coldEvents = eventList.take(
          eventList.length - MatchEventCloudCodec.hotEventLimit,
        );
        for (
          var offset = 0;
          offset < coldEvents.length;
          offset += MatchEventCloudCodec.archiveChunkSize
        ) {
          final events = coldEvents
              .skip(offset)
              .take(MatchEventCloudCodec.archiveChunkSize)
              .toList();
          transaction.set(
            docRef
                .collection('events')
                .doc('${offset ~/ MatchEventCloudCodec.archiveChunkSize}'),
            {
              'matchId': docRef.id,
              'chunkIndex': offset ~/ MatchEventCloudCodec.archiveChunkSize,
              'version': offset + events.length,
              'events': events,
            },
          );
        }
      }
      transaction.set(docRef, cloudData);
    });
  }
}
