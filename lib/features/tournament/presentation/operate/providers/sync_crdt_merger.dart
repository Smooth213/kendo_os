import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

/// CRDT差分追記マージ・データサニタイズヘルパー
class SyncCrdtMerger {
  static Map<String, dynamic> sanitizeForSync(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        result[key] = sanitizeForSync(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[key] = value.map((e) {
          if (e is Map) {
            return sanitizeForSync(Map<String, dynamic>.from(e));
          }
          if (e is Timestamp) {
            return e.toDate().toIso8601String();
          }
          return e;
        }).toList();
      } else if ((key == 'order' ||
              key == 'matchTimeMinutes' ||
              key == 'extensionTimeMinutes' ||
              key == 'enchoTimeMinutes') &&
          value is num) {
        result[key] = value.toDouble();
      } else if ((key == 'redScore' ||
              key == 'whiteScore' ||
              key == 'matchOrder') &&
          value is num) {
        result[key] = value.toInt();
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  static MatchModel mergeAndRebuild({
    required MatchModel remoteMatch,
    required MatchModel localMatch,
    required MatchRule rule,
    required RebuildMatchFromEventsUseCase rebuilder,
  }) {
    final Map<String, ScoreEvent> mergedEventsMap = {};
    for (var e in remoteMatch.events) {
      mergedEventsMap[e.id] = e;
    }
    for (var e in localMatch.pendingEvents) {
      mergedEventsMap[e.id] = e;
    }

    final mergedEvents = mergedEventsMap.values.toList()
      ..sort((a, b) {
        if (a.logicalClock != b.logicalClock) {
          return a.logicalClock.compareTo(b.logicalClock);
        }
        return a.timestamp.compareTo(b.timestamp);
      });

    MatchModel rebuiltMatch = remoteMatch.copyWith(
      events: mergedEvents,
      timerStartedAt: localMatch.timerStartedAt,
      timerPausedAt: localMatch.timerPausedAt,
      accumulatedPauseDurationMs: localMatch.accumulatedPauseDurationMs,
      status: localMatch.status,
    );

    try {
      final savedStatus = rebuiltMatch.status;
      rebuiltMatch = rebuilder.execute(rebuiltMatch, rule);
      rebuiltMatch = rebuiltMatch.copyWith(status: savedStatus);
    } catch (_) {}

    return rebuiltMatch;
  }
}
