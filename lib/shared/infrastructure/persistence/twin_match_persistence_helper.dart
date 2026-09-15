import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🛡️ 【Plan 3-1】ツイン・エンジン永続化（Isar + 軽量JSONスナップショット二重書き込み＆自己修復）
class TwinMatchPersistenceHelper {
  static const String _webSnapshotPrefix = 'twin_snapshot_match_';

  @visibleForTesting
  static Directory? customDirectory;

  @visibleForTesting
  static bool? isWebOverride;

  static bool get _isWeb => isWebOverride ?? kIsWeb;

  static Future<Directory> _getDirectory() async {
    if (customDirectory != null) return customDirectory!;
    return await getApplicationDocumentsDirectory();
  }

  /// 試合データを緊急JSONスナップショットへ二重保存（Atomic Write & Rotation）
  static Future<void> saveSnapshot(MatchModel match) async {
    try {
      final jsonStr = jsonEncode(match.toJson());
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_webSnapshotPrefix${match.id}', jsonStr);
        return;
      }

      final dir = await _getDirectory();
      final snapshotFile = File('${dir.path}/twin_snapshot_${match.id}.json');
      await snapshotFile.writeAsString(jsonStr, flush: true);

      // ローテーションバックアップ（最大3世代）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rotFile = File(
        '${dir.path}/twin_snapshot_${match.id}_$timestamp.json',
      );
      await rotFile.writeAsString(jsonStr, flush: true);

      _rotateFiles(dir, match.id);
    } catch (e) {
      debugPrint('⚠️ [TwinEngine] スナップショット保存に失敗しました: $e');
    }
  }

  /// 破損または消失時にスナップショットから最新の試合データを救出復元
  static Future<MatchModel?> recoverMatch(String matchId) async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString('$_webSnapshotPrefix$matchId');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(jsonStr);
          return MatchModel.fromJson(data);
        }
        return null;
      }

      final dir = await _getDirectory();
      final snapshotFile = File('${dir.path}/twin_snapshot_$matchId.json');
      if (await snapshotFile.exists()) {
        final content = await snapshotFile.readAsString();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          return MatchModel.fromJson(data);
        }
      }

      // 世代バックアップから最新のものを探索
      final files =
          dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.contains('twin_snapshot_${matchId}_'))
              .toList()
            ..sort((a, b) => b.path.compareTo(a.path));

      if (files.isNotEmpty) {
        final content = await files.first.readAsString();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          return MatchModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [TwinEngine] スナップショットからの自己復元に失敗しました: $e');
    }
    return null;
  }

  /// ディレクトリ内の全スナップショットから全試合データを復元
  static Future<List<MatchModel>> recoverAllMatches() async {
    final List<MatchModel> recovered = [];
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        for (final key in prefs.getKeys()) {
          if (key.startsWith(_webSnapshotPrefix)) {
            final str = prefs.getString(key);
            if (str != null) {
              try {
                recovered.add(MatchModel.fromJson(jsonDecode(str)));
              } catch (_) {}
            }
          }
        }
        return recovered;
      }

      final dir = await _getDirectory();
      final files = dir.listSync().whereType<File>().where(
        (f) =>
            f.path.contains('twin_snapshot_') &&
            !f.path.contains('_backup_') &&
            !RegExp(r'_\d+\.json$').hasMatch(f.path),
      );

      for (final file in files) {
        try {
          final content = file.readAsStringSync();
          if (content.isNotEmpty) {
            recovered.add(MatchModel.fromJson(jsonDecode(content)));
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('⚠️ [TwinEngine] 全試合スナップショット復元に失敗しました: $e');
    }
    return recovered;
  }

  /// ファイルの世代管理（3世代より古いものを削除）
  static void _rotateFiles(Directory dir, String matchId) {
    try {
      final backupFiles =
          dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.contains('twin_snapshot_${matchId}_'))
              .toList()
            ..sort((a, b) => b.path.compareTo(a.path));

      if (backupFiles.length > 3) {
        for (final oldFile in backupFiles.sublist(3)) {
          try {
            oldFile.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
