import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/application/projections/timeline_projection.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';

class _MockTimelineItem implements TimelineItem {
  @override
  final String timelineId;
  @override
  String? get tournamentId => 't_unit_test';
  @override
  final double timelineOrder;
  @override
  final TimelineItemType itemType;
  @override
  final String rebuildHash;

  const _MockTimelineItem({
    required this.timelineId,
    required this.timelineOrder,
    required this.itemType,
    required this.rebuildHash,
  });
}

void main() {
  group('[Unit] タイムラインプロジェクション決定論的ハッシュおよびソート安定性テスト', () {
    test('空アイテムリストの場合に規定プレフィックスハッシュを返却すること', () {
      final now = DateTime(2026, 10, 1, 10, 0, 0);
      final projection = TimelineProjection(
        tournamentId: 'tournament_empty',
        items: const [],
        lastUpdatedAt: now,
      );

      expect(projection.rebuildHash, equals('timeline|tournament_empty|'));
    });

    test('異なる順序で挿入されたアイテム群から完全に同一のハッシュを導出すること', () {
      const item1 = _MockTimelineItem(
        timelineId: 'id_1',
        timelineOrder: 1.0,
        itemType: TimelineItemType.match,
        rebuildHash: 'hash_1',
      );
      const item2 = _MockTimelineItem(
        timelineId: 'id_2',
        timelineOrder: 2.0,
        itemType: TimelineItemType.comment,
        rebuildHash: 'hash_2',
      );
      const item3 = _MockTimelineItem(
        timelineId: 'id_3',
        timelineOrder: 3.0,
        itemType: TimelineItemType.match,
        rebuildHash: 'hash_3',
      );

      final now = DateTime(2026, 10, 1, 10, 0, 0);

      final p1 = TimelineProjection(
        tournamentId: 't1',
        items: [item1, item2, item3],
        lastUpdatedAt: now,
      );

      final p2 = TimelineProjection(
        tournamentId: 't1',
        items: [item3, item1, item2],
        lastUpdatedAt: now,
      );

      final p3 = TimelineProjection(
        tournamentId: 't1',
        items: [item2, item3, item1],
        lastUpdatedAt: now,
      );

      expect(p1.rebuildHash, equals(p2.rebuildHash));
      expect(p2.rebuildHash, equals(p3.rebuildHash));
      expect(p1.rebuildHash, equals('timeline|t1|hash_1,hash_2,hash_3'));
    });

    test('同一オーダー値を持つ要素間でハッシュ値による安定したタイブレークを実行すること', () {
      const itemA = _MockTimelineItem(
        timelineId: 'id_a',
        timelineOrder: 10.0,
        itemType: TimelineItemType.match,
        rebuildHash: 'alpha_hash',
      );
      const itemZ = _MockTimelineItem(
        timelineId: 'id_z',
        timelineOrder: 10.0,
        itemType: TimelineItemType.match,
        rebuildHash: 'zeta_hash',
      );

      final now = DateTime(2026, 10, 1, 10, 0, 0);

      final pForward = TimelineProjection(
        tournamentId: 't2',
        items: [itemA, itemZ],
        lastUpdatedAt: now,
      );

      final pReverse = TimelineProjection(
        tournamentId: 't2',
        items: [itemZ, itemA],
        lastUpdatedAt: now,
      );

      expect(pForward.rebuildHash, equals(pReverse.rebuildHash));
      expect(pForward.rebuildHash, equals('timeline|t2|alpha_hash,zeta_hash'));
    });
  });
}
