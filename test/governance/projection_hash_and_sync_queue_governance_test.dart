import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/application/projections/timeline_projection.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';
import 'package:kendo_os/shared/sync/pending_sync_queue.dart';

class _FakeTimelineItem implements TimelineItem {
  @override
  final String timelineId;
  @override
  String? get tournamentId => 'tournament_gov_test';
  @override
  final double timelineOrder;
  @override
  final TimelineItemType itemType;
  @override
  final String rebuildHash;

  const _FakeTimelineItem({
    required this.timelineId,
    required this.timelineOrder,
    required this.itemType,
    required this.rebuildHash,
  });
}

void main() {
  group('[Governance] 分散プロジェクション決定論的ハッシュおよびFIFOキュー不変性保証規約', () {
    test('TimelineProjectionにおいてアイテムの入力順序が異なっても同一の決定論的ハッシュが生成されること', () {
      const itemA = _FakeTimelineItem(
        timelineId: 'item_1',
        timelineOrder: 1.0,
        itemType: TimelineItemType.match,
        rebuildHash: 'hash_order_1_item_1',
      );
      const itemB = _FakeTimelineItem(
        timelineId: 'item_2',
        timelineOrder: 2.0,
        itemType: TimelineItemType.comment,
        rebuildHash: 'hash_order_2_item_2',
      );
      const itemC = _FakeTimelineItem(
        timelineId: 'item_3',
        timelineOrder: 2.0,
        itemType: TimelineItemType.match,
        rebuildHash: 'hash_order_2_item_3_tiebreak',
      );

      final now = DateTime(2026, 10, 1, 12, 0, 0);

      final projection1 = TimelineProjection(
        tournamentId: 't_alpha',
        items: [itemA, itemB, itemC],
        lastUpdatedAt: now,
      );

      final projection2 = TimelineProjection(
        tournamentId: 't_alpha',
        items: [itemC, itemA, itemB],
        lastUpdatedAt: now,
      );

      final projection3 = TimelineProjection(
        tournamentId: 't_alpha',
        items: [itemB, itemC, itemA],
        lastUpdatedAt: now,
      );

      expect(projection1.rebuildHash, equals(projection2.rebuildHash));
      expect(projection2.rebuildHash, equals(projection3.rebuildHash));
      expect(
        projection1.rebuildHash,
        equals(
          'timeline|t_alpha|hash_order_1_item_1,hash_order_2_item_2,hash_order_2_item_3_tiebreak',
        ),
      );
    });

    test('PendingSyncQueueにおいてオフラインタスクがFIFO順序を崩さず厳格に保持されること', () {
      final queue = PendingSyncQueue<String>();

      expect(queue.isEmpty, isTrue);
      expect(queue.pendingCount, equals(0));
      expect(queue.peek, isNull);

      queue.enqueue('task_1', 'payload_1');
      queue.enqueue('task_2', 'payload_2');
      queue.enqueue('task_3', 'payload_3');

      expect(queue.isEmpty, isFalse);
      expect(queue.pendingCount, equals(3));

      // 1件目の確認と取り出し
      expect(queue.peek?.taskId, equals('task_1'));
      expect(queue.peek?.data, equals('payload_1'));
      queue.dequeue();

      // 2件目の確認と取り出し
      expect(queue.pendingCount, equals(2));
      expect(queue.peek?.taskId, equals('task_2'));
      expect(queue.peek?.data, equals('payload_2'));
      queue.dequeue();

      // 3件目の確認と取り出し
      expect(queue.pendingCount, equals(1));
      expect(queue.peek?.taskId, equals('task_3'));
      expect(queue.peek?.data, equals('payload_3'));
      queue.dequeue();

      expect(queue.isEmpty, isTrue);
      expect(queue.pendingCount, equals(0));
      expect(queue.peek, isNull);
    });
  });
}
