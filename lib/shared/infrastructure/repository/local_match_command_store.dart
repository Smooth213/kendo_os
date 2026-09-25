import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';

/// Isar上の保留コマンド（MatchCommandEntity）およびWeb/SharedPreferences操作ヘルパー
class LocalMatchCommandStore {
  static const String _webPendingCommandsKey =
      'kendo_os_pending_commands_queue';

  static Map<String, dynamic> _commandToMap(MatchCommandModel cmd) => {
    'id': cmd.id,
    'type': cmd.type.name,
    'payload': cmd.payload,
    'createdAt': cmd.createdAt.toIso8601String(),
    'status': cmd.status.name,
  };

  static MatchCommandModel _commandFromMap(Map<String, dynamic> map) =>
      MatchCommandModel(
        id: map['id'] as String,
        type: CommandType.values.byName(map['type'] as String),
        payload: Map<String, dynamic>.from(map['payload'] as Map),
        createdAt: DateTime.parse(map['createdAt'] as String),
        status: CommandStatus.values.byName(map['status'] as String),
      );

  static Future<List<MatchCommandModel>> _getPendingCommandsWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_webPendingCommandsKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final list = jsonDecode(jsonStr) as List;
      return list
          .map(
            (item) => _commandFromMap(Map<String, dynamic>.from(item as Map)),
          )
          .where((cmd) => cmd.status == CommandStatus.pending)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      debugPrint(
        '⚠️ [LocalMatchCommandStore] Web pending commands load error: $e',
      );
      return [];
    }
  }

  static Future<void> _savePendingCommandsWeb(
    List<MatchCommandModel> newCmds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _getPendingCommandsWeb();
      final map = {for (final c in current) c.id: c};
      for (final cmd in newCmds) {
        map[cmd.id] = cmd;
      }
      final list = map.values.map(_commandToMap).toList();
      await prefs.setString(_webPendingCommandsKey, jsonEncode(list));
    } catch (e) {
      debugPrint(
        '⚠️ [LocalMatchCommandStore] Web pending commands save error: $e',
      );
    }
  }

  static Future<void> _deleteCommandWeb(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _getPendingCommandsWeb();
      current.removeWhere((c) => c.id == id);
      final list = current.map(_commandToMap).toList();
      await prefs.setString(_webPendingCommandsKey, jsonEncode(list));
    } catch (e) {
      debugPrint(
        '⚠️ [LocalMatchCommandStore] Web pending command delete error: $e',
      );
    }
  }

  static Future<void> _deleteCommandsForMatchesWeb(
    Iterable<String> matchIds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _getPendingCommandsWeb();
      final matchIdSet = matchIds.toSet();
      current.removeWhere((c) => matchIdSet.contains(c.payload['id']));
      final list = current.map(_commandToMap).toList();
      await prefs.setString(_webPendingCommandsKey, jsonEncode(list));
    } catch (e) {
      debugPrint(
        '⚠️ [LocalMatchCommandStore] Web pending commands for matches delete error: $e',
      );
    }
  }

  static Future<void> savePendingCommand(
    Isar? isar,
    MatchCommandModel cmd,
  ) async {
    if (isar == null) {
      await _savePendingCommandsWeb([cmd]);
      return;
    }
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
    if (isar == null) {
      await _deleteCommandWeb(id);
      return;
    }
    await isar.writeTxn(
      () => isar.matchCommandEntitys.filter().commandIdEqualTo(id).deleteAll(),
    );
  }

  static Future<List<MatchCommandModel>> getPendingCommands(Isar? isar) async {
    if (isar == null) {
      return await _getPendingCommandsWeb();
    }
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
    if (cmds.isEmpty) return;
    if (isar == null) {
      await _savePendingCommandsWeb(cmds);
      return;
    }
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
    final matchIdSet = matchIds.toSet();
    if (matchIdSet.isEmpty) return;
    if (isar == null) {
      await _deleteCommandsForMatchesWeb(matchIdSet);
      return;
    }
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
