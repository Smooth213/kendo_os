import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/persistence/twin_match_persistence_helper.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_archive_helper.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_command_store.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_entity_mapper.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_micro_batch.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_signature_verifier.dart';
import 'package:path_provider/path_provider.dart';
export 'package:kendo_os/shared/infrastructure/repository/match_signature_verifier.dart'
    show TamperedEventException;

final isarProvider = Provider<Isar?>(
  (ref) => throw UnimplementedError('main.dartでIsarを初期化してoverrideしてください'),
);
final localMatchRepositoryProvider = Provider<LocalMatchRepository>(
  (ref) => LocalMatchRepository(ref.read(isarProvider)),
);

class LocalMatchRepository {
  final Isar? _isar;
  LocalMatchRepository(this._isar);
  final Set<String> _verifiedSignatureKeys = <String>{};
  late final MatchSignatureVerifier _signatureVerifier = MatchSignatureVerifier(
    _verifiedSignatureKeys,
  );
  late final LocalMatchMicroBatch _microBatch = LocalMatchMicroBatch(
    saveMatch: saveMatch,
    saveMatchesBulk: saveMatchesBulk,
  );
  Future<void> saveMatchBatched(MatchModel match, {bool isCritical = false}) =>
      _microBatch.saveMatchBatched(match, isCritical: isCritical);

  Future<void> flushMicroBatch() => _microBatch.flush();

  void dispose() => _microBatch.dispose();

  Stream<List<MatchModel>> watchMatches() => _isar == null
      ? Stream.value([])
      : _isar.matchEntitys
            .where()
            .watch(fireImmediately: true)
            .asyncMap(_loadModelsWithArchivedEvents);
  Stream<MatchModel?> watchSingleMatch(String matchId) => _isar == null
      ? Stream.value(null)
      : _isar.matchEntitys
            .filter()
            .firestoreIdEqualTo(matchId)
            .watch(fireImmediately: true)
            .asyncMap(
              (e) async =>
                  e.isEmpty ? null : _loadModelWithArchivedEvents(e.first),
            );
  bool _verifyMatchSignatures(
    MatchModel match, {
    bool allowQuarantine = false,
  }) => _signatureVerifier.verify(match, allowQuarantine: allowQuarantine);
  Future<MatchModel?> getMatch(String matchId) async {
    if (_isar != null) {
      try {
        final entity = await _isar.matchEntitys
            .filter()
            .firestoreIdEqualTo(matchId)
            .findFirst();
        if (entity != null) return await _loadModelWithArchivedEvents(entity);
      } catch (e, stack) {
        debugPrint('🔥 [Critical] ローカルDBからの読み込みに失敗しました: $e');
        FirebaseCrashlytics.instance
            .recordError(e, stack, reason: 'Local DB Read Failure')
            .catchError((_) {});
      }
    }
    final recovered = await TwinMatchPersistenceHelper.recoverMatch(matchId);
    if (recovered != null && _isar != null) {
      try {
        final entity = LocalMatchEntityMapper.toEntity(recovered);
        await _isar.writeTxn(() => _isar.matchEntitys.put(entity));
        debugPrint('🛡️ [Self-Healing] スナップショットからIsarへ自己修復完了: $matchId');
      } catch (_) {}
    }
    return recovered;
  }

  Future<void> saveMatch(MatchModel match) =>
      _saveMatchInternal(match, allowQuarantine: false);
  Future<void> saveMatchSafeMode(MatchModel match) =>
      _saveMatchInternal(match, allowQuarantine: true);
  Future<void> _saveMatchInternal(
    MatchModel match, {
    required bool allowQuarantine,
  }) async {
    final hasTampered = _verifyMatchSignatures(
      match,
      allowQuarantine: allowQuarantine,
    );
    var targetMatch = match;
    if (hasTampered) {
      const quarantineTag = '[QUARANTINE_TAMPERED]';
      if (!targetMatch.note.contains(quarantineTag)) {
        targetMatch = targetMatch.copyWith(
          note: '${targetMatch.note} $quarantineTag'.trim(),
        );
      }
      await _saveEmergencyBackupWithRotation(targetMatch);
      debugPrint(
        '🛡️ [Security Quarantine] 署名不一致データを緊急JSONに隔離退避しました ID: ${match.id}',
      );
    }
    if (_isar != null) {
      try {
        final archivedMatch = await _archiveAndTrimEvents(targetMatch);
        final entity = LocalMatchEntityMapper.toEntity(archivedMatch);
        await _isar.writeTxn(() async {
          final existing = await _isar.matchEntitys
              .filter()
              .firestoreIdEqualTo(targetMatch.id)
              .findFirst();
          if (existing != null) entity.id = existing.id;
          await _isar.matchEntitys.put(entity);
        });
      } catch (e, stack) {
        await _handleStorageError(
          e,
          stack,
          targetMatch,
          'Local DB Save Failure',
        );
        rethrow;
      }
    }
    unawaited(TwinMatchPersistenceHelper.saveSnapshot(targetMatch));
  }

