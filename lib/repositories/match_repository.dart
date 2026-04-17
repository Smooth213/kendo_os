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

  // 3. 試合を保存・更新（★楽観的ロック対応）
  Future<void> saveMatch(MatchModel match) async {
    final collection = _firestore.collection('matches');
    
    if (match.id.isEmpty) {
      final data = match.toJson();
      data.remove('id');
      data['version'] = 1; // 新規作成時はバージョン1をセット
      await collection.add(data);
    } else {
      try {
        // 現在のDB（またはオフラインキャッシュ）のデータを取得
        final docSnap = await collection.doc(match.id).get();
        final currentVersion = docSnap.data()?['version'] as int? ?? 0;

        // ★ 自分が持っているバージョンが、DBのバージョンより古ければ書き込みを拒否！
        if (match.version < currentVersion) {
          debugPrint('【楽観的ロック】古いバージョンのため書き込みを破棄しました (DB: $currentVersion, Req: ${match.version})');
          return; // エラーは出さず、静かに破棄して最新データを守る
        }

        // バージョンを+1して上書き保存
        final data = match.toJson();
        data['version'] = currentVersion + 1;
        await collection.doc(match.id).set(data);
      } catch (e) {
        debugPrint('保存エラー: $e');
      }
    }
  }
}