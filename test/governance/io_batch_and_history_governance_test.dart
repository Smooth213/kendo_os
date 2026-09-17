import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_event_cloud_codec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('💾 【第15条 ガバナンス監査】データI/Oバッチ集約・Isar最適化 ＆ 履歴チャンク分割規約', () {
    test(
      'Rule 1: [マイクロバッチング] local_match_repository.dart の saveMatchBatched / flushMicroBatch 規約',
      () {
        final file = File(
          'lib/shared/infrastructure/repository/local_match_repository.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('saveMatchBatched'), isTrue);
        expect(content.contains('flushMicroBatch'), isTrue);
      },
    );

    test(
      'Rule 2: [単一writeTxnアトミック化] saveMatchWithPendingCommand ＆ savePendingCommandsBulk 規約',
      () {
        final repoFile = File(
          'lib/shared/infrastructure/repository/local_match_repository.dart',
        );
        final helperFile = File(
          'lib/features/match/application/services/match_persistence_helper.dart',
        );
        final storeFile = File(
          'lib/shared/infrastructure/repository/local_match_command_store.dart',
        );

        expect(repoFile.existsSync(), isTrue);
        expect(helperFile.existsSync(), isTrue);
        expect(storeFile.existsSync(), isTrue);

        final repoContent = repoFile.readAsStringSync();
        final helperContent = helperFile.readAsStringSync();
        final storeContent = storeFile.readAsStringSync();

        expect(
          repoContent.contains('Future<void> saveMatchWithPendingCommand('),
          isTrue,
        );
        expect(helperContent.contains('saveMatchWithPendingCommand('), isTrue);

        expect(storeContent.contains('savePendingCommandsBulk'), isTrue);
        expect(storeContent.contains('matchCommandEntitys.putAll'), isTrue);
        expect(repoContent.contains('savePendingCommandsBulk'), isTrue);
        expect(helperContent.contains('savePendingCommandsBulk'), isTrue);
      },
    );

    test(
      'Rule 3: [クラウド同期バッチ化] sync_provider.dart で未同期試合の取得が並列化され、saveMatchesBulk で一括反映されていること',
      () {
        final syncFile = File(
          'lib/features/tournament/presentation/operate/providers/sync_provider.dart',
        );
        expect(syncFile.existsSync(), isTrue);
        final syncContent = syncFile.readAsStringSync();

        expect(syncContent.contains('await Future.wait('), isTrue);
        expect(
          RegExp(
            r'await localRepo\.saveMatchesBulk\(\s*syncedMatchesToSave',
          ).hasMatch(syncContent),
          isTrue,
        );
      },
    );

    test('Rule 4: [Isar DB最適化＆空Txn根絶] 128MB MMAP、3世代緊急バックアップ、空Txn根絶規約', () {
      final startupFile = File('lib/bootstrap/app_startup.dart');
      expect(startupFile.existsSync(), isTrue);
      expect(
        startupFile.readAsStringSync().contains('maxSizeMiB = 128'),
        isTrue,
      );

      final helperFile = File('lib/shared/bootstrap/app_bootstrap_helper.dart');
      expect(helperFile.existsSync(), isTrue);
      expect(helperFile.readAsStringSync().contains('maxSizeMiB: 128'), isTrue);

      final repoFile = File(
        'lib/shared/infrastructure/repository/local_match_repository.dart',
      );
      expect(repoFile.existsSync(), isTrue);
      final repoContent = repoFile.readAsStringSync();
      expect(repoContent.contains('_saveEmergencyBackupWithRotation'), isTrue);
      expect(repoContent.contains('backupFiles.length > 3'), isTrue);
      expect(repoContent.contains('oldFile.deleteSync()'), isTrue);

      final archiveHelperFile = File(
        'lib/shared/infrastructure/repository/local_match_archive_helper.dart',
      );
      expect(archiveHelperFile.existsSync(), isTrue);
      final archiveContent = archiveHelperFile.readAsStringSync();
      expect(
        archiveContent.contains('hasArchive') &&
            archiveContent.contains('findFirst()'),
        isTrue,
      );
    });

    test(
      'Rule 5: [毒薬コマンド自律パージ＆滞留防止] SyncEngine 自律パージ ＆ deletePendingCommandsForMatches 規約',
      () {
        final syncEngineFile = File(
          'lib/shared/infrastructure/repository/sync_engine.dart',
        );
        expect(syncEngineFile.existsSync(), isTrue);
        final syncContent = syncEngineFile.readAsStringSync();

        expect(syncContent.contains('ConflictException'), isTrue);
        expect(
          syncContent.contains('remoteMatch.version >= match.version'),
          isTrue,
        );
        expect(syncContent.contains('Staleコマンドを自律パージします'), isTrue);
        expect(syncContent.contains('_retryCount >= 10'), isTrue);
        expect(syncContent.contains('毒薬キュー化防止のため自律パージします'), isTrue);

        final localRepoFile = File(
          'lib/shared/infrastructure/repository/local_match_repository.dart',
        );
        final syncProviderFile = File(
          'lib/features/tournament/presentation/operate/providers/sync_provider.dart',
        );
        expect(localRepoFile.existsSync(), isTrue);
        expect(syncProviderFile.existsSync(), isTrue);
        expect(
          localRepoFile.readAsStringSync().contains(
            'deletePendingCommandsForMatches',
          ),
          isTrue,
        );
        expect(
          syncProviderFile.readAsStringSync().contains(
            'deletePendingCommandsForMatches',
          ),
          isTrue,
        );
      },
    );

    test('Rule 6: [長期イベント履歴チャンク分割] チャンク分割・全件完全復元・孤立チャンク防止規約', () {
      expect(MatchEventCloudCodec.hotEventLimit, 200);
      expect(MatchEventCloudCodec.archiveChunkSize, 200);

      final events = List.generate(
        450,
        (index) => ScoreEvent(
          id: 'event_$index',
          side: Side.red,
          timestamp: DateTime.fromMillisecondsSinceEpoch(index),
        ),
      );
      final match = MatchModel(
        id: 'governance_match',
        matchType: 'individual',
        redName: '赤',
        whiteName: '白',
        events: events,
      );

      final data = MatchEventCloudCodec.matchData(match);
      final archives = MatchEventCloudCodec.archiveData(match).toList();

      expect((data['events'] as List).length, 200);
      expect(data['eventArchiveVersion'], 450);
      expect(archives.length, 2);
      expect(
        archives.expand((archive) => archive['events'] as List).length,
        250,
      );

      final repository = File(
        'lib/shared/infrastructure/repository/match_repository.dart',
      ).readAsStringSync();
      final rules = File('firestore.rules').readAsStringSync();

      expect(repository.contains("collection('events')"), isTrue);
      expect(repository.contains('batch.delete(chunk.reference)'), isTrue);
      expect(rules.contains('match /events/{eventChunkId}'), isTrue);
    });
  });
}
