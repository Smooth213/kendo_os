import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/services/match_snapshot_helper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

void main() {
  group('🛡️ MatchSnapshotHelper Unit Tests', () {
    const helper = MatchSnapshotHelper();

    test(
      '1. addSnapshotToMatch adds a snapshot to match with correct version and reason',
      () {
        final initialMatch = MatchModel(
          id: 'match-1',
          tournamentId: 'tour-1',
          matchOrder: 1,
          matchType: '先鋒',
          status: 'in_progress',
          redName: '選手A',
          whiteName: '選手B',
          events: [
            ScoreEvent(
              id: 'e1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: DateTime.now(),
              sequence: 1,
            ),
          ],
        );

        final updatedMatch = helper.addSnapshotToMatch(
          initialMatch,
          'テストスナップショット',
        );

        expect(updatedMatch.snapshots.length, 1);
        final snapshot = updatedMatch.snapshots.first;
        expect(snapshot.matchId, 'match-1');
        expect(snapshot.reason, 'テストスナップショット');
        expect(snapshot.version, 1);
        expect(snapshot.events.length, 1);
      },
    );

    test(
      '2. addSnapshotToMatch caps snapshots at 1 item by default (sliding window for light memory/DB footprint)',
      () {
        var currentMatch = MatchModel(
          id: 'match-1',
          tournamentId: 'tour-1',
          matchOrder: 1,
          matchType: '先鋒',
          status: 'in_progress',
          redName: '選手A',
          whiteName: '選手B',
        );

        for (int i = 1; i <= 25; i++) {
          currentMatch = helper.addSnapshotToMatch(
            currentMatch,
            'Snapshot #$i',
          );
        }

        // 上限1件に制限されていること（直前Undo用）
        expect(currentMatch.snapshots.length, 1);
        // 最新の25件目のみが保持されていること
        expect(currentMatch.snapshots.first.reason, 'Snapshot #25');
      },
    );

    test(
      '3. addSnapshotToMatch supports configurable maxSnapshots parameter',
      () {
        const customHelper = MatchSnapshotHelper(maxSnapshots: 5);
        var currentMatch = MatchModel(
          id: 'match-1',
          tournamentId: 'tour-1',
          matchOrder: 1,
          matchType: '先鋒',
          status: 'in_progress',
          redName: '選手A',
          whiteName: '選手B',
        );

        for (int i = 1; i <= 10; i++) {
          currentMatch = customHelper.addSnapshotToMatch(
            currentMatch,
            'Snapshot #$i',
          );
        }

        expect(currentMatch.snapshots.length, 5);
        expect(currentMatch.snapshots.first.reason, 'Snapshot #6');
        expect(currentMatch.snapshots.last.reason, 'Snapshot #10');
      },
    );
  });
}
