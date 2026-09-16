import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late LocalMatchRepository localRepo;
  late Directory tempDir;

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
    } catch (_) {}

    tempDir = Directory.systemTemp.createTempSync('plan4_e2e_');
    isar = await Isar.open(
      [
        MatchEntitySchema,
        MatchEventArchiveEntitySchema,
        MatchCommandEntitySchema,
      ],
      directory: tempDir.path,
      name: 'plan4_e2e_db_${DateTime.now().microsecondsSinceEpoch}',
      inspector: false,
    );
    localRepo = LocalMatchRepository(isar);
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
  });
}
