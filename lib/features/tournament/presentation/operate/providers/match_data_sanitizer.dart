import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

/// Firestoreデータサニタイズ・代表戦ステータス修復・署名補正ヘルパー
class MatchDataSanitizer {
  static Map<String, dynamic> sanitizeFirestoreData(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        result[key] = sanitizeFirestoreData(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[key] = value.map((e) {
          if (e is Map) {
            return sanitizeFirestoreData(Map<String, dynamic>.from(e));
          }
          if (e is Timestamp) {
            return e.toDate().toIso8601String();
          }
          return e;
        }).toList();
      } else if ((key == 'order' ||
              key == 'timelineOrder' ||
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

  static MatchModel healRepresentativeMatch(MatchModel match) {
    if (match.matchType == '代表戦' && match.events.isEmpty) {
      if (match.status == 'finished' ||
          match.status == 'approved' ||
          match.status == 'corrupted') {
        debugPrint(
          '🛡️ [代表戦レギュレーション救済ガード] 不正ステート (${match.status}) を検知したため、status = waiting, timerStartedAt = null に強制クレンジング修復しました。 (Match ID: ${match.id})',
        );
        return match.copyWith(status: 'waiting', timerStartedAt: null);
      }
    }
    return match;
  }

  static ScoreEvent healSingleEvent(ScoreEvent event) {
    try {
      if (ScoreEventLegacyAdapter.verifySignature(
        event,
        'kendo_os_secret_key_v1',
      )) {
        return event;
      }
      final eventId = event.id.isNotEmpty ? event.id : const Uuid().v4();
      final uid = event.userId ?? 'unknown_user';
      final payload =
          '$eventId:$uid:${event.timestamp.toIso8601String()}:${event.side.name}:${event.type.name}';
      final signature = ScoreEventLegacyAdapter.generateSignature(
        payload,
        'kendo_os_secret_key_v1',
      );
      return event.copyWith(id: eventId, signature: signature);
    } catch (_) {
      final eventId = event.id.isNotEmpty ? event.id : const Uuid().v4();
      final uid = event.userId ?? 'unknown_user';
      final payload =
          '$eventId:$uid:${DateTime.now().toIso8601String()}:${event.side.name}:${event.type.name}';
      final signature = ScoreEventLegacyAdapter.generateSignature(
        payload,
        'kendo_os_secret_key_v1',
      );
      return event.copyWith(id: eventId, signature: signature);
    }
  }

  static MatchModel healMatchSignatures(MatchModel match) {
    try {
      final healedEvents = match.events.map(healSingleEvent).toList();
      final healedPendingEvents = match.pendingEvents
          .map(healSingleEvent)
          .toList();
      return match.copyWith(
        events: healedEvents,
        pendingEvents: healedPendingEvents,
      );
    } catch (_) {
      return match;
    }
  }
}
