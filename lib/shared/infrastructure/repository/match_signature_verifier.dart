import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

class TamperedEventException implements Exception {
  final String message;
  TamperedEventException(this.message);
  @override
  String toString() => 'TamperedEventException: $message';
}

class MatchSignatureVerifier {
  final Set<String> _verifiedSignatureKeys;

  MatchSignatureVerifier(this._verifiedSignatureKeys);

  bool verify(MatchModel match, {bool allowQuarantine = false}) {
    bool hasTampered = false;
    for (final event in match.events) {
      final key = '${event.id}_${event.signature}';
      if (_verifiedSignatureKeys.contains(key)) continue;

      if (!ScoreEventLegacyAdapter.verifySignature(
        event,
        'kendo_os_secret_key_v1',
      )) {
        if (!allowQuarantine) {
          throw TamperedEventException(
            'イベント(ID: ${event.id})の署名が無効、または改ざんされています。',
          );
        }
        hasTampered = true;
        debugPrint(
          '🛡️ [Quarantine SafeMode] イベント(ID: ${event.id})の署名不一致を検知。隔離退避します。',
        );
        continue;
      }
      if (_verifiedSignatureKeys.length > 5000) _verifiedSignatureKeys.clear();
      _verifiedSignatureKeys.add(key);
    }
    return hasTampered;
  }
}
