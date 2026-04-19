import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tournament_model.dart';

// ★ プロバイダーの定義（ここが重要！）
final tournamentRepositoryProvider = Provider((ref) => TournamentRepository());

class TournamentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 大会を保存する
  Future<String> saveTournament(TournamentModel tournament) async {
    final docRef = await _firestore.collection('tournaments').add(tournament.toJson());
    return docRef.id;
  }

  // ★ 追加：特定の大会IDをリアルタイムで監視する（HomeScreenで使用）
  Stream<TournamentModel?> getTournamentStream(String id) {
    return _firestore.collection('tournaments').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      // IDがモデルに含まれるようにマージして返す
      return TournamentModel.fromJson({...data, 'id': doc.id});
    });
  }

  // ★ 改善：今日の大会（未来含む）だけをリアルタイム監視し、通信量とメモリを極限まで節約！
  Stream<List<TournamentModel>> watchTournaments() {
    final now = DateTime.now();
    final today = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    
    return _firestore
        .collection('tournaments')
        .where('date', isGreaterThanOrEqualTo: today)
        .orderBy('date', descending: false) // 今日から未来へ向けて並べる
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TournamentModel.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  // ★ 追加：過去の大会はリアルタイム監視せず、一度だけ取得してメモリを解放する！
  Future<List<TournamentModel>> getArchivedTournaments() async {
    final now = DateTime.now();
    final today = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    
    final snapshot = await _firestore
        .collection('tournaments')
        .where('date', isLessThan: today)
        .orderBy('date', descending: true) // 過去の大会は新しい順に並べる
        .get();

    return snapshot.docs.map((doc) {
      return TournamentModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // ★ Phase 7-2: 大会と、それに紐づく全試合データを一括削除する（カスケード削除）
  Future<void> deleteTournament(String id) async {
    final batch = _firestore.batch();
    
    // 1. この大会に紐づく試合データをすべて取得して削除バッチに追加
    final matchesSnapshot = await _firestore.collection('matches')
        .where('tournamentId', isEqualTo: id)
        .get();
        
    for (var doc in matchesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // 2. 大会本体の削除をバッチに追加
    batch.delete(_firestore.collection('tournaments').doc(id));
    
    // 3. 一括実行（途中で通信が切れても、データが中途半端に残るのを防ぐ）
    await batch.commit();
  }

  // ★ 追加：大会情報をまるごと更新する
  Future<void> updateTournament(TournamentModel tournament) async {
    await _firestore.collection('tournaments').doc(tournament.id).update(tournament.toJson());
  }

  // ★ 追加：UIからFirestoreの存在を消すための、部分更新メソッド！
  Future<void> updateTournamentDetails(String id, {String? name, String? venue, String? notes, DateTime? date}) async {
    final Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (venue != null) updateData['venue'] = venue;
    if (notes != null) updateData['notes'] = notes;
    if (date != null) updateData['date'] = Timestamp.fromDate(date); // ★ 厄介なTimestamp変換を裏方で引き受ける！

    await _firestore.collection('tournaments').doc(id).update(updateData);
  }
}