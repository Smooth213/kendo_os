import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('🛡️ SyncCrdtMerger Unit Tests', () {
    test('1. sanitizeForSync converts types and keys properly', () {
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

    test('2. mergeAndRebuild orders events by logicalClock and timestamp', () {
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
  });
}
