// ignore_for_file: experimental_member_use
import 'dart:convert';
import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_entity_mapper.dart';
import 'package:path_provider/path_provider.dart';

class TamperedEventException implements Exception {
  final String message;
  TamperedEventException(this.message);
  @override
  String toString() => 'TamperedEventException: $message';
}

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

  bool _verifyMatchSignatures(
    MatchModel match, {
    bool allowQuarantine = false,
  }) {
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

  Stream<List<MatchModel>> watchMatches() => _isar == null
      ? Stream.value([])
      : _isar.matchEntitys
            .where()
            .watch(fireImmediately: true)
            .map((e) => e.map(LocalMatchEntityMapper.toModel).toList());

  Stream<MatchModel?> watchSingleMatch(String matchId) => _isar == null
      ? Stream.value(null)
      : _isar.matchEntitys
            .filter()
            .firestoreIdEqualTo(matchId)
            .watch(fireImmediately: true)
            .map(
              (e) => e.isEmpty ? null : LocalMatchEntityMapper.toModel(e.first),
            );

  Future<MatchModel?> getMatch(String matchId) async {
    if (_isar == null) return null;
    try {
      final entity = await _isar.matchEntitys
          .filter()
          .firestoreIdEqualTo(matchId)
          .findFirst();
      return entity == null ? null : LocalMatchEntityMapper.toModel(entity);
    } catch (e, stack) {
      debugPrint('🔥 [Critical] ローカルDBからの読み込みに失敗しました: $e');
      FirebaseCrashlytics.instance
          .recordError(e, stack, reason: 'Local DB Read Failure')
          .catchError((_) {});
      return null;
    }
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

    if (_isar == null) return;
    try {
      final entity = LocalMatchEntityMapper.toEntity(targetMatch);
      await _isar.writeTxn(() async {
        final existing = await _isar.matchEntitys
            .filter()
            .firestoreIdEqualTo(targetMatch.id)
            .findFirst();
        if (existing != null) entity.id = existing.id;
        await _isar.matchEntitys.put(entity);
      });
    } catch (e, stack) {
      await _handleStorageError(e, stack, targetMatch, 'Local DB Save Failure');
      rethrow;
    }
  }

  Future<void> saveMatchWithPendingCommand(
    MatchModel match,
    MatchCommandModel? command,
  ) async {
    if (_isar == null) return;
    try {
      _verifyMatchSignatures(match);
      final entity = LocalMatchEntityMapper.toEntity(match);
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
      final entity = LocalMatchEntityMapper.toEntity(match);
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

  Future<void> saveMatchesBulk(List<MatchModel> matches) =>
      _saveMatchesBulkInternal(matches, allowQuarantine: false);

  Future<void> saveMatchesBulkSafeMode(List<MatchModel> matches) =>
      _saveMatchesBulkInternal(matches, allowQuarantine: true);

  Future<void> _saveMatchesBulkInternal(
    List<MatchModel> matches, {
    required bool allowQuarantine,
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

    final matchIds = processedMatches.map((m) => m.id).toList();
    await _isar.writeTxn(() async {
      final existingEntities = await _isar.matchEntitys
          .filter()
          .anyOf(matchIds, (q, String id) => q.firestoreIdEqualTo(id))
          .findAll();
      final existingIdMap = {
        for (final e in existingEntities) e.firestoreId: e.id,
      };
      final entitiesToPut = processedMatches.map((match) {
        final entity = LocalMatchEntityMapper.toEntity(match);
        final existingId = existingIdMap[match.id];
        if (existingId != null) entity.id = existingId;
        return entity;
      }).toList();
      await _isar.matchEntitys.putAll(entitiesToPut);
    });
  }

  Future<void> deleteMatch(String matchId) async {
    if (_isar == null) return;
    await _isar.writeTxn(
      () => _isar.matchEntitys.filter().firestoreIdEqualTo(matchId).deleteAll(),
    );
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

  Future<void> savePendingCommand(MatchCommandModel cmd) async {
    if (_isar == null) return;
    final entity = MatchCommandEntity()
      ..commandId = cmd.id
      ..type = cmd.type.name
      ..payloadJson = jsonEncode(cmd.payload)
      ..createdAt = cmd.createdAt
      ..status = cmd.status.name;

    await _isar.writeTxn(() async {
      final existing = await _isar.matchCommandEntitys
          .filter()
          .commandIdEqualTo(cmd.id)
          .findFirst();
      if (existing != null) entity.id = existing.id;
      await _isar.matchCommandEntitys.put(entity);
    });
  }

  Future<void> deleteCommand(String id) async {
    if (_isar == null) return;
    await _isar.writeTxn(
      () => _isar.matchCommandEntitys.filter().commandIdEqualTo(id).deleteAll(),
    );
  }

  Future<List<MatchCommandModel>> getPendingCommands() async {
    if (_isar == null) return [];
    final entities = await _isar.matchCommandEntitys
        .filter()
        .statusEqualTo(CommandStatus.pending.name)
        .sortByCreatedAt()
        .findAll();
    return entities
        .map(
          (e) => MatchCommandModel(
            id: e.commandId,
            type: CommandType.values.byName(e.type),
            payload: jsonDecode(e.payloadJson),
            createdAt: e.createdAt,
            status: CommandStatus.values.byName(e.status),
          ),
        )
        .toList();
  }

  Stream<List<MatchModel>> watchLocalMatches(String tournamentId) =>
      _isar == null
      ? Stream.value([])
      : _isar.matchEntitys
            .filter()
            .tournamentIdEqualTo(tournamentId)
            .sortByOrder()
            .watch(fireImmediately: true)
            .map((e) => e.map(LocalMatchEntityMapper.toModel).toList());

  Stream<List<MatchModel>> watchAllLocalMatches() => _isar == null
      ? Stream.value([])
      : _isar.matchEntitys
            .where()
            .sortByOrder()
            .watch(fireImmediately: true)
            .map((e) => e.map(LocalMatchEntityMapper.toModel).toList());

  Future<void> _saveEmergencyBackupWithRotation(MatchModel match) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/emergency_backup_${match.id}_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonEncode(match.toJson()), flush: true);
      final backupFiles =
          dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.contains('emergency_backup_${match.id}_'))
              .toList()
            ..sort((a, b) => b.path.compareTo(a.path));

      if (backupFiles.length > 3) {
        for (final oldFile in backupFiles.sublist(3)) {
          try {
            oldFile.deleteSync();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('💥 [致命的エラー] 緊急避難保存にも失敗しました: $e');
    }
  }
}