  Future<void> saveMatchWithPendingCommand(
    MatchModel match,
    MatchCommandModel? command,
  ) async {
    if (_isar == null) return;
    try {
      _verifyMatchSignatures(match);
      final archivedMatch = await _archiveAndTrimEvents(match);
      final entity = LocalMatchEntityMapper.toEntity(archivedMatch);
      final cmdEntity = command == null
          ? null
          : (MatchCommandEntity()
              ..commandId = command.id
              ..type = command.type.name
              ..payloadJson = jsonEncode(command.payload)
              ..createdAt = command.createdAt
              ..status = command.status.name);
      await _isar.writeTxn(() async {
        final existing = await _isar.matchEntitys
            .filter()
            .firestoreIdEqualTo(match.id)
            .findFirst();
        if (existing != null) entity.id = existing.id;
        await _isar.matchEntitys.put(entity);
        if (cmdEntity != null && command != null) {
          final existingCmd = await _isar.matchCommandEntitys
              .filter()
              .commandIdEqualTo(command.id)
              .findFirst();
          if (existingCmd != null) cmdEntity.id = existingCmd.id;
          await _isar.matchCommandEntitys.put(cmdEntity);
        }
      });
    } catch (e, stack) {
      await _handleStorageError(
        e,
        stack,
        match,
        'Local DB Command Save Failure',
      );
      rethrow;
    }
  }

  Future<void> executeAndSaveMatchWithCommandRemoval(
    MatchModel match,
    String commandId,
  ) async {
    if (_isar == null) return;
    try {
      _verifyMatchSignatures(match);
      final archivedMatch = await _archiveAndTrimEvents(match);
      final entity = LocalMatchEntityMapper.toEntity(archivedMatch);
      await _isar.writeTxn(() async {
        final existing = await _isar.matchEntitys
            .filter()
            .firestoreIdEqualTo(match.id)
            .findFirst();
        if (existing != null) entity.id = existing.id;
        await _isar.matchEntitys.put(entity);
        await _isar.matchCommandEntitys
            .filter()
            .commandIdEqualTo(commandId)
            .deleteAll();
      });
    } catch (e, stack) {
      await _handleStorageError(
        e,
        stack,
        match,
        'Local DB Command Save Failure',
      );
      rethrow;
    }
  }

  Future<void> _handleStorageError(
    Object e,
    StackTrace stack,
    MatchModel match,
    String reason,
  ) async {
    debugPrint('🔥 [Storage Error] $reason: $e');
    FirebaseCrashlytics.instance
        .recordError(e, stack, reason: reason)
        .catchError((_) {});
    await _saveEmergencyBackupWithRotation(match);
  }

