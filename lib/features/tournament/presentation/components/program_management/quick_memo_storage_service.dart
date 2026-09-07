import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🥋 クイックメモの永続化データ
class QuickMemoData {
  final String text;
  final List<MemoStroke> strokes;
  final String modeName;
  final DateTime? updatedAt;

  const QuickMemoData({
    this.text = '',
    this.strokes = const [],
    this.modeName = 'drawing',
    this.updatedAt,
  });

  bool get isEmpty => text.isEmpty && strokes.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// 🥋 クイックメモの保存・復元サービス（メモリキャッシュ＋SharedPreferences＋Firestoreクラウド同期）
class QuickMemoStorageService {
  QuickMemoStorageService._();
  static final QuickMemoStorageService instance = QuickMemoStorageService._();

  // メモリキャッシュ（即時レスポンス・同一セッション保護）
  final Map<String, QuickMemoData> _memoryCache = {};

  static const String _keyPrefix = 'quick_memo_data_v1_';

  /// Google連携中のUIDを取得（未連携・Firebase未初期化ならnull）
  String? get _linkedUid {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final isGoogle = user.providerData.any(
        (p) => p.providerId == 'google.com',
      );
      return isGoogle ? user.uid : null;
    } catch (_) {
      return null;
    }
  }

  String _resolveId(String id) =>
      id.trim().isNotEmpty ? id.trim() : 'default_quick_memo';

