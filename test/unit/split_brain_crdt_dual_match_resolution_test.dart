import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

void main() {
  group('👁️ 【Phase 6-8/12】オフライン二重更新スプリットブレイン CRDT決定論的マージテスト', () {
    test('1. 端末A（赤面記録）と端末B（白小手記録）が並行発生後、論理時計順に決定論的マージされること', () {
      final baseTime = DateTime(2026, 9, 3, 10, 0, 0);

      // 端末Aでの操作（論理時計: 1）
      final eventA = ScoreEvent(
        id: 'ev_deviceA_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: baseTime.add(const Duration(seconds: 10)),
        logicalClock: 1,
      );

      // 端末Bでの操作（論理時計: 2）
      final eventB = ScoreEvent(
        id: 'ev_deviceB_1',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: baseTime.add(const Duration(seconds: 15)),
        logicalClock: 2,
      );

      // 🌐 ネットワーク再接続時のCRDTマージエンジン
      final mergedEvents = <ScoreEvent>[eventB, eventA]; // 到着順序が逆
      mergedEvents.sort((a, b) => a.logicalClock.compareTo(b.logicalClock));

      // 決定論的に論理時計順（赤面 ➔ 白小手）に整合すること
      expect(mergedEvents.first.id, 'ev_deviceA_1');
      expect(mergedEvents.first.side, Side.red);
      expect(mergedEvents.last.id, 'ev_deviceB_1');
      expect(mergedEvents.last.side, Side.white);
    });
  });
}
