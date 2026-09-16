import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_archive_helper.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_entity_mapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
    } catch (_) {}

    tempDir = Directory.systemTemp.createTempSync('archive_helper_test_');
    isar = await Isar.open(
      [
        MatchEntitySchema,
        MatchEventArchiveEntitySchema,
        MatchCommandEntitySchema,
      ],
      directory: tempDir.path,
      name: 'archive_helper_db_${DateTime.now().microsecondsSinceEpoch}',
      inspector: false,
    );
  });

  tearDownAll(() async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await isar.writeTxn(() => isar.clear());
  });

  group('LocalMatchArchiveHelper Tests', () {
    test('イベント数が上限以下の場合はアーカイブ分割せずそのまま保持する', () async {
      final match = MatchModel(
        id: 'small_match',
        matchType: '個人戦',
        redName: '赤',
        whiteName: '白',
        events: [
          ScoreEvent(id: 'ev1', side: Side.red, timestamp: DateTime.now()),
        ],
      );

      final trimmed = await LocalMatchArchiveHelper.archiveAndTrimEvents(
        isar,
        match,
      );
      expect(trimmed.events.length, 1);

      final archives = await isar.matchEventArchiveEntitys.where().findAll();
      expect(archives.isEmpty, isTrue);
    });

    test('イベント数が上限(200件)を超える場合はアーカイブチャンクに分割され、復元できること', () async {
      final events = List.generate(
        250,
        (i) =>
            ScoreEvent(id: 'ev_$i', side: Side.red, timestamp: DateTime.now()),
      );
      final match = MatchModel(
        id: 'large_match',
        matchType: '個人戦',
        redName: '赤',
        whiteName: '白',
        events: events,
      );

      final trimmed = await LocalMatchArchiveHelper.archiveAndTrimEvents(
        isar,
        match,
      );
      expect(trimmed.events.length, 200);

      final archives = await isar.matchEventArchiveEntitys.where().findAll();
      expect(archives.length, 1);
      expect(archives.first.events.length, 50);

      // 復元テスト
      final entity = LocalMatchEntityMapper.toEntity(trimmed);

      final restored =
          await LocalMatchArchiveHelper.loadModelWithArchivedEvents(
            isar,
            entity,
          );
      expect(restored.events.length, 250);
    });
  });
}
