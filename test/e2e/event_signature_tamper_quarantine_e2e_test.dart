@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/persistence/twin_match_persistence_helper.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import '../helpers/test_isar_helper.dart';

void main() {
  TestIsarContext? isarContext;
  late Isar isar;
  late LocalMatchRepository repository;
  Directory? snapshotDirectory;

  setUpAll(() async {
    final ctx = await TestIsarHelper.openContext(
      schemas: [MatchEntitySchema, MatchEventArchiveEntitySchema],
      prefix: 'isar_quarantine_e2e',
    );
    isarContext = ctx;
    isar = ctx.isar;
    final dir = Directory.systemTemp.createTempSync('snapshot_quarantine_e2e_');
    snapshotDirectory = dir;
    repository = LocalMatchRepository(isar);
    TwinMatchPersistenceHelper.customDirectory = dir;
    TwinMatchPersistenceHelper.isWebOverride = false;
  });

  tearDownAll(() async {
    TwinMatchPersistenceHelper.customDirectory = null;
    TwinMatchPersistenceHelper.isWebOverride = null;
    await isarContext?.dispose();
    if (snapshotDirectory != null && snapshotDirectory!.existsSync()) {
      snapshotDirectory!.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await isarContext?.clear();
    if (snapshotDirectory != null && snapshotDirectory!.existsSync()) {
      for (final file in snapshotDirectory!.listSync().whereType<File>()) {
        file.deleteSync();
      }
    }
  });

  group('[E2E] イベント電子署名改ざん隔離および自己修復 E2Eシナリオテスト', () {
    test('悪意あるスコア改ざん発生時にクランティン隔離され正規イベント再同期で自己修復されること', () async {
      const matchId = 'e2e-tamper-match-001';
      final now = DateTime.now();

      // 1. 正規端末による第1得点（メン）
      final validMen = ScoreEventLegacyAdapter.fromLegacy(
        type: PointType.men,
        side: Side.red,
        id: 'evt-valid-men',
        timestamp: now,
        userId: 'auth-referee-1',
      );

      final initialMatch = const MatchModel(
        id: matchId,
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
      ).copyWith(events: [validMen]);

      await repository.saveMatch(initialMatch);

      final loaded1 = await repository.getMatch(matchId);
      expect(loaded1, isNotNull);
      expect(loaded1!.redScore, 1);
      expect(loaded1.events.length, 1);

      // 2. 外部通信での悪意ある改ざんイベント混入（署名偽装）
      final tamperedEvent = validMen.copyWith(
        id: 'evt-tampered-fake',
        strikeType: StrikeType.tsuki,
        signature: 'forged_fake_signature_packet',
      );

      final corruptedMatch = initialMatch.copyWith(
        events: [validMen, tamperedEvent],
        redScore: 2,
      );

      // 通常保存時は改ざん例外で遮断されること
      expect(
        () => repository.saveMatch(corruptedMatch),
        throwsA(isA<TamperedEventException>()),
      );

      // 3. セーフモード（クランティン隔離モード）での退避保存
      await repository.saveMatchSafeMode(corruptedMatch);

      // 4. 正規端末から正当な第2得点（コテ）を受信して完全修復
      final validKote = ScoreEventLegacyAdapter.fromLegacy(
        type: PointType.kote,
        side: Side.red,
        id: 'evt-valid-kote',
        timestamp: now.add(const Duration(seconds: 30)),
        userId: 'auth-referee-1',
      );

      final healedMatch = initialMatch.copyWith(
        events: [validMen, validKote],
        redScore: 2,
        status: 'finished',
      );

      await repository.saveMatch(healedMatch);

      final finalLoaded = await repository.getMatch(matchId);
      expect(finalLoaded, isNotNull);
      expect(finalLoaded!.redScore, 2);
      expect(finalLoaded.status, 'finished');
      expect(finalLoaded.events.length, 2);
      expect(
        finalLoaded.events.map((e) => e.id).toSet(),
        containsAll(['evt-valid-men', 'evt-valid-kote']),
      );
    });
  });
}
