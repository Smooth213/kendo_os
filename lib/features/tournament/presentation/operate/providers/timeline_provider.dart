import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_comment_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';
import 'package:kendo_os/features/match/domain/events/comment_event.dart'; // ★ 修正: 一本化された events 側の正しいパスへ完全同期
import 'package:uuid/uuid.dart';
import 'package:kendo_os/shared/time/time_source.dart'; // ★ 追加

// ==========================================
// 1. Local Repository Provider
// ==========================================
final localCommentRepositoryProvider = Provider<LocalCommentRepository>((ref) {
  final isar = ref.watch(isarProvider);
  // ★ Webではisarがnullになりますが、LocalCommentRepository側で安全にスキップされるため例外を投げずに渡す
  return LocalCommentRepository(isar);
});

// ==========================================
// 2. コメントのストリーム監視 (Local DB)
// ==========================================
final commentStreamProvider =
    StreamProvider.family<List<MatchCommentModel>, String>((ref, tournamentId) {
      final repo = ref.watch(localCommentRepositoryProvider);
      return repo.watchComments(tournamentId);
    });

// ==========================================
// 3. コメント操作用の Command Service
// ==========================================
class CommentCommandService {
  final LocalCommentRepository _repo;
  final TimeSource _timeSource;
  final List<CommentEvent> _eventStore =
      []; // ★ Phase 4: Append-only Event Store

  CommentCommandService(this._repo, this._timeSource);

  Future<void> addComment({
    required String tournamentId,
    required String category,
    required String groupName,
    String? matchGroupId,
    required String text,
    required double order,
  }) async {
    final commentId = const Uuid().v4();
    final event = CommentEvent(
      id: const Uuid().v4(),
      commentId: commentId,
      type: CommentEventType.added,
      tournamentId: tournamentId,
      category: category,
      groupName: groupName,
      matchGroupId: matchGroupId,
      text: text,
      order: order,
      timestamp: _timeSource.now(),
      userId: 'system',
      logicalClock: _timeSource.now().millisecondsSinceEpoch,
    );

    _eventStore.add(event); // Append-only
    final comment = _rebuildSingle(commentId);
    if (comment != null) {
      await _repo.saveComment(comment);
    }
  }

  Future<void> updateCommentOrder(
    MatchCommentModel comment,
    double newOrder,
  ) async {
    final event = CommentEvent(
      id: const Uuid().v4(),
      commentId: comment.id,
      type: CommentEventType.updated,
      order: newOrder,
      timestamp: _timeSource.now(),
      userId: 'system',
      logicalClock: _timeSource.now().millisecondsSinceEpoch,
    );

    _eventStore.add(event);
    final updated = _rebuildSingle(comment.id);
    if (updated != null) {
      final withSync = updated.copyWith(syncState: SyncState.localOnly);
      await _repo.saveComment(withSync);
    }
  }

  Future<void> updateComment(MatchCommentModel comment) async {
    final event = CommentEvent(
      id: const Uuid().v4(),
      commentId: comment.id,
      type: CommentEventType.updated,
      text: comment.text,
      timestamp: _timeSource.now(),
      userId: 'system',
      logicalClock: _timeSource.now().millisecondsSinceEpoch,
    );

    _eventStore.add(event);
    final updated = _rebuildSingle(comment.id);
    if (updated != null) {
      final withSync = updated.copyWith(syncState: SyncState.localOnly);
      await _repo.saveComment(withSync);
    }
  }

  Future<void> deleteComment(String id) async {
    final event = CommentEvent(
      id: const Uuid().v4(),
      commentId: id,
      type: CommentEventType.deleted,
      timestamp: _timeSource.now(),
      userId: 'system',
      logicalClock: _timeSource.now().millisecondsSinceEpoch,
    );

    _eventStore.add(event);
    await _repo.deleteComment(id);
  }

  // ★ Phase 4: timeline replay rebuild
  MatchCommentModel? _rebuildSingle(String commentId) {
    final events = _eventStore.where((e) => e.commentId == commentId).toList();
    events.sort((a, b) => a.compareTo(b));

    MatchCommentModel? state;
    for (var e in events) {
      if (e.type == CommentEventType.added) {
        state = MatchCommentModel(
          id: e.commentId,
          tournamentId: e.tournamentId,
          category: e.category,
          groupName: e.groupName,
          matchGroupId: e.matchGroupId,
          text: e.text,
          order: e.order,
          lastUpdatedAt: e.timestamp,
        );
      } else if (e.type == CommentEventType.updated && state != null) {
        state = state.copyWith(
          text: e.text.isNotEmpty ? e.text : state.text,
          order: e.order != 0.0 ? e.order : state.order,
          lastUpdatedAt: e.timestamp,
        );
      } else if (e.type == CommentEventType.deleted) {
        state = null;
      }
    }
    return state;
  }
}

final commentCommandProvider = Provider<CommentCommandService>((ref) {
  return CommentCommandService(
    ref.watch(localCommentRepositoryProvider),
    ref.watch(timeSourceProvider), // ★ 追加
  );
});

// ==========================================
// 4. UIで並び替えるための統合ラッパーモデル
// ==========================================
abstract class ReorderableTimelineItem {
  String get id;
  double get order;
  String get rebuildHash;
}

class MatchGroupTimelineItem implements ReorderableTimelineItem {
  final String groupId;
  final List<MatchModel> matches;
  final List<MatchCommentModel> comments; // ★ 追加: グループ内のコメント

  MatchGroupTimelineItem(
    this.groupId,
    this.matches, [
    this.comments = const [],
  ]); // ★ 修正

  @override
  String get id => groupId;

  @override
  double get order {
    // ★ 修正: double.infinity がシステム外部や Projection（toInt()など）へ漏れ出すのを完全に防ぐ防壁を構築
    if (matches.isEmpty && comments.isEmpty) {
      return 0.0;
    }

    final mOrder = matches.isEmpty
        ? double.maxFinite
        : matches.fold<double>(
            double.maxFinite,
            (min, m) => m.order < min ? m.order : min,
          );

    final cOrder = comments.isEmpty
        ? double.maxFinite
        : comments.fold<double>(
            double.maxFinite,
            (min, c) => c.order < min ? c.order : min,
          );

    final minVal = mOrder < cOrder ? mOrder : cOrder;

    // システムの最大値を超えている、または infinity に近い場合は安全に 0.0 へフォールバック
    if (minVal >= double.maxFinite || minVal.isInfinite || minVal.isNaN) {
      return 0.0;
    }
    return minVal;
  }

  // ★ 追加: アコーディオン内部で混在描画するためのソート済み統合リスト
  List<TimelineItem> get sortedInnerItems {
    final list = <TimelineItem>[...matches, ...comments];
    list.sort((a, b) => a.timelineOrder.compareTo(b.timelineOrder));
    return list;
  }

  @override
  String get rebuildHash {
    final mHash = matches.map((m) => m.rebuildHash).join(',');
    final cHash = comments.map((c) => c.rebuildHash).join(',');
    return 'group|$groupId|$mHash|$cHash';
  }
}

class MatchIndividualTimelineItem implements ReorderableTimelineItem {
  final MatchModel match;
  MatchIndividualTimelineItem(this.match);

  @override
  String get id => match.id;

  @override
  double get order => match.order;

  @override
  String get rebuildHash => match.rebuildHash;
}

class CommentTimelineItem implements ReorderableTimelineItem {
  final MatchCommentModel comment;
  CommentTimelineItem(this.comment);

  @override
  String get id => comment.id;

  @override
  double get order => comment.order;

  @override
  String get rebuildHash => comment.rebuildHash;
}
