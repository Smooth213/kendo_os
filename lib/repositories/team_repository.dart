import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team_model.dart';

final teamRepositoryProvider = Provider((ref) => TeamRepository());

// ★ 追加：自チーム一覧をリアルタイム監視する固定の窓口（リセット防止！）
final registeredTeamsProvider = StreamProvider.family.autoDispose<List<TeamModel>, String>((ref, tournamentId) {
  return ref.watch(teamRepositoryProvider).watchTeamsByTournament(tournamentId);
});

class TeamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // チームを保存・更新し、IDを返す（修正版）
  Future<String> saveTeam(TeamModel team) async {
    if (team.id.isEmpty) {
      // 新規時はidフィールドを除いて保存し、Firestoreが生成したIDを取得する
      final data = team.toJson()..remove('id');
      final docRef = await _firestore.collection('teams').add(data);
      return docRef.id;
    } else {
      await _firestore.collection('teams').doc(team.id).set(team.toJson(), SetOptions(merge: true));
      return team.id;
    }
  }

  // 大会IDに紐づくチーム一覧をリアルタイムで取得する
  Stream<List<TeamModel>> watchTeamsByTournament(String tournamentId) {
    return _firestore
        .collection('teams')
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TeamModel.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  // チームを削除する
  Future<void> deleteTeam(String id) async {
    await _firestore.collection('teams').doc(id).delete();
  }
}