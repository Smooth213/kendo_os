import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/entities/match_comment_model.dart';
import 'package:kendo_os/domain/entities/timeline_item.dart';
import 'package:kendo_os/presentation/operate/providers/timeline_provider.dart';

void main() {
  group('MatchGroupTimelineItem Tests', () {
    test('order returns the minimum order of matches and comments', () {
      final match = const MatchModel(
        id: 'm1',
        matchType: '先鋒',
        redName: '赤',
        whiteName: '白',
        order: 10.0,
      );
      
      final comment1 = const MatchCommentModel(
        id: 'c1',
        text: 'コメント1',
        order: 20.0,
      );
      
      final comment2 = const MatchCommentModel(
        id: 'c2',
        text: 'コメント2',
        order: 5.0,
      );

      // コメントの方が最小orderの場合
      final item1 = MatchGroupTimelineItem('group1', [match], [comment1, comment2]);
      expect(item1.order, 5.0, reason: 'グループ全体のorderは、内包する要素の最小値を返すこと');

      // 試合の方が最小orderの場合
      final item2 = MatchGroupTimelineItem('group2', [match], [comment1]);
      expect(item2.order, 10.0, reason: '試合の方が値が小さければ、試合のorderを返すこと');
    });

    test('order returns 0.0 when both matches and comments are empty', () {
      final item = MatchGroupTimelineItem('group_empty', [], []);
      expect(item.order, 0.0, reason: '試合もコメントも無い場合は0.0を返すこと');
    });

    test('order works correctly when only comments or only matches exist', () {
      final match = const MatchModel(id: 'm1', matchType: '先鋒', redName: '赤', whiteName: '白', order: 15.0);
      final comment = const MatchCommentModel(id: 'c1', text: 'コメント', order: 25.0);

      final itemMatchesOnly = MatchGroupTimelineItem('group_m', [match], []);
      expect(itemMatchesOnly.order, 15.0, reason: '試合のみの場合は試合の最小orderを返すこと');

      final itemCommentsOnly = MatchGroupTimelineItem('group_c', [], [comment]);
      expect(itemCommentsOnly.order, 25.0, reason: 'コメントのみの場合はコメントの最小orderを返すこと');
    });

    test('sortedInnerItems returns a sorted list of matches and comments combined', () {
      final match1 = const MatchModel(
        id: 'm1',
        matchType: '先鋒',
        redName: '赤',
        whiteName: '白',
        order: 20.0,
      );
      
      final match2 = const MatchModel(
        id: 'm2',
        matchType: '次鋒',
        redName: '赤',
        whiteName: '白',
        order: 40.0,
      );

      final comment1 = const MatchCommentModel(id: 'c1', text: '試合開始前', order: 10.0);
      final comment2 = const MatchCommentModel(id: 'c2', text: '試合間のメモ', order: 30.0);

      final item = MatchGroupTimelineItem('group1', [match1, match2], [comment1, comment2]);
      final sortedItems = item.sortedInnerItems;
      
      // 10.0 (c1) -> 20.0 (m1) -> 30.0 (c2) -> 40.0 (m2) の順で異種混在ソートされているか
      expect(sortedItems.length, 4);
      expect(sortedItems[0].timelineId, 'c1');
      expect(sortedItems[0].itemType, TimelineItemType.comment);
      expect(sortedItems[1].timelineId, 'm1');
      expect(sortedItems[1].itemType, TimelineItemType.match);
      expect(sortedItems[2].timelineId, 'c2');
      expect(sortedItems[3].timelineId, 'm2');
    });
  });

  group('MatchCommentModel implements TimelineItem Tests', () {
    test('returns correct timeline properties', () {
      final comment = const MatchCommentModel(id: 'c123', text: 'テスト', order: 99.5);
      expect(comment.timelineId, 'c123');
      expect(comment.timelineOrder, 99.5);
      expect(comment.itemType, TimelineItemType.comment);
    });
  });
}