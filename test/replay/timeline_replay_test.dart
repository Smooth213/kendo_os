import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/events/comment_event.dart'; // ★ 修正: 一本化された events 側の正しいパスへ完全同期
import 'package:kendo_os/domain/entities/match_comment_model.dart';

void main() {
  group('Phase 4: Timeline Replay & Merge Conflict Test', () {
    test('Comment Event Append-Only & Deterministic Rebuild', () {
      final events = [
        CommentEvent(
          id: 'evt1',
          commentId: 'c1',
          type: CommentEventType.added,
          tournamentId: 't1',
          text: 'Initial Comment',
          order: 10.0,
          timestamp: DateTime(2026, 1, 1, 10, 0, 0),
          userId: 'user1',
          logicalClock: 1,
        ),
        CommentEvent(
          id: 'evt2',
          commentId: 'c1',
          type: CommentEventType.updated,
          text: 'Updated Comment',
          timestamp: DateTime(2026, 1, 1, 10, 5, 0),
          userId: 'user1',
          logicalClock: 2,
        ),
      ];

      MatchCommentModel? state;
      for (var e in events) {
        if (e.type == CommentEventType.added) {
          state = MatchCommentModel(
            id: e.commentId,
            tournamentId: e.tournamentId,
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
        }
      }

      expect(state, isNotNull);
      expect(state!.text, 'Updated Comment');
      expect(state.order, 10.0);
    });

    test('Timeline Merge Conflict Determinism', () {
      final evt1 = CommentEvent(
        id: 'evt1',
        commentId: 'c1',
        type: CommentEventType.added,
        timestamp: DateTime(2026, 1, 1, 10, 0, 0),
        userId: 'user1',
        logicalClock: 1,
      );
      final evt2 = CommentEvent(
        id: 'evt2',
        commentId: 'c1',
        type: CommentEventType.updated,
        text: 'Updated Comment',
        timestamp: DateTime(2026, 1, 1, 10, 5, 0),
        userId: 'user1',
        logicalClock: 2,
      );

      final events = [evt2, evt1];
      events.sort((a, b) => a.compareTo(b));

      expect(events.first.id, 'evt1');
      expect(events.last.id, 'evt2');
    });
  });
}
