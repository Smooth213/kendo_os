import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';

/// タイムトラベル（指定バージョンへの巻き戻し）専用サービス
class MatchRewindService {
  static MatchModel executeRewind({
    required MatchModel initialMatch,
    required int targetVersion,
    required User currentUser,
    required MatchRule rule,
    required AddScoreUseCase addScore,
  }) {
    final engine = KendoRuleEngine();
    final validEvents = engine.filterActiveEvents(initialMatch.events);

    if (validEvents.length <= targetVersion) return initialMatch;

    MatchModel processMatch = initialMatch.copyWith(status: 'in_progress');
    int undoCount = validEvents.length - targetVersion;

    final String syncSeed = DateTime.now().microsecondsSinceEpoch.toString();

    int maxClock = processMatch.events.isEmpty
        ? 0
        : processMatch.events
              .map((e) => e.logicalClock)
              .reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < undoCount; i++) {
      maxClock++;
      final undoEvent = ScoreEventLegacyAdapter.fromLegacy(
        id: 'rewind-${initialMatch.id}-$syncSeed-$i',
        side: Side.none,
        type: PointType.undo,
        timestamp: DateTime.now().add(Duration(milliseconds: i)),
        userId: currentUser.id,
        sequence: processMatch.events.isEmpty
            ? 1
            : processMatch.events.last.sequence + 1,
        logicalClock: maxClock,
      );

      processMatch = addScore.execute(
        currentUser,
        processMatch,
        undoEvent,
        rule,
      );
    }

    final analysis = engine.analyzeHistory(
      processMatch.events,
      processMatch,
      rule,
    );

    return processMatch.copyWith(
      status: 'in_progress',
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      syncState: SyncState.localOnly,
      lastUpdatedAt: DateTime.now(),
    );
  }
}
