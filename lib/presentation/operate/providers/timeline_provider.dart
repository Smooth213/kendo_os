import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_comment_model.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/infrastructure/repository/local_comment_repository.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/domain/entities/timeline_item.dart';
import 'package:uuid/uuid.dart';

// ==========================================
// 1. Local Repository Provider
// ==========================================
final localCommentRepositoryProvider = Provider<LocalCommentRepository>((ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) throw Exception('Isar is not initialized (Web mode does not support local comments yet)');
  return LocalCommentRepository(isar);
});

// ==========================================
// 2. コメントのストリーム監視 (Local DB)
// ==========================================
final commentStreamProvider = StreamProvider.family<List<MatchCommentModel>, String>((ref, tournamentId) {
  final repo = ref.watch(localCommentRepositoryProvider);
  return repo.watchComments(tournamentId);
});

// ==========================================
// 3. コメント操作用の Command Service
// ==========================================
class CommentCommandService {
  final LocalCommentRepository _repo;
  CommentCommandService(this._repo);

  Future<void> addComment({
    required String tournamentId,
    required String category,
    required String groupName, // 所属先のチーム名など
    String? matchGroupId, // ★ 追加: アコーディオン内部に属する場合のグループID
    required String text,
    required double order,
  }) async {
    final comment = MatchCommentModel(
      id: const Uuid().v4(),
      tournamentId: tournamentId,
      category: category,
      groupName: groupName,
      matchGroupId: matchGroupId, // ★ 追加
      text: text,
      order: order,
    );
    await _repo.saveComment(comment);
  }

  Future<void> updateCommentOrder(MatchCommentModel comment, double newOrder) async {
    final updated = comment.copyWith(
      order: newOrder, 
      syncState: SyncState.localOnly, 
      lastUpdatedAt: DateTime.now()
    );
    await _repo.saveComment(updated);
  }

  Future<void> updateComment(MatchCommentModel comment) async {
    final updated = comment.copyWith(
      syncState: SyncState.localOnly, 
      lastUpdatedAt: DateTime.now()
    );
    await _repo.saveComment(updated);
  }

  Future<void> deleteComment(String id) async {
    // LocalCommentRepository側にdeleteCommentメソッドがある前提
    await _repo.deleteComment(id);
  }
}

final commentCommandProvider = Provider<CommentCommandService>((ref) {
  return CommentCommandService(ref.watch(localCommentRepositoryProvider));
});

// ==========================================
// 4. UIで並び替えるための統合ラッパーモデル
// ==========================================
abstract class ReorderableTimelineItem {
  String get id;
  double get order;
}

class MatchGroupTimelineItem implements ReorderableTimelineItem {
  final String groupId;
  final List<MatchModel> matches;
  final List<MatchCommentModel> comments; // ★ 追加: グループ内のコメント

  MatchGroupTimelineItem(this.groupId, this.matches, [this.comments = const []]); // ★ 修正

  @override
  String get id => groupId;

  @override
  double get order {

    final mOrder = matches.fold<double>(double.infinity, (min, m) => m.order < min ? m.order : min);
    final cOrder = comments.fold<double>(double.infinity, (min, c) => c.order < min ? c.order : min);
    final minVal = mOrder < cOrder ? mOrder : cOrder;
    return minVal == double.infinity ? 0.0 : minVal;
  }

  // ★ 追加: アコーディオン内部で混在描画するためのソート済み統合リスト
  List<TimelineItem> get sortedInnerItems {
    final list = <TimelineItem>[...matches, ...comments];
    list.sort((a, b) => a.timelineOrder.compareTo(b.timelineOrder));
    return list;
  }
}

class MatchIndividualTimelineItem implements ReorderableTimelineItem {
  final MatchModel match;
  MatchIndividualTimelineItem(this.match);

  @override
  String get id => match.id;

  @override
  double get order => match.order;
}

class CommentTimelineItem implements ReorderableTimelineItem {
  final MatchCommentModel comment;
  CommentTimelineItem(this.comment);

  @override
  String get id => comment.id;

  @override
  double get order => comment.order;
}
