import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/bunaiksen_infinite_engine_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🛡️ BunaiksenInfiniteEngine Score carry-over & Rotation Tests', () {
    test(
      'Verify that next generated match resets all events, scores, and timer states',
      () async {
        final container = ProviderContainer();

        // Initialize the queue with some players
        final queueNotifier = container.read(
          bunaiksenInfiniteQueueProvider.notifier,
        );
        queueNotifier.setPlayers(['選手C', '選手D']);

        final engine = container.read(bunaiksenInfiniteEngineProvider);

        // Create a finished match with scores, events, and timer state
        final finishedMatch = MatchModel(
          id: 'old_match_id',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
          matchType: '無限勝ち抜き',
          isKachinuki: true,
          events: [
            ScoreEvent(
              id: 'e1',
              strikeType: StrikeType.men,
              isIppon: true,
              side: Side.red,
              timestamp: DateTime.now(),
              sequence: 1,
            ),
            ScoreEvent(
              id: 'e2',
              strikeType: StrikeType.kote,
              isIppon: true,
              side: Side.white,
              timestamp: DateTime.now(),
              sequence: 2,
            ),
            ScoreEvent(
              id: 'e3',
              strikeType: StrikeType.men,
              isIppon: true,
              side: Side.red,
              timestamp: DateTime.now(),
              sequence: 3,
            ),
          ],
          snapshots: const [],
          accumulatedPauseDurationMs: 5000,
          timerStartedAt: DateTime.now(),
        );

        // Red wins
        final nextMatch = await engine.processMatchResult(finishedMatch, 'red');

        expect(nextMatch, isNotNull);
        // Verify players rotation: Red (選手A) wins and stays. White (選手B) is rotated out.
        // Next challenger is popped from queue ('選手C')
        expect(nextMatch!.redName, equals('選手A'));
        expect(nextMatch.whiteName, equals('選手C'));

        // Verify that all scores, events, snapshots, and timer states are completely reset
        expect(nextMatch.redScore, equals(0));
        expect(nextMatch.whiteScore, equals(0));
        expect(nextMatch.status, equals('waiting'));
        expect(nextMatch.events, isEmpty);
        expect(nextMatch.snapshots, isEmpty);
        expect(nextMatch.pendingEvents, isEmpty);
        expect(nextMatch.timerStartedAt, isNull);
        expect(nextMatch.timerPausedAt, isNull);
        expect(nextMatch.accumulatedPauseDurationMs, equals(0));

        // Verify streaks: 選手A streak should increment
        final streaks = container.read(bunaiksenInfiniteStreakProvider);
        expect(streaks['選手A'], equals(1));
        expect(streaks['選手B'] ?? 0, equals(0));
      },
    );

    test(
      'Verify that KendoRuleEngine does not evaluate an in-progress infinite kachinuki match as a tie',
      () {
        final engine = KendoRuleEngine();
        final rule = const MatchRule(
          matchTimeMinutes: 3,
          enchoTimeMinutes: 0,
          isEnchoUnlimited: false,
          isKachinuki: true,
        );

        // 1. Match is in progress (status: in_progress) at 0-0 score
        final inProgressMatch = MatchModel(
          id: 'test_match',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 0,
          whiteScore: 0,
          status: 'in_progress',
          matchType: '無限勝ち抜き',
          isKachinuki: true,
          redRemaining: const [],
          whiteRemaining: const [],
        );

        final inProgressStatus = engine.analyzeGroupStatus(
          currentMatch: inProgressMatch,
          groupMatches: [inProgressMatch],
          rule: rule,
        );

        // Should NOT be evaluated as a tie or finished
        expect(inProgressStatus.isAllDone, isFalse);
        expect(inProgressStatus.isTie, isFalse);

        // 2. Match is finished (status: finished) at 0-0 score
        final finishedMatch = inProgressMatch.copyWith(status: 'finished');
        final finishedStatus = engine.analyzeGroupStatus(
          currentMatch: finishedMatch,
          groupMatches: [finishedMatch],
          rule: rule,
        );

        // Should be evaluated as a finished tie/draw since scores are equal and no extensions remain
        expect(finishedStatus.isAllDone, isTrue);
        expect(finishedStatus.isTie, isTrue);
      },
    );

    test(
      'Verify queue restoration on return to list / break after win or draw',
      () async {
        // --- Scenario 1: Red Wins ---
        {
          final container = ProviderContainer();
          final queueNotifier = container.read(
            bunaiksenInfiniteQueueProvider.notifier,
          );
          queueNotifier.setPlayers(['Tanaka', 'Suzuki']);

          final engine = container.read(bunaiksenInfiniteEngineProvider);

          final finishedMatch = MatchModel(
            id: 'match_1',
            redName: 'Yamada',
            whiteName: 'Sato',
            redScore: 2,
            whiteScore: 1,
            status: 'finished',
            matchType: '無限勝ち抜き',
            isKachinuki: true,
          );

          // Process Yamada (Red) win
          final nextMatch = await engine.processMatchResult(
            finishedMatch,
            'red',
          );
          expect(nextMatch, isNotNull);
          expect(nextMatch!.redName, 'Yamada'); // winner
          expect(
            nextMatch.whiteName,
            'Tanaka',
          ); // next challenger popped from queue

          // Queue state right now is [Suzuki, Sato (loser)]
          expect(container.read(bunaiksenInfiniteQueueProvider), [
            'Suzuki',
            'Sato',
          ]);

          // Simulate "Return to List (Break)" logic
          final currentQueue = container.read(bunaiksenInfiniteQueueProvider);
          final filteredQueue = currentQueue
              .where((p) => p != nextMatch.redName && p != nextMatch.whiteName)
              .toList();
          queueNotifier.setPlayers([
            nextMatch.redName,
            nextMatch.whiteName,
            ...filteredQueue,
          ]);

          // Expected queue after break: Yamada (winner) at front, Tanaka (challenger) second, Suzuki third, Sato (loser) at end
          expect(container.read(bunaiksenInfiniteQueueProvider), [
            'Yamada',
            'Tanaka',
            'Suzuki',
            'Sato',
          ]);
        }

        // --- Scenario 2: Draw ---
        {
          final container = ProviderContainer();
          final queueNotifier = container.read(
            bunaiksenInfiniteQueueProvider.notifier,
          );
          queueNotifier.setPlayers(['Tanaka', 'Suzuki', 'Watanabe']);

          final engine = container.read(bunaiksenInfiniteEngineProvider);

          final finishedMatch = MatchModel(
            id: 'match_2',
            redName: 'Yamada',
            whiteName: 'Sato',
            redScore: 1,
            whiteScore: 1,
            status: 'finished',
            matchType: '無限勝ち抜き',
            isKachinuki: true,
          );

          // Process Draw
          final nextMatch = await engine.processMatchResult(
            finishedMatch,
            'draw',
          );
          expect(nextMatch, isNotNull);
          expect(nextMatch!.redName, 'Tanaka'); // first challenger popped
          expect(nextMatch.whiteName, 'Suzuki'); // second challenger popped

          // Queue state right now is [Watanabe, Yamada (loser1), Sato (loser2)]
          expect(container.read(bunaiksenInfiniteQueueProvider), [
            'Watanabe',
            'Yamada',
            'Sato',
          ]);

          // Simulate "Return to List (Break)" logic
          final currentQueue = container.read(bunaiksenInfiniteQueueProvider);
          final filteredQueue = currentQueue
              .where((p) => p != nextMatch.redName && p != nextMatch.whiteName)
              .toList();
          queueNotifier.setPlayers([
            nextMatch.redName,
            nextMatch.whiteName,
            ...filteredQueue,
          ]);

          // Expected queue after break: Tanaka & Suzuki (next challengers) at front, Watanabe, then Yamada & Sato (losers) at end
          expect(container.read(bunaiksenInfiniteQueueProvider), [
            'Tanaka',
            'Suzuki',
            'Watanabe',
            'Yamada',
            'Sato',
          ]);
        }
      },
    );
  });
}
