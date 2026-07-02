import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  return CommentRepository(FirebaseFirestore.instance, dojoId);
});

class CommentRepository {
  final FirebaseFirestore _firestore;
  final String _dojoId;

  CommentRepository(this._firestore, this._dojoId);

  CollectionReference<Map<String, dynamic>> _commentsCollection(
    String tournamentId,
  ) {
    final dojo = _dojoId.isNotEmpty ? _dojoId : 'default_org';
    return _firestore
        .collection('organizations')
        .doc(dojo)
        .collection('tournaments')
        .doc(tournamentId.isNotEmpty ? tournamentId : 'default_tournament')
        .collection('comments');
  }

  Stream<List<MatchCommentModel>> watchComments(String tournamentId) {
    return _commentsCollection(tournamentId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => MatchCommentModel.fromJson(doc.data()..['id'] = doc.id))
          .toList(),
    );
  }

  Future<void> saveComment(MatchCommentModel comment) async {
    final tId = comment.tournamentId ?? 'default_tournament';
    await _commentsCollection(
      tId,
    ).doc(comment.id).set(comment.toJson()..remove('id'));
  }

  Future<void> deleteComment(String tournamentId, String commentId) async {
    await _commentsCollection(tournamentId).doc(commentId).delete();
  }
}
