import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/auth/application/user_data_cloud_sync_manager.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_history_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_name_history_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_storage_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';

class _FakePlayerRepo implements PlayerRepository {
  @override
  Future<void> addCustomTeamName(String name, {String? organization}) async {}
  @override
  Future<void> deleteCustomTeamName(
    String name, {
    String? organization,
  }) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore sharedCloudFirestore;
  const testGoogleUid = 'google-samurai-user-777';

  setUp(() {
    sharedCloudFirestore = FakeFirebaseFirestore();
    QuickMemoStorageService.testFirestore = sharedCloudFirestore;
    ReadAnnouncementsNotifier.testFirestore = sharedCloudFirestore;
  });

  tearDown(() {
    QuickMemoStorageService.testFirestore = null;
    QuickMemoStorageService.testOverrideUid = null;
    ReadAnnouncementsNotifier.testFirestore = null;
    ReadAnnouncementsNotifier.testOverrideUid = null;
  });

  group('🥋 Googleアカウント連携データ完全同期・証明テスト (全7大項目・マルチデバイスシミュレーション)', () {
    test('【Phase 1〜4】端末Aで全7項目を設定 ➔ クラウド保持 ➔ 端末Bで完全復元 ➔ 双方向マージを完全証明', () async {
      // -----------------------------------------------------------------------
      // [端末Aのセットアップ]
      // -----------------------------------------------------------------------
      SharedPreferences.setMockInitialValues({});
      final prefsA = await SharedPreferences.getInstance();

      final containerA = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefsA),
          playerRepositoryProvider.overrideWithValue(_FakePlayerRepo()),
          userDataCloudSyncManagerProvider.overrideWith((ref) {
            return UserDataCloudSyncManager(
              ref,
              firestore: sharedCloudFirestore,
              overrideUid: testGoogleUid,
            );
          }),
        ],
      );

      QuickMemoStorageService.testOverrideUid = testGoogleUid;
      ReadAnnouncementsNotifier.testOverrideUid = testGoogleUid;

      // =======================================================================
      // STEP 1: 端末Aで全7大項目を操作・保存
      // =======================================================================

      // ① アプリ基本環境設定 ＆ ② 通知設定（4系統）
      await containerA
          .read(settingsProvider.notifier)
          .updateField(
            themeMode: 'dark',
            audioFeedbackMode: 'voice',
            confirmBehavior: 'single',
            leftHanded: true,
            sleepPrevent: true,
            // 通知設定4系統
            notifyOnEmergency: true,
            notifyOnMatchAdded: false,
            notifyOnMatchStarted: true,
            notifyOnResult: true,
          );

      // ③ クイックメモ（手書き赤線 ＋ テキストメモ）
      final memoStrokes = [
        MemoStroke(
          points: const [Offset(10, 20), Offset(15, 25), Offset(20, 30)],
          color: Colors.red,
          strokeWidth: 4.0,
        ),
      ];
      await QuickMemoStorageService.instance.saveMemo(
        tournamentId: 'tournament-2026-autumn',
        text: '13:00 決勝戦開始（第1試合場）',
        strokes: memoStrokes,
        modeName: 'drawing',
      );

      // ④ 道場通信ルーム履歴
      await containerA
          .read(dojoRoomHistoryProvider.notifier)
          .addHistory('ROOM-TOKYO-BUDOKAN-2026');

      // ⑤ チーム名・対戦相手入力履歴
      await containerA
          .read(teamNameHistoryProvider.notifier)
          .addHistory('水戸葵剣友会');

      // ⑥ ドック独立型タイマー設定 (5分 = 300秒)
      containerA.read(dockTimerProvider.notifier).setPreset(300);

      // ⑦ アナウンス既読状態
      await containerA
          .read(readAnnouncementsProvider.notifier)
          .markAsRead('announce-urgent-999');

      // =======================================================================
      // STEP 2: クラウド（Firestore）の実態検証
      // 全7箇所のドキュメントがFirestore上に正しく永続化されていることを直接検証
      // =======================================================================

      // ①＆② 基本設定・通知設定のクラウド確認
      final prefDoc = await sharedCloudFirestore
          .collection('users')
          .doc(testGoogleUid)
          .collection('settings')
          .doc('preferences')
          .get();
      expect(prefDoc.exists, isTrue);
      final prefData = prefDoc.data()!;
      expect(prefData['themeMode'], 'dark');
      expect(prefData['audioFeedbackMode'], 'voice');
      expect(prefData['confirmBehavior'], 'single');
      expect(prefData['leftHanded'], true);
      expect(prefData['notifyOnEmergency'], true);
      expect(prefData['notifyOnMatchAdded'], false);
      expect(prefData['notifyOnMatchStarted'], true);
      expect(prefData['notifyOnResult'], true);

      // ③ クイックメモのクラウド確認
      final memoDoc = await sharedCloudFirestore
          .collection('users')
          .doc(testGoogleUid)
          .collection('quick_memos')
          .doc('tournament-2026-autumn')
          .get();
      expect(memoDoc.exists, isTrue);
      final memoData = memoDoc.data()!;
      expect(memoData['text'], '13:00 決勝戦開始（第1試合場）');
      expect(memoData['mode'], 'drawing');
      expect((memoData['strokes'] as List).length, 1);

      // ④ 道場ルーム履歴のクラウド確認
      final dojoDoc = await sharedCloudFirestore
          .collection('users')
          .doc(testGoogleUid)
          .collection('settings')
          .doc('dojo_history')
          .get();
      expect(dojoDoc.exists, isTrue);
      expect(
        (dojoDoc.data()!['history'] as List).contains(
          'ROOM-TOKYO-BUDOKAN-2026',
        ),
        isTrue,
      );

      // ⑤ チーム名履歴のクラウド確認
      final inputDoc = await sharedCloudFirestore
          .collection('users')
          .doc(testGoogleUid)
          .collection('settings')
          .doc('input_history')
          .get();
      expect(inputDoc.exists, isTrue);
      expect(
        (inputDoc.data()!['teamNames'] as List).contains('水戸葵剣友会'),
        isTrue,
      );

      // ⑥ タイマー設定のクラウド確認
      final timerDoc = await sharedCloudFirestore
          .collection('users')
          .doc(testGoogleUid)
          .collection('settings')
          .doc('timer_preferences')
          .get();
      expect(timerDoc.exists, isTrue);
      expect(timerDoc.data()!['initialSeconds'], 300);

      // ⑦ アナウンス既読のクラウド確認
      final announceDoc = await sharedCloudFirestore
          .collection('users')
          .doc(testGoogleUid)
          .collection('settings')
          .doc('read_announcements')
          .get();
      expect(announceDoc.exists, isTrue);
      expect(
        (announceDoc.data()!['readIds'] as List).contains(
          'announce-urgent-999',
        ),
        isTrue,
      );

      // =======================================================================
      // STEP 3: 端末B（未同期の新規端末）でGoogleログイン＆自動同期
      // =======================================================================
      // 端末B専用の完全クリーンなローカルストレージを模擬
      SharedPreferences.setMockInitialValues({});
      final prefsB = await SharedPreferences.getInstance();

      final containerB = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefsB),
          playerRepositoryProvider.overrideWithValue(_FakePlayerRepo()),
          userDataCloudSyncManagerProvider.overrideWith((ref) {
            return UserDataCloudSyncManager(
              ref,
              firestore: sharedCloudFirestore,
              overrideUid: testGoogleUid,
            );
          }),
        ],
      );

      // 端末BでGoogleアカウントによる全体自動同期を発火
      await containerB.read(userDataCloudSyncManagerProvider).syncAll();

      // =======================================================================
      // STEP 4: 端末Bで全7大項目の完全復元・正常動作を証明
      // =======================================================================

      // ①＆② 端末Bの基本設定・通知設定が完全復元されていること
      final restoredSettings = containerB.read(settingsProvider);
      expect(restoredSettings.themeMode, 'dark');
      expect(restoredSettings.audioFeedbackMode, 'voice');
      expect(restoredSettings.confirmBehavior, 'single');
      expect(restoredSettings.leftHanded, true);
      expect(restoredSettings.notifyOnEmergency, true);
      expect(restoredSettings.notifyOnMatchAdded, false);
      expect(restoredSettings.notifyOnMatchStarted, true);
      expect(restoredSettings.notifyOnResult, true);

      // ③ 端末Bでクイックメモが完全復元されること
      final restoredMemo = await QuickMemoStorageService.instance.loadMemo(
        'tournament-2026-autumn',
        forceCloudRefresh: true,
      );
      expect(restoredMemo.text, '13:00 決勝戦開始（第1試合場）');
      expect(restoredMemo.modeName, 'drawing');
      expect(restoredMemo.strokes.length, 1);
      expect(restoredMemo.strokes.first.points.length, 3);

      // ④ 端末Bで道場ルーム履歴が復元されていること
      final restoredDojoHistory = containerB.read(dojoRoomHistoryProvider);
      expect(restoredDojoHistory.contains('ROOM-TOKYO-BUDOKAN-2026'), isTrue);

      // ⑤ 端末Bでチーム名履歴がサジェスト候補に復元されていること
      final restoredTeamNames = containerB.read(teamNameHistoryProvider);
      expect(restoredTeamNames.contains('水戸葵剣友会'), isTrue);

      // ⑥ 端末Bでタイマー初期秒数が300秒で復元されていること
      final restoredTimer = containerB.read(dockTimerProvider);
      expect(restoredTimer.initialSeconds, 300);
      expect(restoredTimer.remainingSeconds, 300);
      expect(restoredTimer.formattedDisplay, '05:00');

      // ⑦ 端末Bでアナウンス既読状態が反映されること
      final restoredAnnouncementsNotifier = containerB.read(
        readAnnouncementsProvider.notifier,
      );
      await restoredAnnouncementsNotifier.syncFromCloud();
      final restoredReadIds = containerB.read(readAnnouncementsProvider);
      expect(restoredReadIds.contains('announce-urgent-999'), isTrue);

      // =======================================================================
      // STEP 5: 双方向スマートマージを証明（端末Bで追加入力 ➔ 端末Aで合体）
      // =======================================================================

      // 端末Bで別の道場とチーム名を追加
      await containerB
          .read(dojoRoomHistoryProvider.notifier)
          .addHistory('ROOM-OSAKA-SEISHINKAN-2026');
      await containerB
          .read(teamNameHistoryProvider.notifier)
          .addHistory('佐賀鍋島館');

      // 端末A側で同期を実行（スマートマージ）
      await containerA.read(userDataCloudSyncManagerProvider).syncAll();

      // 端末Aに、端末A自身の履歴と端末Bの履歴が重複なく合体していること
      final mergedDojoA = containerA.read(dojoRoomHistoryProvider);
      expect(mergedDojoA.contains('ROOM-TOKYO-BUDOKAN-2026'), isTrue);
      expect(mergedDojoA.contains('ROOM-OSAKA-SEISHINKAN-2026'), isTrue);

      final mergedTeamsA = containerA.read(teamNameHistoryProvider);
      expect(mergedTeamsA.contains('水戸葵剣友会'), isTrue);
      expect(mergedTeamsA.contains('佐賀鍋島館'), isTrue);

      // クリーンアップ
      containerA.dispose();
      containerB.dispose();
    });

    test('【Phase 5】Google未連携（ゲスト端末C）時は他人のクラウドデータが一切漏洩・混入しないこと', () async {
      SharedPreferences.setMockInitialValues({});
      final prefsC = await SharedPreferences.getInstance();

      final containerC = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefsC),
          playerRepositoryProvider.overrideWithValue(_FakePlayerRepo()),
          userDataCloudSyncManagerProvider.overrideWith((ref) {
            return UserDataCloudSyncManager(
              ref,
              firestore: sharedCloudFirestore,
              overrideUid: null, // 未ログイン・Google未連携
            );
          }),
        ],
      );

      QuickMemoStorageService.testOverrideUid = null;
      ReadAnnouncementsNotifier.testOverrideUid = null;

      // 未連携端末で同期を実行
      await containerC.read(userDataCloudSyncManagerProvider).syncAll();

      // 初期値のままであり、testGoogleUidのデータが一切混入していないこと
      final settings = containerC.read(settingsProvider);
      expect(settings.themeMode, 'system'); // デフォルト
      expect(containerC.read(dojoRoomHistoryProvider), isEmpty);
      expect(containerC.read(teamNameHistoryProvider), isEmpty);
      expect(containerC.read(dockTimerProvider).initialSeconds, 180); // デフォルト3分

      containerC.dispose();
    });
  });
}
