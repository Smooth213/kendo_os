import 'package:flutter/foundation.dart'; // ★ debugPrintを使うために追加
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/match_model.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(FirebaseFirestore.instance);
});

class MatchRepository {
  final FirebaseFirestore _firestore;
  MatchRepository(this._firestore);

  // ★ 1-C. 全試合をリアルタイム監視（主にWeb観客席用）
  Stream<List<MatchModel>> watchAllMatches() {
    return _firestore
        .collection('matches')
        .snapshots()
        .map((snapshot) {
      final validMatches = <MatchModel>[];
      for (final doc in snapshot.docs) {
        try {
          validMatches.add(MatchModel.fromJson(<String, dynamic>{
            ...doc.data(),
            'id': doc.id,
          }));
        } catch (e, stack) {
          debugPrint('🔥 [watchAllMatches Parse Error] 試合ID: ${doc.id} のパースに失敗 (スキップします): $e\n$stack');
        }
      }
      return validMatches;
    });
  }

  // 1-A. 進行中と待機中（新規追加）の試合をリアルタイム監視（パケット節約と追加検知を両立）
  Stream<List<MatchModel>> watchActiveMatches() {
    return _firestore
        .collection('matches')
        .where('status', whereIn: ['in_progress', 'waiting'])
        .snapshots()
        .map((snapshot) {
      final validMatches = <MatchModel>[];
      for (final doc in snapshot.docs) {
        try {
          validMatches.add(MatchModel.fromJson(<String, dynamic>{
            ...doc.data(),
            'id': doc.id,
          }));
        } catch (e, stack) {
          debugPrint('🔥 [watchActiveMatches Parse Error] 試合ID: ${doc.id} のパースに失敗 (スキップします): $e\n$stack');
        }
      }
      return validMatches;
    });
  }

  // 1-B. 終了済みの試合を1回だけ取得（キャッシュ用）
  Future<List<MatchModel>> getStaticMatches() async {
    final snapshot = await _firestore
        .collection('matches')
        .where('status', whereIn: ['finished', 'approved'])
        .get();
        
    final validMatches = <MatchModel>[];
    for (final doc in snapshot.docs) {
      try {
        validMatches.add(MatchModel.fromJson(<String, dynamic>{
          ...doc.data(),
          'id': doc.id,
        }));
      } catch (e, stack) {
        debugPrint('🔥 [getStaticMatches Parse Error] 試合ID: ${doc.id} のパースに失敗 (スキップします): $e\n$stack');
      }
    }
    return validMatches;
  }

  // 2. 特定の1試合をリアルタイム監視（MatchProviderで使用）
  Stream<MatchModel> watchSingleMatch(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((doc) {
      return MatchModel.fromJson(<String, dynamic>{
        ...doc.data() ?? {},
        'id': doc.id,
      });
    });
  }

  // 3. 試合を保存・更新
  // ★ Phase 0-3: トランザクション等の詳細ロジックをリポジトリ内に隠蔽する
  Future<void> saveMatch(MatchModel match) async {
    final docRef = _firestore.collection('matches').doc(match.id);
    
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        int remoteVersion = 1;
        if (snapshot.exists) {
          remoteVersion = (snapshot.data()!['version'] as num?)?.toInt() ?? 1;
          // 楽観的ロックのチェック
          if (match.version < remoteVersion) {
            throw Exception('ConflictException: 古いバージョンです');
          }
        }
        
        // 保存時にバージョンをインクリメントし、isDirty フラグを管理する
        final updatedData = match.copyWith(
          version: remoteVersion + 1,
          // ※ ここではまだオンライン前提だが、PHASE 1以降でここを「Local保存のみ」に切り替える
        ).toJson();
        
        transaction.set(docRef, updatedData);
      });
    } catch (e) {
      debugPrint('Repository保存エラー: $e');
      rethrow;
    }
  }
}