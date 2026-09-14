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

    // 🛡️ 【Plan 3 最適化】不可逆ガード: 確定ステータス(finished/approved)の巻き戻り防止
    final chosenStatus = resolveMonotonicStatus(
      localStatus: localMatch.status,
      remoteStatus: remoteMatch.status,
      preferLocal: preferLocal,
    );

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
      final finalStatus = resolveMonotonicStatus(
        localStatus: savedStatus,
        remoteStatus: rebuiltMatch.status,
        preferLocal: true,
      );
      rebuiltMatch = rebuiltMatch.copyWith(status: finalStatus);
    } catch (_) {}

    return rebuiltMatch;
  }

  /// 🛡️ 【Plan 3 最適化】ステータスの単調増加調停（不可逆ガード）
  /// 試合終了（finished/approved/completed）が未送信イベント等によって進行中（in_progress等）へ巻き戻るのを物理的に防止する
  static String resolveMonotonicStatus({
    required String localStatus,
    required String remoteStatus,
    required bool preferLocal,
  }) {
    int getStatusRank(String status) {
      switch (status) {
        case 'approved':
          return 4;
        case 'finished':
        case 'completed':
        case 'fusen':
        case 'canceled':
          return 3;
        case 'in_progress':
        case 'paused':
        case 'encho':
        case 'hantei_pending':
          return 2;
        case 'ready':
        case 'waiting':
        case 'not_started':
        default:
          return 1;
      }
    }

    final localRank = getStatusRank(localStatus);
    final remoteRank = getStatusRank(remoteStatus);

    // 一方が完了系(ランク>=3)で他方が進行中・未開始(ランク<3)の場合、必ず完了系を維持
    if (remoteRank >= 3 && localRank < 3) {
      return remoteStatus;
    }
    if (localRank >= 3 && remoteRank < 3) {
      return localStatus;
    }

    // 双方のランクが同等、またはどちらも完了系の場合（approved > finished など）
    if (localRank != remoteRank) {
      return localRank > remoteRank ? localStatus : remoteStatus;
    }

    // ランクが完全一致の場合は preferLocal による調停
    return preferLocal ? localStatus : remoteStatus;
  }
}
