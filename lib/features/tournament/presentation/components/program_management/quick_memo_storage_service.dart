import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🥋 クイックメモの永続化データ
class QuickMemoData {
  final String text;
  final List<MemoStroke> strokes;
  final String modeName;

  const QuickMemoData({
    this.text = '',
    this.strokes = const [],
    this.modeName = 'drawing',
  });
}

/// 🥋 クイックメモの保存・復元サービス（メモリキャッシュ＋SharedPreferences永続化）
class QuickMemoStorageService {
  QuickMemoStorageService._();
  static final QuickMemoStorageService instance = QuickMemoStorageService._();

  // メモリキャッシュ（即時レスポンス・同一セッション保護）
  final Map<String, QuickMemoData> _memoryCache = {};

  static const String _keyPrefix = 'quick_memo_data_v1_';

  /// メモデータを取得（メモリ優先、なければSharedPreferencesから読み込み）
  Future<QuickMemoData> loadMemo(String tournamentId) async {
    // 1. メモリキャッシュがあれば即座に返却
    if (_memoryCache.containsKey(tournamentId)) {
      return _memoryCache[tournamentId]!;
    }

    // 2. SharedPreferences から復元
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$tournamentId';
      final jsonStr = prefs.getString(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final text = map['text'] as String? ?? '';
        final modeName = map['mode'] as String? ?? 'drawing';
        final rawStrokes = map['strokes'] as List<dynamic>? ?? [];
        final strokes = rawStrokes
            .map((s) => MemoStroke.fromJson(s as Map<String, dynamic>))
            .toList();

        final data = QuickMemoData(
          text: text,
          strokes: strokes,
          modeName: modeName,
        );
        _memoryCache[tournamentId] = data;
        return data;
      }
    } catch (e) {
      debugPrint('⚠️ [QuickMemoStorage] loadMemo error: $e');
    }

    const defaultData = QuickMemoData();
    _memoryCache[tournamentId] = defaultData;
    return defaultData;
  }

  /// メモデータを保存
  Future<void> saveMemo({
    required String tournamentId,
    required String text,
    required List<MemoStroke> strokes,
    required String modeName,
  }) async {
    final data = QuickMemoData(
      text: text,
      strokes: List.unmodifiable(strokes),
      modeName: modeName,
    );
    // 1. メモリキャッシュを即時更新
    _memoryCache[tournamentId] = data;

    // 2. 非同期で SharedPreferences へ保存
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$tournamentId';
      final map = {
        'text': text,
        'mode': modeName,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(key, jsonEncode(map));
    } catch (e) {
      debugPrint('⚠️ [QuickMemoStorage] saveMemo error: $e');
    }
  }

  /// メモを全消去
  Future<void> clearMemo(String tournamentId) async {
    _memoryCache.remove(tournamentId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$tournamentId';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('⚠️ [QuickMemoStorage] clearMemo error: $e');
    }
  }
}
