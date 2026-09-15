@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/persistence/twin_match_persistence_helper.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

void main() {
  late Isar isar;
  late LocalMatchRepository repository;
  late Directory isarDirectory;
  late Directory snapshotDirectory;

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
    } catch (_) {}

    isarDirectory = Directory.systemTemp.createTempSync('isar_twin_repo_');
    snapshotDirectory = Directory.systemTemp.createTempSync(
      'snapshot_twin_repo_',
    );
    isar = await Isar.open(
      [MatchEntitySchema, MatchEventArchiveEntitySchema],
      directory: isarDirectory.path,
      name: 'twin_behavior_${DateTime.now().microsecondsSinceEpoch}',
      inspector: false,
    );
    repository = LocalMatchRepository(isar);
    TwinMatchPersistenceHelper.customDirectory = snapshotDirectory;
    TwinMatchPersistenceHelper.isWebOverride = false;
  });

  tearDownAll(() async {
    TwinMatchPersistenceHelper.customDirectory = null;
    TwinMatchPersistenceHelper.isWebOverride = null;
    if (isar.isOpen) await isar.close(deleteFromDisk: true);
    if (isarDirectory.existsSync()) {
      isarDirectory.deleteSync(recursive: true);
    }
    if (snapshotDirectory.existsSync()) {
      snapshotDirectory.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await isar.writeTxn(() => isar.clear());
    for (final file in snapshotDirectory.listSync().whereType<File>()) {
      file.deleteSync();
    }
  });

  test('通常のsaveMatchesBulkはIsarとTwinスナップショットへ保存する', () async {
    const match = MatchModel(
      id: 'bulk-twin-normal',
      matchType: 'individual',
      redName: '赤選手',
      whiteName: '白選手',
      status: 'finished',
    );

    await repository.saveMatchesBulk([match]);

    expect(await isar.matchEntitys.count(), 1);
    await _waitForSnapshot(snapshotDirectory, match.id);
    final recovered = await TwinMatchPersistenceHelper.recoverMatch(match.id);
    expect(recovered?.id, match.id);
  });

  test('skipTwin=trueはIsarへ保存するがTwinスナップショットを作成しない', () async {
    const match = MatchModel(
      id: 'bulk-twin-skipped',
      matchType: 'individual',
      redName: '赤選手',
      whiteName: '白選手',
      status: 'synced',
    );

    await repository.saveMatchesBulk([match], skipTwin: true);

    expect(await isar.matchEntitys.count(), 1);
    final snapshotFiles = snapshotDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.contains(match.id))
        .toList();
    expect(snapshotFiles, isEmpty);
  });
}

Future<void> _waitForSnapshot(Directory directory, String matchId) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    final exists = directory.listSync().whereType<File>().any(
      (file) => file.path.contains(matchId),
    );
    if (exists) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Twin snapshot was not created for $matchId');
}
