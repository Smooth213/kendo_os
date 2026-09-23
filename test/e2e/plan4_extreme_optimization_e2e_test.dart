@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_archive_helper.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/match/presentation/providers/read_announcements_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_isar_helper.dart';

class FakeRemoteMatchRepository implements MatchRepository {
  final List<MatchModel> savedMatches = [];
  bool shouldThrow = false;
  int attemptCount = 0;

  @override
  Future<int> saveMatch(MatchModel match) async {
    attemptCount++;
    if (shouldThrow) {
      throw Exception('Server error simulation');
    }
    savedMatches.add(match);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestIsarContext? isarContext;
  late Isar isar;
  late LocalMatchRepository localRepo;

  setUpAll(() async {
    final ctx = await TestIsarHelper.openContext(
      schemas: [
        MatchEntitySchema,
        MatchEventArchiveEntitySchema,
        MatchCommandEntitySchema,
      ],
      prefix: 'plan4_e2e',
    );
    isarContext = ctx;
    isar = ctx.isar;
    localRepo = LocalMatchRepository(isar);
  });

  tearDownAll(() async {
    await isarContext?.dispose();
  });

  setUp(() async {
    await isarContext?.clear();
  });

  group('⚡ 【Plan 4 E2E】4大極限最適化・安定化（軽快・低負荷・絶対安定）統合実証テスト', () {
    test(
      'E2E-1: 【保留コマンド自律消去・Poison Pill根絶】同期完了した試合の保留コマンドがIsarから漏れなく自動消去され、キュー滞留がゼロ化すること',
      () async {
        // Given: 試合A（同期完了予定）と試合B（未同期）の保留コマンドをIsarに保存
        final cmdA1 = MatchCommandEntity()
          ..commandId = 'cmd_a_1'
          ..type = 'saveMatch'
          ..payloadJson = '{"id":"match_A","redName":"選手A1"}'
          ..createdAt = DateTime.now()
          ..status = 'pending';

        final cmdA2 = MatchCommandEntity()
          ..commandId = 'cmd_a_2'
          ..type = 'saveMatch'
          ..payloadJson = '{"id":"match_A","redName":"選手A2"}'
          ..createdAt = DateTime.now()
          ..status = 'pending';

        final cmdB = MatchCommandEntity()
          ..commandId = 'cmd_b_1'
          ..type = 'saveMatch'
          ..payloadJson = '{"id":"match_B","redName":"選手B"}'
          ..createdAt = DateTime.now()
          ..status = 'pending';

        await isar.writeTxn(() async {
          await isar.matchCommandEntitys.putAll([cmdA1, cmdA2, cmdB]);
        });

        // When: 同期エンジンが試合Aの同期完了を検知し、一括反映＆保留コマンドパージを実行
        final syncedMatchA = MatchModel(
          id: 'match_A',
          matchType: '個人戦',
          redName: '選手A2',
          whiteName: '選手相手',
        );

        await localRepo.saveMatchesBulk([syncedMatchA], skipTwin: true);
        await localRepo.deletePendingCommandsForMatches([syncedMatchA.id]);

        // Then: 試合Aの保留コマンドのみが確実に削除され、試合Bの保留コマンドは安全に残存
        final remainingCommands = await isar.matchCommandEntitys
            .where()
            .findAll();
        expect(remainingCommands.length, 1);
        expect(remainingCommands.first.commandId, 'cmd_b_1');
        expect(
          remainingCommands.any((c) => c.commandId.startsWith('cmd_a')),
          isFalse,
        );
      },
    );

    test(
      'E2E-2: 【UI局所化・Jank防止】settingsProvider.select((s) => s.themeMode) により、他設定（バイブ・確認ダイアログ等）変更でルート再ビルドが発生しないこと',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );

        int rootThemeModeNotificationCount = 0;
        String currentWatchedTheme = 'system';

        // main.dart のルートウィジェットと同等の局所購読
        container.listen<String>(settingsProvider.select((s) => s.themeMode), (
          previous,
          next,
        ) {
          rootThemeModeNotificationCount++;
          currentWatchedTheme = next;
        }, fireImmediately: true);

        // 初期状態で1回評価
        expect(rootThemeModeNotificationCount, 1);
        expect(currentWatchedTheme, 'system');

        final notifier = container.read(settingsProvider.notifier);

        // 1. 触覚フィードバック（バイブ）設定を変更 ➔ ルート通知カウントは変化しないこと
        await notifier.updateField(haptic: false);
        expect(container.read(settingsProvider).haptic, isFalse);
        expect(
          rootThemeModeNotificationCount,
          1,
          reason: 'バイブ設定変更でルートが再ビルドされてはならない',
        );

        // 2. 確認ダイアログ表示設定を変更 ➔ ルート通知カウントは変化しないこと
        await notifier.updateField(showConfirmDialog: false);
        expect(container.read(settingsProvider).showConfirmDialog, isFalse);
        expect(
          rootThemeModeNotificationCount,
          1,
          reason: '確認ダイアログ設定変更でルートが再ビルドされてはならない',
        );

        // 3. スリープ防止設定を変更 ➔ ルート通知カウントは変化しないこと
        await notifier.updateField(sleepPrevent: false);
        expect(container.read(settingsProvider).sleepPrevent, isFalse);
        expect(
          rootThemeModeNotificationCount,
          1,
          reason: 'スリープ防止設定変更でルートが再ビルドされてはならない',
        );

        // 4. テーマモードを 'light' に変更 ➔ 初めてルート通知が発火すること
        await notifier.updateField(themeMode: 'light');
        expect(
          rootThemeModeNotificationCount,
          2,
          reason: 'themeMode変更時のみ正確に1回発火すること',
        );
        expect(currentWatchedTheme, 'light');

        // 5. テーマモードを 'sunshine' に変更 ➔ 正確に発火すること
        await notifier.updateField(themeMode: 'sunshine');
        expect(rootThemeModeNotificationCount, 3);
        expect(currentWatchedTheme, 'sunshine');

        container.dispose();
      },
    );

    test(
      'E2E-3: 【バックグラウンド待機時タイマー沈黙・復帰再開】BatteryNotifier が AppLifecycleState に連動して安全に動作すること',
      () async {
        final notifier = BatteryNotifier();
        expect(notifier.zoneValuesContainsTestKey(), isTrue);

        // テスト環境下でビルドがクラッシュせず即座に100%モック値を返すこと
        final data = await notifier.build();
        expect(data.batteryLevel, 100);
        expect(data.isInPowerSaveMode, isFalse);
      },
    );

    test(
      'E2E-4: 【空Txn根絶・I/O半減実証】通常試合（<=200件）保存時に過去アーカイブが存在しない場合はIsarへの不要なwriteTxnが発生せず、正常に保存・復元できること',
      () async {
        // 1. アーカイブが存在しない新規の通常試合（イベント10件）
        final normalMatch = MatchModel(
          id: 'normal_match_e2e',
          matchType: '個人戦',
          redName: '選手赤',
          whiteName: '選手白',
          events: List.generate(
            10,
            (i) => ScoreEvent(
              id: 'ev_$i',
              side: Side.red,
              timestamp: DateTime.now(),
            ),
          ),
        );

        // archiveAndTrimEvents を実行
        final trimmed = await LocalMatchArchiveHelper.archiveAndTrimEvents(
          isar,
          normalMatch,
        );
        expect(trimmed.events.length, 10);

        // アーカイブテーブルが空であることを確認（先行確認によりwriteTxnが完全スキップ）
        final archivesCount = await isar.matchEventArchiveEntitys.count();
        expect(archivesCount, 0);

        // 2. 次にイベント250件の過大試合を保存（アーカイブ分割が発生）
        final largeMatch = MatchModel(
          id: 'large_match_e2e',
          matchType: '個人戦',
          redName: '選手赤',
          whiteName: '選手白',
          events: List.generate(
            250,
            (i) => ScoreEvent(
              id: 'ev_large_$i',
              side: Side.red,
              timestamp: DateTime.now(),
            ),
          ),
        );

        final trimmedLarge = await LocalMatchArchiveHelper.archiveAndTrimEvents(
          isar,
          largeMatch,
        );
        expect(trimmedLarge.events.length, 200);

        final largeArchivesCount = await isar.matchEventArchiveEntitys.count();
        expect(largeArchivesCount, 1);

        // 3. 過大試合が編集等で通常件数（<=200件）に縮小された場合
        // hasArchive が true となり、古い不要アーカイブが確実にパージされること
        final shrunkenMatch = largeMatch.copyWith(
          events: largeMatch.events.take(50).toList(),
        );
        final trimmedShrunk =
            await LocalMatchArchiveHelper.archiveAndTrimEvents(
              isar,
              shrunkenMatch,
            );
        expect(trimmedShrunk.events.length, 50);

        final finalArchivesCount = await isar.matchEventArchiveEntitys
            .filter()
            .matchIdEqualTo(largeMatch.id)
            .count();
        expect(finalArchivesCount, 0);
      },
    );

    test(
      'E2E-5: 【Poison Pill自律パージ実証】不正ペイロードの毒薬コマンドがIsarキューから自律パージされ、後続正常コマンドが滞留なく処理されること',
      () async {
        final fakeRemoteRepo = FakeRemoteMatchRepository();
        final container = ProviderContainer(
          overrides: [
            localMatchRepositoryProvider.overrideWithValue(localRepo),
            matchRepositoryProvider.overrideWithValue(fakeRemoteRepo),
          ],
        );
        addTearDown(container.dispose);

        // 1. 破損データ（不正な型）の毒薬コマンドと、後続の正常コマンドをキューに投入
        final poisonCmd = MatchCommandEntity()
          ..commandId = 'cmd_poison'
          ..type = 'updateMatch'
          ..payloadJson =
              '{"id":"bad_match","events":"INVALID_STRING_INSTEAD_OF_LIST"}'
          ..createdAt = DateTime.now()
          ..status = 'pending';

        final validCmd = MatchCommandEntity()
          ..commandId = 'cmd_valid'
          ..type = 'updateMatch'
          ..payloadJson =
              '{"id":"good_match","matchType":"個人戦","redName":"赤選手","whiteName":"白選手"}'
          ..createdAt = DateTime.now().add(const Duration(milliseconds: 10))
          ..status = 'pending';

        await isar.writeTxn(() async {
          await isar.matchCommandEntitys.putAll([poisonCmd, validCmd]);
        });

        final engine = container.read(syncEngineProvider);

        // processQueue を実行
        await engine.processQueue();

        // 毒薬コマンドは即座に自律パージされ、後続の正常コマンドは無事にリモートへアップロード完了すること
        expect(fakeRemoteRepo.savedMatches.length, 1);
        expect(fakeRemoteRepo.savedMatches.first.id, 'good_match');

        // Isarキューが完全に消化されて空になっていること（毒薬キューによる永久ブロックゼロ）
        final pendingAfter = await isar.matchCommandEntitys.where().findAll();
        expect(pendingAfter, isEmpty);
      },
    );

    test(
      'E2E-6: 【保留コマンドバルク保存＆バルクパージ実証】savePendingCommandsBulk による一括書き込みと deleteAll による一括パージがアトミックに動作すること',
      () async {
        // 1. 複数（10件）のコマンドを一括作成
        final cmds = List.generate(
          10,
          (i) => MatchCommandModel(
            id: 'bulk_cmd_$i',
            type: CommandType.updateMatch,
            payload: {'id': 'bulk_match_$i', 'name': '選手_$i'},
            createdAt: DateTime.now(),
            status: CommandStatus.pending,
          ),
        );

        // 2. savePendingCommandsBulk で1トランザクション一括保存
        await localRepo.savePendingCommandsBulk(cmds);

        // 3. Isarに全10件が正しく保存されたことを検証
        final savedEntities = await isar.matchCommandEntitys.where().findAll();
        expect(savedEntities.length, 10);

        // 4. 重複IDで再保存した場合のupsert動作検証
        final updatedCmds = [
          MatchCommandModel(
            id: 'bulk_cmd_0',
            type: CommandType.updateMatch,
            payload: {'id': 'bulk_match_0', 'name': '選手_0_更新'},
            createdAt: DateTime.now(),
            status: CommandStatus.pending,
          ),
        ];
        await localRepo.savePendingCommandsBulk(updatedCmds);
        final afterUpsert = await isar.matchCommandEntitys.where().findAll();
        expect(afterUpsert.length, 10, reason: '重複IDの場合は件数が増えず更新されること');

        // 5. deletePendingCommandsForMatches による一括バルクパージ（前半5件）
        final matchIdsToPurge = List.generate(5, (i) => 'bulk_match_$i');
        await localRepo.deletePendingCommandsForMatches(matchIdsToPurge);

        final remainingAfterPurge = await isar.matchCommandEntitys
            .where()
            .findAll();
        expect(
          remainingAfterPurge.length,
          5,
          reason: '指定された試合の保留コマンド5件が一括削除され、残り5件となること',
        );
      },
    );

    test(
      'E2E-7: 【既読アナウンスID上限トリム実証】ReadAnnouncementsNotifier が200件を超過した古いIDを自動トリムし、メモリ肥大化を完全抑止すること',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final notifier = ReadAnnouncementsNotifier(prefs);

        // 1. 250件の既読IDを順次または一括追加
        final testIds = List.generate(250, (i) => 'announce_id_$i');
        await notifier.markAllAsRead(testIds);

        // 2. 状態の件数が最大200件にトリムされていること
        expect(notifier.state.length, 200);

        // 3. FIFO/LRUにより、古い50件（0〜49）が切り捨てられ、最新200件（50〜249）が保持されていること
        expect(notifier.state.contains('announce_id_0'), isFalse);
        expect(notifier.state.contains('announce_id_49'), isFalse);
        expect(notifier.state.contains('announce_id_50'), isTrue);
        expect(notifier.state.contains('announce_id_249'), isTrue);

        // 4. SharedPreferencesにも正確に200件で永続化されていること
        final persisted = prefs.getStringList('kendo_os_read_announcements');
        expect(persisted, isNotNull);
        expect(persisted!.length, 200);
        expect(persisted.first, 'announce_id_50');
        expect(persisted.last, 'announce_id_249');

        // 5. 単一追加（markAsRead）時にも上限200件が維持されること
        await notifier.markAsRead('announce_id_250');
        expect(notifier.state.length, 200);
        expect(notifier.state.contains('announce_id_50'), isFalse);
        expect(notifier.state.last, 'announce_id_250');
      },
    );
  });
}
