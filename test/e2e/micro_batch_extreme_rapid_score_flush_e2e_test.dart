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
      prefix: 'isar_micro_batch_e2e',
    );
    isarContext = ctx;
    isar = ctx.isar;
    final dir = Directory.systemTemp.createTempSync('snapshot_mb_e2e_');
    snapshotDirectory = dir;
    repository = LocalMatchRepository(isar);
    TwinMatchPersistenceHelper.customDirectory = dir;
    TwinMatchPersistenceHelper.isWebOverride = false;
  });

  tearDownAll(() async {
    repository.dispose();
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

  group('[E2E] 極限連打スコア入力マイクロバッチ永続化 E2Eシナリオテスト', () {
    test('毎秒20回以上のスコア連打およびタイマー切替時にマイクロバッチが破綻せずIsarとTwinへ完全永続化されること', () async {
      const matchId = 'e2e-rapid-batch-001';
      final now = DateTime.now();

      MatchModel currentMatch = const MatchModel(
        id: matchId,
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'in_progress',
      );

      // 毎秒20回相当（合計25回）の急速なスコアイベントおよびタイマー状態更新
      for (int i = 1; i <= 25; i++) {
        final isRed = i % 2 != 0;
        final event = ScoreEventLegacyAdapter.fromLegacy(
          type: isRed ? PointType.men : PointType.kote,
          side: isRed ? Side.red : Side.white,
          id: 'rapid-evt-$i',
          timestamp: now.add(Duration(milliseconds: i * 40)),
          userId: 'ref-rapid-operator',
        );

        currentMatch = currentMatch.copyWith(
          redScore: isRed ? currentMatch.redScore + 1 : currentMatch.redScore,
          whiteScore: !isRed
              ? currentMatch.whiteScore + 1
              : currentMatch.whiteScore,
          events: [...currentMatch.events, event],
          status: i == 25 ? 'finished' : 'in_progress',
        );

        // バッチキューに投入（得点更新のため内部でクリティカルフラッシュ含む）
        await repository.saveMatchBatched(currentMatch);
      }

      // 明示的フラッシュで完全永続化待機
      await repository.flushMicroBatch();

      // 1. Isarからの取得検証
      final isarMatch = await repository.getMatch(matchId);
      expect(isarMatch, isNotNull);
      expect(isarMatch!.status, 'finished');
      expect(isarMatch.events.length, 25);
      expect(isarMatch.redScore, 13);
      expect(isarMatch.whiteScore, 12);

      // 2. Twinスナップショットからの取得復元検証（非同期キュー完了待機）
      await Future.delayed(const Duration(milliseconds: 150));
      final twinMatch = await TwinMatchPersistenceHelper.recoverMatch(matchId);
      expect(twinMatch, isNotNull);
      expect(twinMatch!.id, matchId);
      expect(twinMatch.redScore, 13);
      expect(twinMatch.whiteScore, 12);
      expect(twinMatch.status, 'finished');
    });
  });
}
