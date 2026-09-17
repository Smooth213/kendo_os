import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_entity_mapper.dart';

/// 試合イベントのチャンク分割アーカイブ保存・復元ヘルパー
class LocalMatchArchiveHelper {
  static const int hotEventLimit = 200;

  static Future<List<MatchModel>> loadModelsWithArchivedEvents(
    Isar? isar,
    List<MatchEntity> entities,
  ) async =>
      Future.wait(entities.map((e) => loadModelWithArchivedEvents(isar, e)));

  static Future<MatchModel> loadModelWithArchivedEvents(
    Isar? isar,
    MatchEntity entity,
  ) async {
    final model = LocalMatchEntityMapper.toModel(entity);
    if (isar == null) return model;
    final archives = await isar.matchEventArchiveEntitys
        .filter()
        .matchIdEqualTo(entity.firestoreId)
        .sortByChunkIndex()
        .findAll();
    if (archives.isEmpty) return model;
    final archivedEvents = archives
        .expand((archive) => archive.events)
        .map(LocalMatchEntityMapper.entityToEvent)
        .toList();
    return model.copyWith(events: [...archivedEvents, ...model.events]);
  }

  static Future<MatchModel> archiveAndTrimEvents(
    Isar? isar,
    MatchModel match,
  ) async {
    if (isar == null) return match;
    if (match.events.length <= hotEventLimit) {
      // 🚀 【極限最適化】アーカイブが存在しない通常の試合（99.9%）では
      // 空テーブルに対する不要な writeTxn（ジャーナリングI/O・排他ロック）を完全スキップ
      final hasArchive =
          await isar.matchEventArchiveEntitys
              .filter()
              .matchIdEqualTo(match.id)
              .findFirst() !=
          null;
      if (hasArchive) {
        await isar.writeTxn(
          () => isar.matchEventArchiveEntitys
              .filter()
              .matchIdEqualTo(match.id)
              .deleteAll(),
        );
      }
      return match;
    }
    final splitAt = match.events.length - hotEventLimit;
    final coldEvents = match.events.take(splitAt).toList();
    final chunkSize = hotEventLimit;
    await isar.writeTxn(() async {
      for (var offset = 0; offset < coldEvents.length; offset += chunkSize) {
        final chunk = coldEvents.skip(offset).take(chunkSize).toList();
        final chunkIndex = offset ~/ chunkSize;
        final archive = MatchEventArchiveEntity()
          ..archiveKey = '${match.id}:$chunkIndex'
          ..matchId = match.id
          ..chunkIndex = chunkIndex
          ..events = chunk.map(LocalMatchEntityMapper.eventToEntity).toList();
        final existing = await isar.matchEventArchiveEntitys
            .filter()
            .archiveKeyEqualTo(archive.archiveKey)
            .findFirst();
        if (existing != null) archive.id = existing.id;
        await isar.matchEventArchiveEntitys.put(archive);
      }
      final lastChunkIndex = (coldEvents.length - 1) ~/ chunkSize;
      await isar.matchEventArchiveEntitys
          .filter()
          .matchIdEqualTo(match.id)
          .chunkIndexGreaterThan(lastChunkIndex)
          .deleteAll();
    });
    return match.copyWith(events: match.events.skip(splitAt).toList());
  }
}
