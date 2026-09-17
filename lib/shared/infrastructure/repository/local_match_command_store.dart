import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';

/// Isar上の保留コマンド（MatchCommandEntity）操作ヘルパー
class LocalMatchCommandStore {
  static Future<void> savePendingCommand(
    Isar? isar,
    MatchCommandModel cmd,
  ) async {
    if (isar == null) return;
    final entity = MatchCommandEntity()
      ..commandId = cmd.id
      ..type = cmd.type.name
      ..payloadJson = jsonEncode(cmd.payload)
      ..createdAt = cmd.createdAt
      ..status = cmd.status.name;

    await isar.writeTxn(() async {
      final existing = await isar.matchCommandEntitys
          .filter()
          .commandIdEqualTo(cmd.id)
          .findFirst();
      if (existing != null) entity.id = existing.id;
      await isar.matchCommandEntitys.put(entity);
    });
  }

  static Future<void> deleteCommand(Isar? isar, String id) async {
    if (isar == null) return;
    await isar.writeTxn(
      () => isar.matchCommandEntitys.filter().commandIdEqualTo(id).deleteAll(),
    );
  }

  static Future<List<MatchCommandModel>> getPendingCommands(Isar? isar) async {
    if (isar == null) return [];
    final entities = await isar.matchCommandEntitys
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

  static Future<void> savePendingCommandsBulk(
    Isar? isar,
    List<MatchCommandModel> cmds,
  ) async {
    if (isar == null || cmds.isEmpty) return;
    final entities = cmds.map((cmd) {
      return MatchCommandEntity()
        ..commandId = cmd.id
        ..type = cmd.type.name
        ..payloadJson = jsonEncode(cmd.payload)
        ..createdAt = cmd.createdAt
        ..status = cmd.status.name;
    }).toList();

    await isar.writeTxn(() async {
      final cmdIds = cmds.map((c) => c.id).toList();
      final existingEntities = await isar.matchCommandEntitys
          .filter()
          .anyOf(cmdIds, (q, id) => q.commandIdEqualTo(id))
          .findAll();
      final existingMap = {for (final e in existingEntities) e.commandId: e.id};

      for (final entity in entities) {
        final existingId = existingMap[entity.commandId];
        if (existingId != null) {
          entity.id = existingId;
        }
      }
      await isar.matchCommandEntitys.putAll(entities);
    });
  }

  static Future<void> deletePendingCommandsForMatches(
    Isar? isar,
    Iterable<String> matchIds,
  ) async {
    if (isar == null) return;
    final matchIdSet = matchIds.toSet();
    if (matchIdSet.isEmpty) return;
    try {
      await isar.writeTxn(() async {
        final cmds = await isar.matchCommandEntitys
            .filter()
            .statusEqualTo(CommandStatus.pending.name)
            .findAll();
        final idsToDelete = <Id>[];
        for (final cmd in cmds) {
          try {
            final map = jsonDecode(cmd.payloadJson);
            if (map is Map && matchIdSet.contains(map['id'])) {
              idsToDelete.add(cmd.id);
            }
          } catch (_) {}
        }
        if (idsToDelete.isNotEmpty) {
          await isar.matchCommandEntitys.deleteAll(idsToDelete);
        }
      });
    } catch (e) {
      debugPrint('⚠️ [LocalMatchCommandStore] 保留コマンド削除エラー: $e');
    }
  }

  static Future<void> deletePendingCommandsForMatch(
    Isar? isar,
    String matchId,
  ) => deletePendingCommandsForMatches(isar, [matchId]);
}
