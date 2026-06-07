import 'package:isar_community/isar.dart';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/features/match/domain/match_model.dart'; // SyncState
import '../persistence/models/match_comment_entity.dart';

class LocalCommentRepository {
  final Isar? _isar; // ★ Web環境を考慮しNullableに変更

  LocalCommentRepository(this._isar);

  Future<void> saveComment(MatchCommentModel comment) async {
    // ★ Web環境ではIsarが無効なため処理をスキップ
    if (kIsWeb || _isar == null) return;

    final entity = MatchCommentEntity()
      ..commentId = comment.id
      ..tournamentId = comment.tournamentId
      ..category = comment.category
      ..groupName = comment.groupName
      ..matchGroupId = comment
          .matchGroupId // ★ 追加
      ..text = comment.text
      ..order = comment.order
      ..syncState = comment.syncState
      ..lastUpdatedAt = comment.lastUpdatedAt;

    await _isar.writeTxn(() async {
      await _isar.matchCommentEntitys.put(entity);
    });
  }

  Stream<List<MatchCommentModel>> watchComments(String tournamentId) {
    // ★ Web環境ではIsarが無効なため空のストリームを返す
    if (kIsWeb || _isar == null) return Stream.value([]);

    return _isar.matchCommentEntitys
        .filter()
        .tournamentIdEqualTo(tournamentId)
        .build()
        .watch(fireImmediately: true)
        .map(
          (entities) => entities
              .map(
                (e) => MatchCommentModel(
                  id: e.commentId,
                  tournamentId: e.tournamentId,
                  category: e.category,
                  groupName: e.groupName,
                  matchGroupId: e.matchGroupId, // ★ 追加
                  text: e.text,
                  order: e.order,
                  syncState: e.syncState,
                  lastUpdatedAt: e.lastUpdatedAt,
                ),
              )
              .toList(),
        );
  }

  Future<void> markAsSynced(String id) async {
    // ★ Web環境ではIsarが無効なため処理をスキップ
    if (kIsWeb || _isar == null) return;

    final entity = await _isar.matchCommentEntitys
        .filter()
        .commentIdEqualTo(id)
        .findFirst();
    if (entity != null) {
      entity.syncState = SyncState.synced;
      await _isar.writeTxn(() async {
        await _isar.matchCommentEntitys.put(entity);
      });
    }
  }

  Future<void> deleteComment(String id) async {
    // ★ Web環境ではIsarが無効なため処理をスキップ
    if (kIsWeb || _isar == null) return;

    await _isar.writeTxn(() async {
      final success = await _isar.matchCommentEntitys
          .filter()
          .commentIdEqualTo(id)
          .deleteAll();
      debugPrint(success > 0 ? 'Comment $id deleted' : 'Comment $id not found');
    });
  }
}
