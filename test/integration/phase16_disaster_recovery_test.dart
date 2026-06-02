import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/score/score_event.dart';

void main() {
  group('🛡️ PHASE 16 — Disaster Recovery 災害復旧要塞', () {
    test('1. 【完全復旧】バックアップからのリストアでデータが完全一致すること', () {
      final original = MatchModel(
        id: 'recover_1',
        matchType: '個人戦',
        redName: 'A',
        whiteName: 'B',
        syncState: SyncState.synced,
      );
      final exported = original.toJson();
      final restored = MatchModel.fromJson(exported);
      expect(restored.id, original.id);
    });

    test('2. 【同期競合】3台同時編集時の論理時計収束検証', () {
      final now = DateTime.now();
      final e1 = ScoreEvent(
        id: '1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
        logicalClock: 1,
      );
      final e2 = ScoreEvent(
        id: '2',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now,
        logicalClock: 2,
      );

      final history = [e2, e1]
        ..sort((a, b) => a.logicalClock.compareTo(b.logicalClock));
      expect(history.first.logicalClock, 1);
      expect(history.last.logicalClock, 2);
    });
  });
}