  Future<void> _saveEmergencyBackupWithRotation(MatchModel match) async {
    await TwinMatchPersistenceHelper.saveSnapshot(match);
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupFiles =
          dir
              .listSync()
              .whereType<File>()
              .where((file) => file.path.contains('twin_snapshot_${match.id}_'))
              .toList()
            ..sort((a, b) => b.path.compareTo(a.path));
      if (backupFiles.length > 3) {
        for (final oldFile in backupFiles.sublist(3)) {
          try {
            oldFile.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<void> saveMatchesBulk(
    List<MatchModel> matches, {
    bool skipTwin = false,
  }) => _saveMatchesBulkInternal(
    matches,
    allowQuarantine: false,
    skipTwin: skipTwin,
  );
  Future<void> saveMatchesBulkSafeMode(List<MatchModel> matches) =>
      _saveMatchesBulkInternal(matches, allowQuarantine: true, skipTwin: false);
  Future<void> _saveMatchesBulkInternal(
    List<MatchModel> matches, {
    required bool allowQuarantine,
    required bool skipTwin,
  }) async {
    if (_isar == null || matches.isEmpty) return;
    final processedMatches = <MatchModel>[];
    for (final match in matches) {
      final hasTampered = _verifyMatchSignatures(
        match,
        allowQuarantine: allowQuarantine,
      );
      if (hasTampered) {
        const quarantineTag = '[QUARANTINE_TAMPERED]';
        var tMatch = match;
        if (!tMatch.note.contains(quarantineTag)) {
          tMatch = tMatch.copyWith(
            note: '${tMatch.note} $quarantineTag'.trim(),
          );
        }
        await _saveEmergencyBackupWithRotation(tMatch);
        processedMatches.add(tMatch);
      } else {
        processedMatches.add(match);
      }
    }
    final archivedMatches = <MatchModel>[];
    for (final match in processedMatches) {
      archivedMatches.add(await _archiveAndTrimEvents(match));
    }
    final matchIds = processedMatches.map((m) => m.id).toList();
    await _isar.writeTxn(() async {
      final existingEntities = await _isar.matchEntitys
          .filter()
          .anyOf(matchIds, (q, String id) => q.firestoreIdEqualTo(id))
          .findAll();
      final existingIdMap = {
        for (final e in existingEntities) e.firestoreId: e.id,
      };
      final entitiesToPut = archivedMatches.map((match) {
        final entity = LocalMatchEntityMapper.toEntity(match);
        final existingId = existingIdMap[match.id];
        if (existingId != null) entity.id = existingId;
        return entity;
      }).toList();
      await _isar.matchEntitys.putAll(entitiesToPut);
    });
    if (!skipTwin) {
      await Future.wait(
        processedMatches.map(TwinMatchPersistenceHelper.saveSnapshot),
      );
    }
  }

  Future<void> deleteMatch(String matchId) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      await _isar.matchEntitys.filter().firestoreIdEqualTo(matchId).deleteAll();
      await _isar.matchEventArchiveEntitys
          .filter()
          .matchIdEqualTo(matchId)
          .deleteAll();
    });
  }

  Future<List<MatchModel>> getPendingMatches() async {
    if (_isar == null) return [];
    final entities = await _isar.matchEntitys
        .filter()
        .not()
        .syncStateEqualTo(SyncState.synced)
        .findAll();
    return entities.map(LocalMatchEntityMapper.toModel).toList();
  }

  Future<void> markAsSynced(String matchId) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      final entity = await _isar.matchEntitys
          .filter()
          .firestoreIdEqualTo(matchId)
          .findFirst();
      if (entity != null) {
        entity.syncState = SyncState.synced;
        entity.pendingEvents = [];
        await _isar.matchEntitys.put(entity);
      }
    });
  }

  Future<void> markMatchesAsSynced(List<String> matchIds) async {
    if (_isar == null || matchIds.isEmpty) return;
    await _isar.writeTxn(() async {
      final entities = await _isar.matchEntitys
          .filter()
          .anyOf(matchIds, (q, String id) => q.firestoreIdEqualTo(id))
          .findAll();
      for (final entity in entities) {
        entity.syncState = SyncState.synced;
        entity.pendingEvents = [];
      }
      await _isar.matchEntitys.putAll(entities);
    });
  }

  Stream<int> watchPendingMatchesCount() => _isar == null
      ? Stream.value(0)
      : _isar.matchEntitys
            .filter()
            .not()
            .syncStateEqualTo(SyncState.synced)
            .watch(fireImmediately: true)
            .map((e) => e.length);

  Future<void> savePendingCommand(MatchCommandModel cmd) =>
      LocalMatchCommandStore.savePendingCommand(_isar, cmd);

  Future<void> savePendingCommandsBulk(List<MatchCommandModel> cmds) =>
      LocalMatchCommandStore.savePendingCommandsBulk(_isar, cmds);

  Future<void> deleteCommand(String id) =>
      LocalMatchCommandStore.deleteCommand(_isar, id);

  Future<List<MatchCommandModel>> getPendingCommands() =>
      LocalMatchCommandStore.getPendingCommands(_isar);

  Stream<List<MatchModel>> watchLocalMatches(String tournamentId) =>
      _isar == null
      ? Stream.value([])
      : _isar.matchEntitys
            .filter()
            .tournamentIdEqualTo(tournamentId)
            .sortByOrder()
            .watch(fireImmediately: true)
            .asyncMap(_loadModelsWithArchivedEvents);

  Stream<List<MatchModel>> watchAllLocalMatches() => _isar == null
      ? Stream.value([])
      : _isar.matchEntitys
            .where()
            .sortByOrder()
            .watch(fireImmediately: true)
            .asyncMap(_loadModelsWithArchivedEvents);

  Future<List<MatchModel>> _loadModelsWithArchivedEvents(
    List<MatchEntity> entities,
  ) => LocalMatchArchiveHelper.loadModelsWithArchivedEvents(_isar, entities);

  Future<MatchModel> _loadModelWithArchivedEvents(MatchEntity entity) =>
      LocalMatchArchiveHelper.loadModelWithArchivedEvents(_isar, entity);

  Future<MatchModel> _archiveAndTrimEvents(MatchModel match) =>
      LocalMatchArchiveHelper.archiveAndTrimEvents(_isar, match);

  Future<void> deletePendingCommandsForMatches(Iterable<String> matchIds) =>
      LocalMatchCommandStore.deletePendingCommandsForMatches(_isar, matchIds);

  Future<void> deletePendingCommandsForMatch(String matchId) =>
      LocalMatchCommandStore.deletePendingCommandsForMatch(_isar, matchId);
}
