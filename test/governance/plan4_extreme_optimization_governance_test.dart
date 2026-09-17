import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    '🛡️ 【第32条 ガバナンス監査】4大極限最適化・安定化（Staleパージ・ルート再描画防止・待機タイマー沈黙・ライフサイクル一元化）永続保証規約',
    () {
      test(
        '1. [ルート購読局所化規約] main.dart で settingsProvider を丸ごと購読せず、.select((s) => s.themeMode) で局所化されていること',
        () {
          final mainFile = File('lib/main.dart');
          expect(mainFile.existsSync(), isTrue);
          final content = mainFile.readAsStringSync();

          // ref.watch(settingsProvider) のような丸ごと購読は禁止（Jank/全画面リビルド防止）
          final hasFullWatch = RegExp(
            r'ref\.watch\(\s*settingsProvider\s*\)',
          ).hasMatch(content);
          expect(
            hasFullWatch,
            isFalse,
            reason:
                'main.dart のルートで settingsProvider を丸ごと購読してはならない。設定変更時のアプリ全体再ビルドを防ぐため select で局所化すること。',
          );

          // select((s) => s.themeMode) が使用されていること
          expect(
            content.contains('settingsProvider.select((s) => s.themeMode)'),
            isTrue,
            reason: 'main.dart では themeMode のみをピンポイント購読していなければならない',
          );
        },
      );

      test(
        '2. [ライフサイクル同期一元化規約] main.dart での didChangeAppLifecycleState 重複同期が排除され、sync_provider.dart に一元化されていること',
        () {
          final mainFile = File('lib/main.dart');
          final syncProviderFile = File(
            'lib/features/tournament/presentation/operate/providers/sync_provider.dart',
          );

          expect(mainFile.existsSync(), isTrue);
          expect(syncProviderFile.existsSync(), isTrue);

          final mainContent = mainFile.readAsStringSync();
          final syncContent = syncProviderFile.readAsStringSync();

          // main.dart 内で didChangeAppLifecycleState による syncNow 呼び出しが存在しないこと
          expect(
            mainContent.contains('didChangeAppLifecycleState'),
            isFalse,
            reason:
                'main.dart に不要な didChangeAppLifecycleState を置かず、同期は sync_provider.dart の AppLifecycleListener に一元化すること',
          );

          // sync_provider.dart に AppLifecycleListener が配備されていること
          expect(
            syncContent.contains('AppLifecycleListener'),
            isTrue,
            reason: 'sync_provider.dart に AppLifecycleListener が配備されていなければならない',
          );
        },
      );

      test(
        '3. [待機時CPU起床ゼロ規約] BatteryNotifier に AppLifecycleListener が配備され、paused時にタイマーが完全停止すること',
        () {
          final settingsFile = File(
            'lib/shared/presentation/providers/settings_provider.dart',
          );
          expect(settingsFile.existsSync(), isTrue);
          final content = settingsFile.readAsStringSync();

          expect(content.contains('class BatteryNotifier'), isTrue);

          // BatteryNotifier 内に AppLifecycleListener が存在すること
          expect(
            content.contains('AppLifecycleListener('),
            isTrue,
            reason:
                'BatteryNotifier はアプリ待機時の省電力制御のため AppLifecycleListener を持たなければならない',
          );

          // paused または inactive 時にタイマーを停止していること
          expect(
            content.contains('_stopPeriodicTimer()') ||
                content.contains('_timer?.cancel()'),
            isTrue,
            reason: 'バックグラウンド移行時にポーリングタイマーを停止しなければならない',
          );

          // resumed 時にタイマーを再開していること
          expect(
            content.contains('_startPeriodicTimer()'),
            isTrue,
            reason: 'フォアグラウンド復帰時にタイマーを再開しなければならない',
          );
        },
      );

      test(
        '4. [自律パージ連携規約] LocalMatchRepository に保留コマンド削除機構があり、sync_provider.dart で同期後に自動クリーンアップされること',
        () {
          final localRepoFile = File(
            'lib/shared/infrastructure/repository/local_match_repository.dart',
          );
          final syncProviderFile = File(
            'lib/features/tournament/presentation/operate/providers/sync_provider.dart',
          );

          expect(localRepoFile.existsSync(), isTrue);
          expect(syncProviderFile.existsSync(), isTrue);

          final repoContent = localRepoFile.readAsStringSync();
          final syncContent = syncProviderFile.readAsStringSync();

          // local_match_repository.dart に deletePendingCommandsForMatches が定義されていること
          expect(
            repoContent.contains('deletePendingCommandsForMatches'),
            isTrue,
            reason:
                'LocalMatchRepository は保留コマンドを安全に一括削除する deletePendingCommandsForMatches を提供しなければならない',
          );

          // sync_provider.dart で saveMatchesBulk の後に deletePendingCommandsForMatches を呼んでいること
          expect(
            syncContent.contains('deletePendingCommandsForMatches'),
            isTrue,
            reason: 'sync_provider.dart は同期完了試合の保留コマンドを自動的にクリーンアップしなければならない',
          );
        },
      );

      test(
        '5. [Staleコマンド自律消化規約] SyncEngine で ConflictException 発生時にクラウドのバージョンが新しければ自律消化すること',
        () {
          final syncEngineFile = File(
            'lib/shared/infrastructure/repository/sync_engine.dart',
          );
          expect(syncEngineFile.existsSync(), isTrue);
          final content = syncEngineFile.readAsStringSync();

          expect(
            content.contains('ConflictException'),
            isTrue,
            reason: 'SyncEngine は ConflictException を適切にトラップしなければならない',
          );

          expect(
            content.contains('remoteMatch.version >= match.version'),
            isTrue,
            reason: 'SyncEngine はクラウド側のバージョンが先行している場合に Stale コマンドと判定しなければならない',
          );

          expect(
            content.contains('Staleコマンドを自律パージします'),
            isTrue,
            reason: 'Staleコマンドの自律パージログが記録され、正常消化（true）として扱われなければならない',
          );
        },
      );

      test(
        '6. [空Txn根絶規約] LocalMatchArchiveHelper でアーカイブが存在しない場合に不要な writeTxn がスキップされること',
        () {
          final archiveHelperFile = File(
            'lib/shared/infrastructure/repository/local_match_archive_helper.dart',
          );
          expect(archiveHelperFile.existsSync(), isTrue);
          final content = archiveHelperFile.readAsStringSync();

          // hotEventLimit以下の判定内で findFirst で存在チェックしていること
          expect(
            content.contains('hasArchive') && content.contains('findFirst()'),
            isTrue,
            reason:
                'LocalMatchArchiveHelper は通常試合で空テーブルに対する不要な writeTxn を防ぐため、findFirst() による先行存在確認を行わなければならない',
          );
        },
      );

      test(
        '7. [待機時タイマー完全沈黙規約] RenseikaiMasterTimerNotifier および DockTimerNotifier に AppLifecycleListener が配備されていること',
        () {
          final renseikaiTimerFile = File(
            'lib/features/tournament/presentation/operate/providers/renseikai_master_timer_provider.dart',
          );
          final dockTimerFile = File(
            'lib/features/tournament/presentation/providers/dock_timer_provider.dart',
          );

          expect(renseikaiTimerFile.existsSync(), isTrue);
          expect(dockTimerFile.existsSync(), isTrue);

          final renseikaiContent = renseikaiTimerFile.readAsStringSync();
          final dockContent = dockTimerFile.readAsStringSync();

          expect(
            renseikaiContent.contains('AppLifecycleListener('),
            isTrue,
            reason:
                'RenseikaiMasterTimerNotifier に AppLifecycleListener が配備されていなければならない',
          );
          expect(
            dockContent.contains('AppLifecycleListener('),
            isTrue,
            reason: 'DockTimerNotifier に AppLifecycleListener が配備されていなければならない',
          );
        },
      );

      test(
        '8. [タイマー破棄漏れ根絶規約] SyncEngine の dispose() で _debounceSyncTimer が確実に破棄されていること',
        () {
          final syncEngineFile = File(
            'lib/shared/infrastructure/repository/sync_engine.dart',
          );
          expect(syncEngineFile.existsSync(), isTrue);
          final content = syncEngineFile.readAsStringSync();

          expect(
            content.contains('_debounceSyncTimer?.cancel()'),
            isTrue,
            reason:
                'SyncEngine の dispose() で _debounceSyncTimer?.cancel() を呼ばなければならない',
          );
        },
      );

      test(
        '9. [Poison Pill防護規約] SyncEngine にリトライ回数上限超過による自律パージおよびペイロード破損保護が備わっていること',
        () {
          final syncEngineFile = File(
            'lib/shared/infrastructure/repository/sync_engine.dart',
          );
          expect(syncEngineFile.existsSync(), isTrue);
          final content = syncEngineFile.readAsStringSync();

          expect(
            content.contains('_retryCount >= 10'),
            isTrue,
            reason: 'SyncEngine は10回以上のリトライ失敗時に毒薬キュー化防止のため自律パージ機構を持たなければならない',
          );

          expect(
            content.contains('毒薬キュー化防止のため自律パージします'),
            isTrue,
            reason: 'SyncEngine は不正ペイロード検知時にキューから自律パージしなければならない',
          );
        },
      );

      test(
        '10. [ツイン永続化非同期I/O規約] TwinMatchPersistenceHelper で同期I/O（listSync, deleteSync, readAsStringSync）が存在しないこと',
        () {
          final twinFile = File(
            'lib/shared/infrastructure/persistence/twin_match_persistence_helper.dart',
          );
          expect(twinFile.existsSync(), isTrue);
          final content = twinFile.readAsStringSync();

          expect(
            content.contains('listSync('),
            isFalse,
            reason:
                'TwinMatchPersistenceHelper に同期 listSync() が残存してはならない。非同期 list() を使用すること。',
          );
          expect(
            content.contains('deleteSync('),
            isFalse,
            reason:
                'TwinMatchPersistenceHelper に同期 deleteSync() が残存してはならない。非同期 delete() を使用すること。',
          );
          expect(
            content.contains('readAsStringSync('),
            isFalse,
            reason:
                'TwinMatchPersistenceHelper に同期 readAsStringSync() が残存してはならない。非同期 readAsString() を使用すること。',
          );
        },
      );

      test(
        '11. [CQRS DI一貫性規約] ProjectionStore で FirebaseFirestore.instance 直接参照が存在せず、firestoreProvider 経由であること',
        () {
          final storeFile = File(
            'lib/shared/application/projections/projection_store.dart',
          );
          expect(storeFile.existsSync(), isTrue);
          final content = storeFile.readAsStringSync();

          expect(
            content.contains('FirebaseFirestore.instance'),
            isFalse,
            reason:
                'ProjectionStore で FirebaseFirestore.instance を直接参照してはならない。ref.read(firestoreProvider) を使用すること。',
          );
          expect(
            content.contains('firestoreProvider'),
            isTrue,
            reason: 'ProjectionStore は firestoreProvider を使用していなければならない',
          );
        },
      );
    },
  );
}
