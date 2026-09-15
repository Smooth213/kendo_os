import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🛡️ 【Plan 3-3】致命的クラッシュ直前状態の緊急退避（Fatal Crash Trap & Preserver）
class EmergencyCrashPreserver {
  static const String _webCrashDumpKey = 'kendo_os_emergency_crash_dump';
  static MatchModel? _activeMatch;
  static Map<String, dynamic>? _lastActiveContext;

  @visibleForTesting
  static Directory? customDirectory;

  @visibleForTesting
  static bool? isWebOverride;

  static bool get _isWeb => isWebOverride ?? kIsWeb;

  static Future<Directory> _getDirectory() async {
    if (customDirectory != null) return customDirectory!;
    return await getApplicationDocumentsDirectory();
  }

  /// 試合操作画面入場時・状態更新時にアクティブ試合を追跡登録
  static void registerActiveMatch(
    MatchModel match, {
    Map<String, dynamic>? extraContext,
  }) {
    _activeMatch = match;
    _lastActiveContext = extraContext;
  }

  /// 試合操作画面離脱時に登録解除
  static void unregisterActiveMatch(String matchId) {
    if (_activeMatch?.id == matchId) {
      _activeMatch = null;
      _lastActiveContext = null;
    }
  }

  /// 現在追跡中のアクティブ試合
  static MatchModel? get activeMatch => _activeMatch;

  /// クラッシュ（未捕捉例外・レンダリングエラー）発生時の緊急退避実行
  static Future<void> preserveOnCrash({
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final match = _activeMatch;
    if (match == null) return;

    try {
      final dumpData = {
        'timestamp': DateTime.now().toIso8601String(),
        'error': error?.toString(),
        'stackTrace': stackTrace?.toString(),
        'match': match.toJson(),
        'context': _lastActiveContext,
      };
      final jsonStr = jsonEncode(dumpData);

      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_webCrashDumpKey, jsonStr);
        debugPrint(
          '🚨 [Crash Preserver] Web: 緊急クラッシュ退避データを保存しました (ID: ${match.id})',
        );
        return;
      }

      final dir = await _getDirectory();
      final dumpFile = File('${dir.path}/emergency_crash_dump.json');
      await dumpFile.writeAsString(jsonStr, flush: true);
      debugPrint(
        '🚨 [Crash Preserver] Native: 緊急クラッシュ退避ファイルを保存しました: ${dumpFile.path}',
      );
    } catch (e) {
      debugPrint('💥 [Crash Preserver] 緊急退避の書き込みに失敗しました: $e');
    }
  }

  /// 退避されたクラッシュダンプが存在するか確認し読み出す
  static Future<Map<String, dynamic>?> loadRecoverableCrashDump() async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString(_webCrashDumpKey);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        }
        return null;
      }

      final dir = await _getDirectory();
      final dumpFile = File('${dir.path}/emergency_crash_dump.json');
      if (await dumpFile.exists()) {
        final content = await dumpFile.readAsString();
        if (content.isNotEmpty) {
          return jsonDecode(content) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Crash Preserver] クラッシュダンプの読み出しに失敗しました: $e');
    }
    return null;
  }

  /// 復旧完了後にクラッシュダンプを破棄
  static Future<void> clearCrashDump() async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_webCrashDumpKey);
        return;
      }

      final dir = await _getDirectory();
      final dumpFile = File('${dir.path}/emergency_crash_dump.json');
      if (await dumpFile.exists()) {
        await dumpFile.delete();
      }
    } catch (_) {}
  }
}
