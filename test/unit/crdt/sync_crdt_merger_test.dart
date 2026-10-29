import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('[Unit] SyncCrdtMerger 単体テスト', () {
    test('sanitizeForSync converts types and keys properlyこと', () {
      final input = {
        'redScore': 2.0,
        'matchTimeMinutes': 3,
        'nested': {'whiteScore': 1.0},
      };

      final output = SyncCrdtMerger.sanitizeForSync(input);
      expect(output['redScore'], 2);
      expect(output['matchTimeMinutes'], 3.0);
      expect(output['nested']['whiteScore'], 1);
    });

    test('mergeAndRebuild 順序 events by logicalClock and timestampこと', () {
      final now = DateTime.now();
      final remoteMatch = MatchModel(
        id: 'm1',
        matchType: '個人戦',
        redName: '山田',
        whiteName: '佐藤',
        events: [
          ScoreEvent(
            id: 'e1',
            timestamp: now,
            logicalClock: 1,
            side: Side.red,
            strikeType: StrikeType.men,
          ),
        ],
      );

      final localMatch = MatchModel(
        id: 'm1',
        matchType: '個人戦',
        redName: '山田',
        whiteName: '佐藤',
        pendingEvents: [
          ScoreEvent(
            id: 'e2',
            timestamp: now.add(const Duration(seconds: 1)),
            logicalClock: 2,
            side: Side.white,
            strikeType: StrikeType.kote,
          ),
        ],
      );

      final merged = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: remoteMatch,
        localMatch: localMatch,
        rule: const MatchRule(),
        rebuilder: RebuildMatchFromEventsUseCase(
          KendoRuleEngine(),
          SystemTimeSource(),
        ),
      );

      expect(merged.events.length, 2);
      expect(merged.events.first.id, 'e1');
      expect(merged.events.last.id, 'e2');
    });

    test(
      'mergeAndRebuildAsyncにおいて Worker内で実行され正しくマージされた試合情報が返却されること',
      () async {
        final now = DateTime.now();
        final remoteMatch = MatchModel(
          id: 'm_async',
          matchType: '個人戦',
          redName: '山田',
          whiteName: '佐藤',
          events: [
            ScoreEvent(
              id: 'e_async_1',
              timestamp: now,
              logicalClock: 1,
              side: Side.red,
              strikeType: StrikeType.men,
            ),
          ],
        );

        final localMatch = MatchModel(
          id: 'm_async',
          matchType: '個人戦',
          redName: '山田',
          whiteName: '佐藤',
          pendingEvents: [
            ScoreEvent(
              id: 'e_async_2',
              timestamp: now.add(const Duration(seconds: 1)),
              logicalClock: 2,
              side: Side.white,
              strikeType: StrikeType.kote,
            ),
          ],
        );

        final merged = await SyncCrdtMerger.mergeAndRebuildAsync(
          remoteMatch: remoteMatch,
          localMatch: localMatch,
          rule: const MatchRule(),
        );

        expect(merged.events.length, 2);
        expect(merged.events.first.id, 'e_async_1');
        expect(merged.events.last.id, 'e_async_2');
      },
    );

    test('同一論理時計および同一時刻の競合イベントにおいて、ID決定論的タイブレーク順序により結果が一意に収束すること', () {
      final now = DateTime(2026, 10, 1, 10, 0, 0);
      final evB = ScoreEvent(
        id: 'ev_device_b',
        timestamp: now,
        logicalClock: 1,
        side: Side.white,
        strikeType: StrikeType.kote,
      );
      final evA = ScoreEvent(
        id: 'ev_device_a',
        timestamp: now,
        logicalClock: 1,
        side: Side.red,
        strikeType: StrikeType.men,
      );

      final rebuilder = RebuildMatchFromEventsUseCase(
        KendoRuleEngine(),
        SystemTimeSource(),
      );

      // パターン1: remoteMatchにevB, localMatchにevA
      final match1 = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          events: [evB],
        ),
        localMatch: MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          pendingEvents: [evA],
        ),
        rule: const MatchRule(),
        rebuilder: rebuilder,
      );

      // パターン2: remoteMatchにevA, localMatchにevB
      final match2 = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          events: [evA],
        ),
        localMatch: MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          pendingEvents: [evB],
        ),
        rule: const MatchRule(),
        rebuilder: rebuilder,
      );

      // どちらの順序でマージされても、IDによる決定論的タイブレークで同一順序(ev_device_a -> ev_device_b)になること
      expect(
        match1.events.map((e) => e.id).toList(),
        equals(['ev_device_a', 'ev_device_b']),
        reason: 'evBが先に入力されてもIDタイブレークでevAが先頭になること',
      );
      expect(
        match2.events.map((e) => e.id).toList(),
        equals(['ev_device_a', 'ev_device_b']),
        reason: 'evAが先に入力されてもIDタイブレークでevAが先頭になること',
      );
    });

    test('同一論理時計および同一時刻の競合イベントにおいて、ID決定論的タイブレーク順序により結果が一意に収束すること', () {
      final now = DateTime(2026, 10, 1, 10, 0, 0);
      final evB = ScoreEvent(
        id: 'ev_device_b',
        timestamp: now,
        logicalClock: 1,
        side: Side.white,
        strikeType: StrikeType.kote,
      );
      final evA = ScoreEvent(
        id: 'ev_device_a',
        timestamp: now,
        logicalClock: 1,
        side: Side.red,
        strikeType: StrikeType.men,
      );

      final rebuilder = RebuildMatchFromEventsUseCase(
        KendoRuleEngine(),
        SystemTimeSource(),
      );

      // パターン1: remoteMatchにevB, localMatchにevA
      final match1 = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          events: [evB],
        ),
        localMatch: MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          pendingEvents: [evA],
        ),
        rule: const MatchRule(),
        rebuilder: rebuilder,
      );

      // パターン2: remoteMatchにevA, localMatchにevB
      final match2 = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          events: [evA],
        ),
        localMatch: MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          pendingEvents: [evB],
        ),
        rule: const MatchRule(),
        rebuilder: rebuilder,
      );

      // どちらの順序でマージされても、IDによる決定論的タイブレークで同一順序(ev_device_a -> ev_device_b)になること
      expect(
        match1.events.map((e) => e.id).toList(),
        equals(['ev_device_a', 'ev_device_b']),
        reason: 'evBが先に入力されてもIDタイブレークでevAが先頭になること',
      );
      expect(
        match2.events.map((e) => e.id).toList(),
        equals(['ev_device_a', 'ev_device_b']),
        reason: 'evAが先に入力されてもIDタイブレークでevAが先頭になること',
      );
    });
  });
}
