import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_model.dart';

// アプリ全体からこの職人（リポジトリ）を呼べるようにするプロバイダー
final playerRepositoryProvider = Provider((ref) => PlayerRepository());

class PlayerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ① 選手一覧を取得する（道上剣友会のメンバーだけを取るなど）
  Stream<List<PlayerModel>> getPlayers({String organization = '道上剣友会'}) {
    return _firestore
        .collection('players')
        .where('organization', isEqualTo: organization)
        // .orderBy('grade') // ★ここをコメントアウト（無効化）！
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PlayerModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ② 選手を新しく追加する
  Future<void> addPlayer(PlayerModel player) async {
    await _firestore.collection('players').add(player.toMap());
  }

  // ③ 選手の情報を手動で更新する（手動で一般に変更する時など！）
  Future<void> updatePlayer(PlayerModel player) async {
    await _firestore.collection('players').doc(player.id).update(player.toMap());
  }

  // ④ 選手を削除する
  Future<void> deletePlayer(String playerId) async {
    await _firestore.collection('players').doc(playerId).delete();
  }

  // ★⑤ 魔法のボタン用：全員を一括進級させる！
  Future<void> promoteAllPlayers({String organization = '道上剣友会'}) async {
    final snapshot = await _firestore
        .collection('players')
        .where('organization', isEqualTo: organization)
        .get();

    // 複数データを一気に更新するためのバッチ処理（途中で失敗せんように）
    final batch = _firestore.batch();

    for (var doc in snapshot.docs) {
      int currentGrade = doc.data()['grade'] as int? ?? 99;
      
      if (currentGrade < 16) {
        // 未就学〜大学3年まではそのまま +1
        batch.update(doc.reference, {'grade': currentGrade + 1});
      } else if (currentGrade == 16) {
        // 大学4年(16) は 一般(99) にする
        batch.update(doc.reference, {'grade': 99});
      }
      // すでに一般(99)の人はそのまま放置
    }

    // 変更を一斉に保存！
    await batch.commit();
  }
}