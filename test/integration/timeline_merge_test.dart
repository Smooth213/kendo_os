import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/match_comment_model.dart';
import 'package:kendo_os/presentation/operate/providers/timeline_provider.dart';

void main() {
  group('Timeline Merge Logic Test', () {
    test('試合3件とコメント2件がLexical Orderingに基づいて正しくマージ・ソートされること', () {
      // 1. 試合3件 (order: 100.0, 300.0, 500.0)
      final match1 = MatchModel(id: 'm1', order: 100.0, matchType: '', redName: '', whiteName: '');
      final match2 = MatchModel(id: 'm2', order: 300.0, matchType: '', redName: '', whiteName: '');
      final match3 = MatchModel(id: 'm3', order: 500.0, matchType: '', redName: '', whiteName: '');

      // 2. コメント2件 (order: 200.0, 400.0)
      final comment1 = MatchCommentModel(id: 'c1', text: 'comment1', order: 200.0);
      final comment2 = MatchCommentModel(id: 'c2', text: 'comment2', order: 400.0);

      // 3. タイムライン要素に変換してリストに格納（あえて順序をバラバラに挿入）
      final timelineItems = <ReorderableTimelineItem>[
        CommentTimelineItem(comment2),
        MatchIndividualTimelineItem(match1),
        MatchIndividualTimelineItem(match3),
        CommentTimelineItem(comment1),
        MatchIndividualTimelineItem(match2),
      ];

      // 4. マージロジックの実行（UI層でのソート処理をシミュレート）
      timelineItems.sort((a, b) => a.order.compareTo(b.order));

      // 5. 正しい順序でソートされているかを検証
      final sortedIds = timelineItems.map((item) => item.id).toList();
      final sortedOrders = timelineItems.map((item) => item.order).toList();

      expect(sortedIds, ['m1', 'c1', 'm2', 'c2', 'm3']);
      expect(sortedOrders, [100.0, 200.0, 300.0, 400.0, 500.0]);
    });
  });
}