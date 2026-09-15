import 'package:flutter/foundation.dart'; // ★ debugPrintを使うために追加
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_event_cloud_codec.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  final tournamentId = ref.watch(currentTournamentIdProvider);
  return MatchRepository(FirebaseFirestore.instance, dojoId, tournamentId);
});

class MatchRepository {
  final FirebaseFirestore _firestore;
  final String _dojoId;
  final String _tournamentId;
  MatchRepository(this._firestore, this._dojoId, [this._tournamentId = '']);

  // ★ 対象となるテナントのコレクション参照を取得するヘルパー
  CollectionReference<Map<String, dynamic>> get _collectionRef {
    final dojo = _dojoId.isNotEmpty ? _dojoId : 'default_org';
    final tournament = _tournamentId.isNotEmpty
        ? _tournamentId
        : 'default_tournament';
    return _firestore
        .collection('organizations')
        .doc(dojo)
        .collection('tournaments')
        .doc(tournament)
        .collection('matches');
  }

  // ★ 1-C. 全試合をリアルタイム監視（主にWeb観客席用）
  Stream<List<MatchModel>> watchAllMatches() {
    return _collectionRef
        .snapshots()
        .asyncMap((snapshot) => Future.wait(snapshot.docs.map(_readMatch)))
        .map((matches) => matches.whereType<MatchModel>().toList());
  }

  // 1-A. 進行中と待機中（新規追加）の試合をリアルタイム監視（パケット節約と追加検知を両立）
  Stream<List<MatchModel>> watchActiveMatches() {
    return _collectionRef
        .where('status', whereIn: ['in_progress', 'waiting'])
        .snapshots()
        .asyncMap((snapshot) => Future.wait(snapshot.docs.map(_readMatch)))
        .map((matches) => matches.whereType<MatchModel>().toList());
  }

  // 1-B. 終了済みの試合を1回だけ取得（キャッシュ用）
  Future<List<MatchModel>> getStaticMatches() async {
    final snapshot = await _collectionRef
        .where('status', whereIn: ['finished', 'approved'])
        .get();

    final matches = await Future.wait(snapshot.docs.map(_readMatch));
    return matches.whereType<MatchModel>().toList();
  }

  // 2. 特定の1試合をリアルタイム監視（MatchProviderで使用）
  Stream<MatchModel> watchSingleMatch(String matchId) {
    return _collectionRef
        .doc(matchId)
        .snapshots()
        .where((doc) => doc.exists)
        .asyncMap(_readMatch)
        .where((match) => match != null)
        .cast<MatchModel>();
  }

  Future<MatchModel?> _readMatch(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      final data = <String, dynamic>{...doc.data() ?? {}, 'id': doc.id};
      if (data['eventArchiveVersion'] != null) {
        final chunks = await doc.reference.collection('events').get();
        if (chunks.docs.isNotEmpty) {
          final archived = chunks.docs
              .map((chunk) => chunk.data()['events'])
              .whereType<List>()
              .expand((events) => events)
              .toList();
          data['events'] = [
            ...archived,
            ...(data['events'] as List? ?? const []),
          ];
        }
      }
      return MatchModel.fromJson(data);
    } catch (e, stack) {
      debugPrint(
        '🔥 [MatchRepository Parse Error] 試合ID: ${doc.id}: $e\n$stack',
      );
      return null;
    }
  }

  // 3. 試合を保存・更新
  // ★ Phase 0-3: トランザクション等の詳細ロジックをリポジトリ内に隠蔽する
  Future<int> saveMatch(MatchModel match) async {
    // ★ モデルに organizationId が設定されている場合はそちらを優先する（安全策）
    final targetOrgId =
        (match.organizationId.isNotEmpty &&
            match.organizationId != 'default_org')
        ? match.organizationId
        : _dojoId;

    final targetTournamentId =
        (match.tournamentId != null && match.tournamentId!.isNotEmpty)
        ? match.tournamentId!
        : (_tournamentId.isNotEmpty ? _tournamentId : 'default_tournament');

    final docRef = _firestore
        .collection('organizations')
        .doc(targetOrgId)
        .collection('tournaments')
        .doc(targetTournamentId)
        .collection('matches')
        .doc(match.id);

    int nextVersion = match.version;

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

        nextVersion = remoteVersion + 1;

        // 保存時にバージョンをインクリメントし、isDirty フラグを管理する
        final cloudMatch = match.copyWith(version: nextVersion);
        transaction.set(docRef, MatchEventCloudCodec.matchData(cloudMatch));
        for (final archive in MatchEventCloudCodec.archiveData(cloudMatch)) {
          final chunkIndex = archive['chunkIndex'] as int;
          transaction.set(
            docRef.collection('events').doc('$chunkIndex'),
            archive,
          );
        }
      });
      return nextVersion;
    } catch (e) {
      debugPrint('Repository保存エラー: $e');
      rethrow;
    }
  }

  // 4. 試合を削除
  Future<void> deleteMatch(String matchId) async {
    try {
      final matchRef = _collectionRef.doc(matchId);
      final eventChunks = await matchRef.collection('events').get();
      final batch = _firestore.batch();
      for (final chunk in eventChunks.docs) {
        batch.delete(chunk.reference);
      }
      batch.delete(matchRef);
      await batch.commit();
    } catch (e) {
      debugPrint('Repository削除エラー: $e');
      rethrow;
    }
  }
}
