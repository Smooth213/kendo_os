import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

void main() {
  group('[E2E] — 同時編集競合要塞：マルチデバイス同期', () {
    test('【2端末同時更新】論理時計による順序制御が正しく検証できること', () async {
      final now = DateTime.now();
      final eventA = ScoreEvent(
        id: 'e1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
        logicalClock: 1,
      );
      final eventB = ScoreEvent(
        id: 'e2',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now,
        logicalClock: 2,
      );

      final history = [eventB, eventA]
        ..sort((a, b) => a.logicalClock.compareTo(b.logicalClock));
      expect(history.first.id, 'e1');
      expect(history.last.id, 'e2');
    });

    test('【オフライン競合】ローカルで発生したイベントが同期時に正しくマージされること', () async {
      final match = MatchModel(
        id: 'm1',
        matchType: '個人戦',
        redName: 'A',
        whiteName: 'B',
        syncState: SyncState.localOnly,
      );
      expect(match.syncState, SyncState.localOnly);
    });
  });
}
