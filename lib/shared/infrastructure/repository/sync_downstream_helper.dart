import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_data_sanitizer.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

/// FirestoreからIsarへのダウンストリーム同期ヘルパー
class SyncDownstreamHelper {
  static Future<void> syncBunaiksenDocToIsar({
    required DocumentSnapshot<Map<String, dynamic>> snapshot,
    required LocalMatchRepository localRepo,
    required String tournamentId,
  }) async {
    try {
      final data = snapshot.data();
      if (data == null) return;

      // ドキュメント内に直接 'matches' リストが含まれている場合の安全同期フォールバック
      if (data.containsKey('matches') && data['matches'] is List) {
        final matchesList = data['matches'] as List;
        final matches = <MatchModel>[];
        for (final item in matchesList) {
          if (item is Map<String, dynamic>) {
            try {
              final sanitized = MatchDataSanitizer.sanitizeFirestoreData(item);
              final id =
                  sanitized['id']?.toString() ??
                  'bunaiksen_match_${DateTime.now().millisecondsSinceEpoch}';
              final rawMatch = MatchModel.fromJson({...sanitized, 'id': id});
              final match = MatchDataSanitizer.healRepresentativeMatch(
                rawMatch,
              );
              matches.add(match);
            } catch (e) {
              debugPrint(
                '⚠️ [Sync Engine Downstream] bunaiksen doc inner match parse error: $e',
              );
            }
          }
        }

        if (matches.isNotEmpty) {
          final healedMatches = matches
              .map(MatchDataSanitizer.healMatchSignatures)
              .toList();
          await applyRemoteMatches(
            localRepo: localRepo,
            remoteMatches: healedMatches,
            tournamentId: tournamentId,
          );
          debugPrint(
            '⚡ [Sync Engine Downstream] bunaiksenドキュメント直下のリストから ${healedMatches.length} 件の試合データをIsarに同期しました。',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '🔥 [Sync Engine Downstream Critical] bunaiksenドキュメント同期中にエラーが発生しました: $e',
      );
    }
  }

  static Future<void> syncFirestoreToIsar({
    required QuerySnapshot<Map<String, dynamic>> snapshot,
    required LocalMatchRepository localRepo,
    required String tournamentId,
  }) async {
    try {
      final matches = <MatchModel>[];
      final removedIds = <String>{};
      var parseFailed = false;
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          removedIds.add(change.doc.id);
          continue;
        }
        final doc = change.doc;
        try {
          final data = doc.data();
          if (data == null) {
            parseFailed = true;
            continue;
          }
          final sanitized = MatchDataSanitizer.sanitizeFirestoreData(data);
          final rawMatch = MatchModel.fromJson({...sanitized, 'id': doc.id});
          final match = MatchDataSanitizer.healRepresentativeMatch(rawMatch);
          matches.add(match);
        } catch (e) {
          parseFailed = true;
          debugPrint(
            '⚠️ [Sync Engine Downstream] Match parsing failed for doc ${doc.id}: $e',
          );
        }
      }

      final healedMatches = matches
          .map(MatchDataSanitizer.healMatchSignatures)
          .toList();
      await applyRemoteMatches(
        localRepo: localRepo,
        remoteMatches: healedMatches,
        tournamentId: tournamentId,
        removedIds: parseFailed ? const <String>{} : removedIds,
      );
      if (healedMatches.isNotEmpty) {
        debugPrint(
          '⚡ [Sync Engine Downstream] Firestoreから ${healedMatches.length} 件の試合データをIsarに同期しました。',
        );
      }
    } catch (e) {
      debugPrint(
        '🔥 [Sync Engine Downstream Critical] Isarへのバルクインサート中にエラーが発生しました: $e',
      );
    }
  }

  static Future<void> applyRemoteMatches({
    required LocalMatchRepository localRepo,
    required List<MatchModel> remoteMatches,
    required String tournamentId,
    Set<String> removedIds = const <String>{},
  }) async {
    final localMatches = await localRepo.watchAllLocalMatches().first;
    final localById = {for (final match in localMatches) match.id: match};
    final safeMatches = remoteMatches.where((remote) {
      final local = localById[remote.id];
      return local == null || !local.isDirty;
    }).toList();

    if (safeMatches.isNotEmpty) {
      await localRepo.saveMatchesBulk(safeMatches);
    }

    if (removedIds.isEmpty) return;
    for (final local in localMatches) {
      if (removedIds.contains(local.id) &&
          (tournamentId.isEmpty || local.tournamentId == tournamentId) &&
          !local.isDirty) {
        await localRepo.deleteMatch(local.id);
      }
    }
  }
}
