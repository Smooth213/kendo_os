import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/isar_projection_store.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

/// 🥋 試合データの安全な取得（ローカル・メモリ・Web直接Firestore）および保存リトライ・永続化ヘルパー
class MatchPersistenceHelper {
  final Ref _ref;

  MatchPersistenceHelper(this._ref);

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

  Future<int> saveToFirestoreWithRetry(
    MatchModel match, {
    int maxAttempts = 3,
  }) async {
    final matchRepo = _ref.read(matchRepositoryProvider);
    int attempts = 0;
    while (attempts < maxAttempts) {
      attempts++;
      try {
        final version = await matchRepo.saveMatch(match);
        return version;
      } catch (e) {
        debugPrint('⚠️ [Save Retry] Attempt $attempts failed: $e');
        if (attempts >= maxAttempts) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempts));
      }
    }
    return 1;
  }

  Future<void> saveMatch(MatchModel match) async {
    final dojoId = _ref.read(currentDojoIdProvider);
    final matchWithId = match.id.isEmpty
        ? match.copyWith(id: const Uuid().v4())
        : match;
    final matchToSave = matchWithId.copyWith(
      organizationId:
          (matchWithId.organizationId == 'default_org' ||
              matchWithId.organizationId.isEmpty)
          ? dojoId
          : matchWithId.organizationId,
      syncState: SyncState.localOnly,
      lastUpdatedAt: DateTime.now(),
    );

    if (kIsWeb) {
      final webSafeMatch = matchToSave.copyWith(snapshots: const []);
      final currentMatches = _ref.read(webCurrentTournamentMatchesProvider);
      final index = currentMatches.indexWhere((m) => m.id == webSafeMatch.id);
      if (index != -1) {
        final newMatches = List<MatchModel>.from(currentMatches);
        newMatches[index] = webSafeMatch;
        _ref.read(webCurrentTournamentMatchesProvider.notifier).state =
            newMatches;
      } else {
        _ref.read(webCurrentTournamentMatchesProvider.notifier).state = [
          ...currentMatches,
          webSafeMatch,
        ];
      }

      final newVersion = await saveToFirestoreWithRetry(webSafeMatch);
      final finalMatches = _ref.read(webCurrentTournamentMatchesProvider);
      final fIndex = finalMatches.indexWhere((m) => m.id == webSafeMatch.id);
      if (fIndex != -1) {
        final newMatches = List<MatchModel>.from(finalMatches);
        newMatches[fIndex] = webSafeMatch.copyWith(version: newVersion);
        _ref.read(webCurrentTournamentMatchesProvider.notifier).state =
            newMatches;
      }
    } else {
      final localRepo = _ref.read(localMatchRepositoryProvider);
      await localRepo.saveMatch(matchToSave);

      bool isViewer = false;
      try {
        final currentUserAuth = FirebaseAuth.instance.currentUser;
        if (currentUserAuth != null && currentUserAuth.isAnonymous) {
          isViewer = true;
        }
      } catch (_) {}

      if (!isViewer) {
        final action = MatchCommandModel(
          id: const Uuid().v4(),
          type: CommandType.updateMatch,
          payload: matchToSave.toJson(),
          createdAt: DateTime.now(),
          status: CommandStatus.pending,
        );
        await localRepo.savePendingCommand(action);
      }

      _ref.read(syncEngineProvider).processQueue();
      _ref.invalidate(matchListProvider);
    }
  }

  Future<void> saveMatchesBulk(List<MatchModel> newMatches) async {
    if (newMatches.isEmpty) return;
    final dojoId = _ref.read(currentDojoIdProvider);

    final preparedMatches = newMatches.map((m) {
      final mWithId = m.id.isEmpty ? m.copyWith(id: const Uuid().v4()) : m;
      return mWithId.copyWith(
        organizationId:
            (mWithId.organizationId == 'default_org' ||
                mWithId.organizationId.isEmpty)
            ? dojoId
            : mWithId.organizationId,
        syncState: SyncState.localOnly,
        lastUpdatedAt: DateTime.now(),
      );
    }).toList();

    if (kIsWeb) {
      final webSafeMatches = preparedMatches
          .map((m) => m.copyWith(snapshots: const []))
          .toList();

      var currentMatches = _ref.read(webCurrentTournamentMatchesProvider);
      var newMatches = List<MatchModel>.from(currentMatches);
      for (final m in webSafeMatches) {
        final index = newMatches.indexWhere((em) => em.id == m.id);
        if (index != -1) {
          newMatches[index] = m;
        } else {
          newMatches.add(m);
        }
      }
      _ref.read(webCurrentTournamentMatchesProvider.notifier).state =
          newMatches;

      for (final m in webSafeMatches) {
        await saveToFirestoreWithRetry(m);
      }
    } else {
      final localRepo = _ref.read(localMatchRepositoryProvider);
      await localRepo.saveMatchesBulk(preparedMatches);

      bool isViewer = false;
      try {
        final currentUserAuth = FirebaseAuth.instance.currentUser;
        if (currentUserAuth != null && currentUserAuth.isAnonymous) {
          isViewer = true;
        }
      } catch (_) {}

      if (!isViewer) {
        for (final m in preparedMatches) {
          final action = MatchCommandModel(
            id: const Uuid().v4(),
            type: CommandType.updateMatch,
            payload: m.toJson(),
            createdAt: DateTime.now(),
            status: CommandStatus.pending,
          );
          await localRepo.savePendingCommand(action);
        }
      }

      _ref.read(syncEngineProvider).processQueue();
      _ref.invalidate(matchListProvider);
    }
  }

  Future<void> saveAndSync(MatchModel match) async {
    if (!kIsWeb) {
      final localRepo = _ref.read(localMatchRepositoryProvider);
      final existingLocal = await localRepo.getMatch(match.id);
      if (existingLocal != null) {
        if ((existingLocal.events.length) > match.events.length) {
          debugPrint(
            '🛡️ [Conflict Resolution] 既存のローカルデータが新しいため上書きスキップ: ${match.id}',
          );
          return;
        }
      }
    }

    await saveMatch(match);

    if (!kIsWeb) {
      try {
        final isarProjectionStore = _ref.read(isarProjectionStoreProvider);
        await isarProjectionStore.saveMatchProjection(match);
      } catch (e) {
        debugPrint('⚠️ [Projection Cache] Isar Projection 書き込み失敗: $e');
      }
    }
  }
}
