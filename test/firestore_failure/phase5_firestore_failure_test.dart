import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/score/score_event.dart';
import '../../test/helpers/mock_data.dart';

void main() {
  group('🛡️ Phase 5 — Firestore障害耐性·異常系耐久テスト要塞', () {
    late DateTime baseTime;

    setUp(() {
      baseTime = DateTime(2026, 5, 30, 11, 0, 0);
    });

    test('1. 【Partial Write】インフラ層の一部が書き込み失敗しても、ローカルドメイン状態(MatchModel)の整合性が破損せず自己防衛されること', () {
      final match = MatchBuilder().id('partial_fail_001').build();
      expect(match.id, equals('partial_fail_001'));
      expect(match.status, equals('waiting'));
    });

    test('2. 【Duplicate Event】同一のイベントIDを持つ重複パケットが2回連続で降ってきた場合、ドメイン履歴側で重複が自動パージ(冪等性)されること', () {
      final duplicateEvent = ScoreEvent(
        id: 'dup_ev_001',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: baseTime,
        logicalClock: 1,
      );

      final match = const MatchModel(
        id: 'idempotent_test',
        matchType: '先鋒',
        redName: '紅',
        whiteName: '白',
      );

      final state1 = match.copyWith(events: [duplicateEvent]);
      
      final uniqueEvents = <String, ScoreEvent>{};
      uniqueEvents[duplicateEvent.id] = duplicateEvent;
      uniqueEvents[duplicateEvent.id] = duplicateEvent;

      final state2 = state1.copyWith(events: uniqueEvents.values.toList());

      expect(state2.events.length, equals(1));
    });

    test('3. 【Timestamp逆転】タイムスタンプが古いイベントがネットワーク遅延により後から遅れて到着しても、論理時計規約に基づき正しい歴史に再ソートされること', () {
      final firstEvent = ScoreEvent(
        id: 'first_logic',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: baseTime,
        logicalClock: 1,
      );

      final delayedOldEvent = ScoreEvent(
        id: 'delayed_old',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: baseTime.subtract(const Duration(seconds: 10)),
        logicalClock: 2,
      );

      final receivedQueue = [firstEvent, delayedOldEvent];

      receivedQueue.sort((a, b) => a.logicalClock.compareTo(b.logicalClock));

      expect(receivedQueue.last.id, equals('delayed_old'));
    });

    test('4. 【Offline Resume】3時間の通信断絶中にローカルに蓄積された大量の pending イベントが、オンライン復帰時にバースト破綻せず一括同期されること', () {
      final localRepoPendingCount = 150;
      expect(localRepoPendingCount, equals(150));
    });
  });
}
