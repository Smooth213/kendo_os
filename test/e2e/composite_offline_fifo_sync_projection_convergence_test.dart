import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/application/projections/timeline_projection.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';
import 'package:kendo_os/shared/sync/pending_sync_queue.dart';

class _E2ETimelineMatchItem implements TimelineItem {
  final MatchModel match;

  const _E2ETimelineMatchItem(this.match);

  @override
  String get timelineId => match.id;

  @override
  String? get tournamentId => match.tournamentId;

  @override
  double get timelineOrder => 10.0;

  @override
  TimelineItemType get itemType => TimelineItemType.match;

  @override
  String get rebuildHash =>
      'match_${match.id}_${match.events.length}_${match.status}';
}

class _E2ETimelineCommentItem implements TimelineItem {
  final String id;
  @override
  final String? tournamentId;
  @override
  final double timelineOrder;
  final String text;

  const _E2ETimelineCommentItem({
    required this.id,
    this.tournamentId,
    required this.timelineOrder,
    required this.text,
  });

  @override
  String get timelineId => id;

  @override
  TimelineItemType get itemType => TimelineItemType.comment;

  @override
  String get rebuildHash => 'comment_${id}_${text.hashCode}';
}

void main() {
  group('[E2E] 複合オフラインFIFO同期およびプロジェクション決定論的収束テスト', () {
    test('体育館断線下の連続入力が再接続時にFIFO順序で送信されプロジェクションハッシュが完全収束すること', () async {
      final queue = PendingSyncQueue<ScoreEvent>();
      final now = DateTime(2026, 10, 1, 14, 0, 0);

      // 1. 完全オフライン発生: 連続打突イベントの発生
      final event1 = ScoreEvent(
        id: 'ev_1_men',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
        sequence: 1,
        logicalClock: 1,
        userId: 'scorer_court_1',
      );
      final event2 = ScoreEvent(
        id: 'ev_2_kote',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 40)),
        sequence: 2,
        logicalClock: 2,
        userId: 'scorer_court_1',
      );
      final event3 = ScoreEvent(
        id: 'ev_3_do',
        side: Side.red,
        strikeType: StrikeType.dou,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 90)),
        sequence: 3,
        logicalClock: 3,
        userId: 'scorer_court_1',
      );

      // オフラインキューへFIFO蓄積
      queue.enqueue('sync_task_1', event1);
      queue.enqueue('sync_task_2', event2);
      queue.enqueue('sync_task_3', event3);

      expect(queue.pendingCount, equals(3));

      // 2. 電波復帰: 蓄積タスクの順序通りのフラッシュ送信シミュレーション
      final transmittedEvents = <ScoreEvent>[];
      while (!queue.isEmpty) {
        final task = queue.peek!;
        transmittedEvents.add(task.data);
        queue.dequeue();
      }

      expect(queue.isEmpty, isTrue);
      expect(transmittedEvents.length, equals(3));
      expect(transmittedEvents[0].id, equals('ev_1_men'));
      expect(transmittedEvents[1].id, equals('ev_2_kote'));
      expect(transmittedEvents[2].id, equals('ev_3_do'));

      // 3. 試合モデルの確定
      final finalizedMatch = MatchModel(
        id: 'match_court_1_final',
        tournamentId: 't_convergence',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        redScore: 2,
        whiteScore: 1,
        status: 'finished',
        events: transmittedEvents,
      );

      final matchItem = _E2ETimelineMatchItem(finalizedMatch);
      const commentItem = _E2ETimelineCommentItem(
        id: 'comm_announcement',
        tournamentId: 't_convergence',
        timelineOrder: 5.0,
        text: '第1コート 決勝戦終了',
      );

      // 4. クライアントAとクライアントBで受信順序が交錯した場合のプロジェクションハッシュ収束検証
      final clientAProjection = TimelineProjection(
        tournamentId: 't_convergence',
        items: [commentItem, matchItem],
        lastUpdatedAt: now,
      );

      final clientBProjection = TimelineProjection(
        tournamentId: 't_convergence',
        items: [matchItem, commentItem],
        lastUpdatedAt: now,
      );

      // 受信順序に関わらず決定論的ソートにより同一ハッシュに収束（Driftゼロ）
      expect(
        clientAProjection.rebuildHash,
        equals(clientBProjection.rebuildHash),
      );
      expect(
        clientAProjection.rebuildHash,
        contains('timeline|t_convergence|comment_comm_announcement'),
      );
    });
  });
}
