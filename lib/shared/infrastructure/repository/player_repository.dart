import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

// アプリ全体からこの職人（リポジトリ）を呼べるようにするプロバイダー
final playerRepositoryProvider = Provider((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  return PlayerRepository(dojoId: dojoId);
});

class PlayerRepository {
  final FirebaseFirestore _firestore;
  final String dojoId;

  PlayerRepository({required String dojoId, FirebaseFirestore? firestore})
    : dojoId = dojoId.isNotEmpty ? dojoId : 'test201',
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _playersCollection {
    return _firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('players');
  }

  CollectionReference<Map<String, dynamic>> get _customTeamsCollection {
    return _firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('custom_team_names');
  }

  // ① 選手一覧を取得する
  Stream<List<PlayerModel>> getPlayers({String organization = ''}) {
    return _playersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PlayerModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ② 選手を新しく追加する
  Future<void> addPlayer(PlayerModel player) async {
    await _playersCollection.add(player.toMap());
  }

  // ③ 選手の情報を手動で更新する（手動で一般に変更する時など！）
  Future<void> updatePlayer(PlayerModel player) async {
    await _playersCollection.doc(player.id).update(player.toMap());
  }

  // ④ 選手を削除する
  Future<void> deletePlayer(String playerId) async {
    await _playersCollection.doc(playerId).delete();
  }

  // ★⑤ 魔法のボタン用：全員を一括進級させる！（Firestore 500件バッチ制限安全分割）
  Future<void> promoteAllPlayers({String organization = ''}) async {
    final snapshot = await _playersCollection
        .where('organization', isEqualTo: organization)
        .get();

    const int batchLimit = 450;
    WriteBatch batch = _firestore.batch();
    int opCount = 0;

    for (var doc in snapshot.docs) {
      int currentGrade = doc.data()['grade'] as int? ?? 99;

      if (currentGrade < 16) {
        // 未就学〜大学3年まではそのまま +1
        batch.update(doc.reference, {'grade': currentGrade + 1});
        opCount++;
      } else if (currentGrade == 16) {
        // 大学4年(16) は 一般(99) にする
        batch.update(doc.reference, {'grade': 99});
        opCount++;
      }

      if (opCount >= batchLimit) {
        await batch.commit();
        batch = _firestore.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }
  }

  // --- よく使う自チーム名（カスタムチーム名）の管理機能 ---

  /// 所属道場に関連付けられたカスタムチーム名の一覧を監視する
  Stream<List<String>> watchCustomTeamNames({String organization = ''}) {
    return _customTeamsCollection
        .where('organization', isEqualTo: organization)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()['name'] as String).toList()
                ..sort(),
        )
        .handleError((error, stackTrace) {
          // 権限エラーやネットワーク遮断時でも例外をスローせず安全に空リストへフォールバック
          return <String>[];
        });
  }

  /// 新しいカスタムチーム名を追加する
  Future<void> addCustomTeamName(
    String name, {
    String organization = '',
  }) async {
    final docId = '${organization}_$name'; // 重複防止のためのID
    await _customTeamsCollection.doc(docId).set({
      'organization': organization,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// カスタムチーム名を削除する
  Future<void> deleteCustomTeamName(
    String name, {
    String organization = '',
  }) async {
    final docId = '${organization}_$name';
    await _customTeamsCollection.doc(docId).delete();
  }
}
