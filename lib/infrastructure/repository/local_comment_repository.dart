import 'package:isar_community/isar.dart';
import '../../domain/entities/match_comment_model.dart';
import '../../domain/entities/match_model.dart'; // SyncState
import '../persistence/models/match_comment_entity.dart';

class LocalCommentRepository {
  final Isar _isar;

  LocalCommentRepository(this._isar);

  Future<void> saveComment(MatchCommentModel comment) async {
    final entity = MatchCommentEntity()
      ..id = comment.id
      ..tournamentId = comment.tournamentId
      ..category = comment.category
      ..groupName = comment.groupName
      ..text = comment.text
      ..order = comment.order
      ..syncState = comment.syncState
      ..lastUpdatedAt = comment.lastUpdatedAt;

    await _isar.writeTxn(() async {
      await _isar.matchCommentEntitys.put(entity);
    });
  }

  Stream<List<MatchCommentModel>> watchComments(String tournamentId) {
    return _isar.matchCommentEntitys
        .filter()
        .tournamentIdEqualTo(tournamentId)
        .build()
        .watch(fireImmediately: true)
        .map((entities) => entities.map((e) => MatchCommentModel(
              id: e.id,
              tournamentId: e.tournamentId,
              category: e.category,
              groupName: e.groupName,
              text: e.text,
              order: e.order,
              syncState: e.syncState,
              lastUpdatedAt: e.lastUpdatedAt,
            )).toList());
  }

  Future<void> markAsSynced(String id) async {
    final entity = await _isar.matchCommentEntitys.filter().idEqualTo(id).findFirst();
    if (entity != null) {
      entity.syncState = SyncState.synced;
      await _isar.writeTxn(() async {
        await _isar.matchCommentEntitys.put(entity);
      });
    }
  }
}