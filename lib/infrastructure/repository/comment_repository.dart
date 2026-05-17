import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/match_comment_model.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(FirebaseFirestore.instance);
});

class CommentRepository {
  final FirebaseFirestore _firestore;

  CommentRepository(this._firestore);

  Stream<List<MatchCommentModel>> watchComments(String tournamentId) {
    return _firestore
        .collection('comments')
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchCommentModel.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<void> saveComment(MatchCommentModel comment) async {
    await _firestore.collection('comments').doc(comment.id).set(comment.toJson()..remove('id'));
  }
}