  /// メモデータを取得（未連携時はメモリ・ローカル即時、Google連携時はFirestore最新データを取得・同期）
  Future<QuickMemoData> loadMemo(
    String tournamentId, {
    bool forceCloudRefresh = false,
  }) async {
    final uid = _linkedUid;
    final resolvedId = _resolveId(tournamentId);

    // 1. 未連携時（ローカル単体運用）かつ強制リフレッシュでない場合はメモリキャッシュを即座に返却
    if (uid == null &&
        !forceCloudRefresh &&
        _memoryCache.containsKey(resolvedId)) {
      return _memoryCache[resolvedId]!;
    }

    QuickMemoData? localData;

    // 2. SharedPreferences / メモリ から復元
    if (_memoryCache.containsKey(resolvedId)) {
      localData = _memoryCache[resolvedId];
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = '$_keyPrefix$resolvedId';
        final jsonStr = prefs.getString(key);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final text = map['text'] as String? ?? '';
          final modeName = map['mode'] as String? ?? 'drawing';
          final rawStrokes = map['strokes'] as List<dynamic>? ?? [];
          final updatedAtStr = map['updatedAt'] as String?;
          final strokes = rawStrokes
              .map((s) => MemoStroke.fromJson(s as Map<String, dynamic>))
              .toList();

          localData = QuickMemoData(
            text: text,
            strokes: strokes,
            modeName: modeName,
            updatedAt: updatedAtStr != null
                ? DateTime.tryParse(updatedAtStr)
                : null,
          );
        }
      } catch (e) {
        debugPrint('⚠️ [QuickMemoStorage] loadMemo (local) error: $e');
      }
    }

    // 3. Google連携中の場合、Firestoreのクラウドデータを取得・同期
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('quick_memos')
            .doc(resolvedId)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final text = data['text'] as String? ?? '';
          final modeName = data['mode'] as String? ?? 'drawing';
          final rawStrokes = data['strokes'] as List<dynamic>? ?? [];
          final updatedAtStr = data['updatedAt'] as String?;
          final cloudUpdatedAt = updatedAtStr != null
              ? DateTime.tryParse(updatedAtStr)
              : null;
          final strokes = rawStrokes
              .map((s) => MemoStroke.fromJson(s as Map<String, dynamic>))
              .toList();

          final cloudData = QuickMemoData(
            text: text,
            strokes: strokes,
            modeName: modeName,
            updatedAt: cloudUpdatedAt,
          );

          // クラウドにデータがある場合、ローカルより新しいか、ローカルが空ならクラウドデータを採用
          if (localData == null ||
              localData.isEmpty ||
              cloudUpdatedAt == null ||
              localData.updatedAt == null ||
              cloudUpdatedAt.isAfter(localData.updatedAt!) ||
              cloudUpdatedAt.isAtSameMomentAs(localData.updatedAt!)) {
            localData = cloudData;
            await _saveToLocal(resolvedId, cloudData);
          }
        } else if (localData != null && localData.isNotEmpty) {
          // クラウドになくローカルにある場合は、クラウドへ初期バックアップ
          _saveToCloud(uid, resolvedId, localData);
        }
      } catch (e) {
        debugPrint('⚠️ [QuickMemoStorage] loadMemo (cloud) error: $e');
      }
    }

    final result = localData ?? const QuickMemoData();
    _memoryCache[resolvedId] = result;
    return result;
  }

  /// 🥋 クラウドメモのリアルタイム変更を監視するストリーム（他端末での更新を即時検知）
  Stream<QuickMemoData> watchMemo(String tournamentId) {
    final uid = _linkedUid;
    final resolvedId = _resolveId(tournamentId);
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('quick_memos')
        .doc(resolvedId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) {
            return const QuickMemoData();
          }
          final data = doc.data()!;
          final text = data['text'] as String? ?? '';
          final modeName = data['mode'] as String? ?? 'drawing';
          final rawStrokes = data['strokes'] as List<dynamic>? ?? [];
          final updatedAtStr = data['updatedAt'] as String?;
          final cloudUpdatedAt = updatedAtStr != null
              ? DateTime.tryParse(updatedAtStr)
              : null;
          final strokes = rawStrokes
              .map((s) => MemoStroke.fromJson(s as Map<String, dynamic>))
              .toList();

          final memoData = QuickMemoData(
            text: text,
            strokes: strokes,
            modeName: modeName,
            updatedAt: cloudUpdatedAt,
          );
          _memoryCache[resolvedId] = memoData;
          _saveToLocal(resolvedId, memoData);
          return memoData;
        });
  }

  /// メモデータを保存（メモリ即時 ➔ SharedPreferences ➔ Google連携時はFirestoreへ非同期同期）
  Future<void> saveMemo({
    required String tournamentId,
    required String text,
    required List<MemoStroke> strokes,
    required String modeName,
  }) async {
    final resolvedId = _resolveId(tournamentId);
    final now = DateTime.now();
    final data = QuickMemoData(
      text: text,
      strokes: List.unmodifiable(strokes),
      modeName: modeName,
      updatedAt: now,
    );

    // 1. メモリキャッシュを即時更新
    _memoryCache[resolvedId] = data;

    // 2. ローカル SharedPreferences へ保存
    await _saveToLocal(resolvedId, data);

    // 3. Google連携中なら Firestore へ非同期保存
    final uid = _linkedUid;
    if (uid != null) {
      _saveToCloud(uid, resolvedId, data);
    }
  }

  /// ローカル SharedPreferences 保存ヘルパー
  Future<void> _saveToLocal(String resolvedId, QuickMemoData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$resolvedId';
      final map = {
        'text': data.text,
        'mode': data.modeName,
        'strokes': data.strokes.map((s) => s.toJson()).toList(),
        'updatedAt':
            data.updatedAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
      };
      await prefs.setString(key, jsonEncode(map));
    } catch (e) {
      debugPrint('⚠️ [QuickMemoStorage] _saveToLocal error: $e');
    }
  }

  /// クラウド Firestore 保存ヘルパー（失敗しても例外を握りつぶしてローカル保護）
  void _saveToCloud(String uid, String resolvedId, QuickMemoData data) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('quick_memos')
        .doc(resolvedId)
        .set({
          'text': data.text,
          'mode': data.modeName,
          'strokes': data.strokes.map((s) => s.toJson()).toList(),
          'updatedAt':
              data.updatedAt?.toIso8601String() ??
              DateTime.now().toIso8601String(),
        }, SetOptions(merge: true))
        .then((_) {
          debugPrint(
            '☁️ [QuickMemoStorage] Cloud synced successfully: $resolvedId (uid: $uid)',
          );
        })
        .catchError((e) {
          debugPrint('⚠️ [QuickMemoStorage] _saveToCloud error: $e');
        });
  }

  /// メモを全消去（メモリ、ローカル、Firestoreすべてからクリア）
  Future<void> clearMemo(String tournamentId) async {
    final resolvedId = _resolveId(tournamentId);
    _memoryCache.remove(resolvedId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$resolvedId';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('⚠️ [QuickMemoStorage] clearMemo local error: $e');
    }

    final uid = _linkedUid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('quick_memos')
          .doc(resolvedId)
          .delete()
          .catchError((e) {
            debugPrint('⚠️ [QuickMemoStorage] clearMemo cloud error: $e');
          });
    }
  }
}
