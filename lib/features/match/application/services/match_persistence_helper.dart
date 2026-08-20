import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

/// 🥋 試合データの安全な取得（ローカル・メモリ・Web直接Firestore）および保存リトライヘルパー
class MatchPersistenceHelper {
  final Ref _ref;

  MatchPersistenceHelper(this._ref);

  // =========================================================================
  // 🛡️ Webアプリ・セーフガード (キャッシュ消失・ブラウザ再読み込み時の復旧)
  // =========================================================================
  Future<MatchModel?> getMatchSafely(String matchId) async {
    final localRepo = _ref.read(localMatchRepositoryProvider);
    MatchModel? match;
    try {
      match = await localRepo.getMatch(matchId);
    } catch (_) {}

    match ??= _ref
        .read(matchListProvider)
        .where((m) => m.id == matchId)
        .firstOrNull;

    if (match == null && kIsWeb) {
      try {
        final dojoId = _ref.read(currentDojoIdProvider);
        final tournamentId = _ref.read(currentTournamentIdProvider);
        final dojo = dojoId.isNotEmpty ? dojoId : 'default_org';
        final tournament = tournamentId.isNotEmpty
            ? tournamentId
            : 'default_tournament';

        final docSnapshot = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(dojo)
            .collection('tournaments')
            .doc(tournament)
            .collection('matches')
            .doc(matchId)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          data['id'] = docSnapshot.id;

          // Timestamp の安全な再帰的変換
          void safeConvertTimestamps(dynamic obj) {
            if (obj is Map) {
              for (var key in obj.keys.toList()) {
                final value = obj[key];
                if (value == null) continue;
                if (value.runtimeType.toString() == 'Timestamp') {
                  obj[key] = (value as Timestamp).toDate().toIso8601String();
                } else {
                  safeConvertTimestamps(value);
                }
              }
            } else if (obj is List) {
              for (int i = 0; i < obj.length; i++) {
                final value = obj[i];
                if (value == null) continue;
                if (value.runtimeType.toString() == 'Timestamp') {
                  obj[i] = (value as Timestamp).toDate().toIso8601String();
                } else {
                  safeConvertTimestamps(value);
                }
              }
            }
          }

          safeConvertTimestamps(data);
          match = MatchModel.fromJson(data);
          debugPrint(
            '🌐 [Web Sync] Firestoreから試合を復元成功: ${match.redName} vs ${match.whiteName}',
          );
        } else {
          debugPrint(
            '⚠️ [MatchPersistenceHelper] Firestoreに試合データが存在しません: $matchId',
          );
        }
      } catch (e, st) {
        debugPrint('⚠️ [MatchPersistenceHelper] Firestore直接取得エラー: $e\n$st');
      }
    }
    return match;
  }

  // =========================================================================
  // 🛡️ Webアプリ・保存リトライ防波堤 (1秒制限・一瞬の通信断の克服)
  // =========================================================================
  Future<int> saveToFirestoreWithRetry(
    MatchModel match, {
    int maxAttempts = 3,
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final newVersion = await _ref
            .read(matchRepositoryProvider)
            .saveMatch(match);
        return newVersion;
      } catch (e) {
        if (attempt == maxAttempts) {
          rethrow;
        }
        final delayMs = 500 * attempt;
        debugPrint(
          '⚠️ [MatchPersistenceHelper] Firestore保存をリトライします ($attempt/$maxAttempts) ${delayMs}ms後: $e',
        );
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    throw Exception('Firestore保存エラー: リトライ上限に達しました');
  }
}
