@TestOn('vm')
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

void main() {
  group('🔋 [Phase 5 Performance Governance] DB・I/O バッチ最適化テスト', () {
    late Isar isar;
    late LocalMatchRepository repository;
    late Directory tempDir;

    setUpAll(() async {
      try {
        await Isar.initializeIsarCore(download: true);
      } catch (_) {}

      tempDir = Directory.systemTemp.createTempSync('isar_batch_test_');
      isar = await Isar.open(
        [MatchEntitySchema],
        directory: tempDir.path,
        name: 'batch_test_db_${DateTime.now().microsecondsSinceEpoch}',
        inspector: false,
      );

      repository = LocalMatchRepository(isar);
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
      await isar.writeTxn(() async {
        await isar.clear();
      });
    });

    test('1. saveMatchesBulk: 大量試合データ（50件）を一括バッチputAllで正確に永続化できること', () async {
      final matches = List.generate(
        50,
        (i) => MatchModel(
          id: 'batch_match_$i',
          tournamentId: 't_batch',
          category: '一般',
          order: i + 1,
          redName: '選手赤_$i',
          whiteName: '選手白_$i',
          matchType: '個人戦',
          status: 'ongoing',
          syncState: SyncState.localOnly,
        ),
      );

      // バッチ保存実行
      await repository.saveMatchesBulk(matches);

      // 保存件数検証
      final count = await isar.matchEntitys.count();
      expect(count, 50);

      // ランダムサンプリング検証
      final match25 = await repository.getMatch('batch_match_25');
      expect(match25, isNotNull);
      expect(match25!.redName, '選手赤_25');
      expect(match25.order, 26);
    });

    test(
      '2. saveMatchesBulk: 既存エンティティが存在する場合に既存IDを引き継いで重複なく上書き更新されること',
      () async {
        final initialMatches = List.generate(
          20,
          (i) => MatchModel(
            id: 'overwrite_match_$i',
            tournamentId: 't_overwrite',
            category: '一般',
            order: i + 1,
            redName: '元選手_$i',
            whiteName: '白選手_$i',
            matchType: '個人戦',
            status: 'ongoing',
            redScore: 0,
          ),
        );

        await repository.saveMatchesBulk(initialMatches);
        expect(await isar.matchEntitys.count(), 20);

        // スコアを更新して再度一括保存
        final updatedMatches = initialMatches
            .map((m) => m.copyWith(redScore: 2, status: 'finished'))
            .toList();

        await repository.saveMatchesBulk(updatedMatches);

        // 件数は20件のままであること（重複なし）
        expect(await isar.matchEntitys.count(), 20);

        // 更新後の値が反映されていること
        final updated0 = await repository.getMatch('overwrite_match_0');
        expect(updated0!.redScore, 2);
        expect(updated0.status, 'finished');
      },
    );

    test(
      '3. markMatchesAsSynced: 複数試合の同期ステートを一括putAllでSyncState.syncedへ移行できること',
      () async {
        final matches = List.generate(
          10,
          (i) => MatchModel(
            id: 'sync_match_$i',
            tournamentId: 't_sync',
            category: '一般',
            order: i + 1,
            redName: '選手_$i',
            whiteName: '相手_$i',
            matchType: '個人戦',
            status: 'finished',
            syncState: SyncState.localOnly,
          ),
        );

        await repository.saveMatchesBulk(matches);

        // 5件だけ同期完了にする
        final syncedIds = ['sync_match_0', 'sync_match_2', 'sync_match_4'];
        await repository.markMatchesAsSynced(syncedIds);

        final match0 = await repository.getMatch('sync_match_0');
        final match1 = await repository.getMatch('sync_match_1');
        final match2 = await repository.getMatch('sync_match_2');

        expect(match0!.syncState, SyncState.synced);
        expect(match1!.syncState, SyncState.localOnly);
        expect(match2!.syncState, SyncState.synced);
      },
    );
  });
}
