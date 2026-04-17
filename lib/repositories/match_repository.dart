import 'package:flutter/foundation.dart'; // ★ debugPrintを使うために追加
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(FirebaseFirestore.instance);
});

class MatchRepository {
  final FirebaseFirestore _firestore;
  MatchRepository(this._firestore);

  // 1. 試合一覧をリアルタイム取得（MatchListProviderで使用）
  Stream<List<MatchModel>> watchMatches() {
    return _firestore
        .collection('matches')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MatchModel.fromJson(data);
      }).toList();
    });
  }

  // 2. 特定の1試合をリアルタイム監視（MatchProviderで使用）
  Stream<MatchModel> watchSingleMatch(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((doc) {
      final data = doc.data() ?? {};
      data['id'] = doc.id;
      return MatchModel.fromJson(data);
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