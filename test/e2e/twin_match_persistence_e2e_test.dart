@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/persistence/twin_match_persistence_helper.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import '../helpers/test_isar_helper.dart';

void main() {
  late TestIsarContext isarContext;
  late Isar isar;
  late LocalMatchRepository repository;
  late Directory snapshotDirectory;

  setUpAll(() async {
    isarContext = await TestIsarHelper.openContext(
      schemas: [MatchEntitySchema, MatchEventArchiveEntitySchema],
      prefix: 'isar_twin_e2e',
    );
    isar = isarContext.isar;
    snapshotDirectory = Directory.systemTemp.createTempSync(
      'snapshot_twin_e2e_',
    );
    repository = LocalMatchRepository(isar);
    TwinMatchPersistenceHelper.customDirectory = snapshotDirectory;
    TwinMatchPersistenceHelper.isWebOverride = false;
  });

  tearDownAll(() async {
    TwinMatchPersistenceHelper.customDirectory = null;
    TwinMatchPersistenceHelper.isWebOverride = null;
    await isarContext.dispose();
    if (snapshotDirectory.existsSync()) {
      snapshotDirectory.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await isarContext.clear();
    for (final file in snapshotDirectory.listSync().whereType<File>()) {
      file.deleteSync();
    }
  });

  test('一括保存後にIsarレコードが欠落してもTwinから自己修復できる', () async {
    const match = MatchModel(
      id: 'e2e-twin-recovery',
      tournamentId: 'tournament-e2e',
      matchType: 'individual',
      redName: '復元赤',
      whiteName: '復元白',
      redScore: 2,
      whiteScore: 1,
      status: 'finished',
    );

    await repository.saveMatchesBulk([match]);
    await _waitForSnapshot(snapshotDirectory, match.id);

    await isar.writeTxn(
      () => isar.matchEntitys.filter().firestoreIdEqualTo(match.id).deleteAll(),
    );
    expect(await isar.matchEntitys.count(), 0);

    final recovered = await repository.getMatch(match.id);

    expect(recovered, isNotNull);
    expect(recovered!.id, match.id);
    expect(recovered.redName, '復元赤');
    expect(recovered.whiteScore, 1);
    expect(await isar.matchEntitys.count(), 1);
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
