import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

/// CRDT差分追記マージ・データサニタイズヘルパー
class SyncCrdtMerger {
  /// 🏎️ 【Phase 11】AOTインライン化: 通信ペイロードのサニタイズ処理
  @pragma('vm:prefer-inline')
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

  /// 🏎️ 【Phase 11 & Plan 3-③】AOTインライン化: 3者イベント履歴CRDTマージ ＆ LWWタイマー調停
  @pragma('vm:prefer-inline')
  static MatchModel mergeAndRebuild({
    required MatchModel remoteMatch,
    required MatchModel localMatch,
    required MatchRule rule,
    required RebuildMatchFromEventsUseCase rebuilder,
  }) {
    final Map<String, ScoreEvent> mergedEventsMap = {};
    // 1. リモート確定イベント
    for (var e in remoteMatch.events) {
      mergedEventsMap[e.id] = e;
    }
    // 2. ローカル確定イベント (万が一クラウド未達の確定イベントの消失防止)
    for (var e in localMatch.events) {
      final existing = mergedEventsMap[e.id];
      if (existing == null || e.logicalClock >= existing.logicalClock) {
        mergedEventsMap[e.id] = e;
      }
    }
    // 3. ローカル未送信イベント
    for (var e in localMatch.pendingEvents) {
      final existing = mergedEventsMap[e.id];
      if (existing == null || e.logicalClock >= existing.logicalClock) {
        mergedEventsMap[e.id] = e;
      }
    }

    final mergedEvents = mergedEventsMap.values.toList()
      ..sort((a, b) {
        if (a.logicalClock != b.logicalClock) {
          return a.logicalClock.compareTo(b.logicalClock);
        }
        return a.timestamp.compareTo(b.timestamp);
      });

    // タイマーおよびステータスの Last-Write-Wins (LWW) 調停
    final bool preferLocal;
    if (localMatch.pendingEvents.isNotEmpty) {
      preferLocal = true;
    } else if (localMatch.lastUpdatedAt != null &&
        remoteMatch.lastUpdatedAt != null) {
      preferLocal = !remoteMatch.lastUpdatedAt!.isAfter(
        localMatch.lastUpdatedAt!,
      );
    } else if (localMatch.lastUpdatedAt != null) {
      preferLocal = true;
    } else if (remoteMatch.lastUpdatedAt != null) {
      preferLocal = false;
    } else {
      preferLocal = true;
    }

    final chosenTimerStartedAt = preferLocal
        ? localMatch.timerStartedAt
        : remoteMatch.timerStartedAt;
    final chosenTimerPausedAt = preferLocal
        ? localMatch.timerPausedAt
        : remoteMatch.timerPausedAt;
    final chosenAccPauseMs = preferLocal
        ? localMatch.accumulatedPauseDurationMs
        : remoteMatch.accumulatedPauseDurationMs;
    final chosenStatus = preferLocal ? localMatch.status : remoteMatch.status;

    MatchModel rebuiltMatch = remoteMatch.copyWith(
      events: mergedEvents,
      timerStartedAt: chosenTimerStartedAt,
      timerPausedAt: chosenTimerPausedAt,
      accumulatedPauseDurationMs: chosenAccPauseMs,
      status: chosenStatus,
    );

    try {
      final savedStatus = rebuiltMatch.status;
      rebuiltMatch = rebuilder.execute(rebuiltMatch, rule);
      rebuiltMatch = rebuiltMatch.copyWith(status: savedStatus);
    } catch (_) {}

    return rebuiltMatch;
  }
}
