import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/auth/application/user_data_cloud_sync_manager.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_history_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_name_history_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';

class _FakePlayerRepository implements PlayerRepository {
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

  late FakeFirebaseFirestore fakeFirestore;
  late SharedPreferences prefs;
  late ProviderContainer container;
  const testUid = 'google-user-12345';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeFirestore = FakeFirebaseFirestore();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        playerRepositoryProvider.overrideWithValue(_FakePlayerRepository()),
        userDataCloudSyncManagerProvider.overrideWith((ref) {
          return UserDataCloudSyncManager(
            ref,
            firestore: fakeFirestore,
            overrideUid: testUid,
          );
        }),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('UserDataCloudSyncManager 4大機能同期テスト', () {
    test('1. アプリ個人設定 (preferences) のクラウド保存と同期反映', () async {
      final syncManager = container.read(userDataCloudSyncManagerProvider);

      // クラウドに設定を事前格納
      await fakeFirestore
          .collection('users')
          .doc(testUid)
          .collection('settings')
          .doc('preferences')
          .set({
            'themeMode': 'dark',
            'audioFeedbackMode': 'voice',
            'enableLiquidGlass': false,
            'leftHanded': true,
            'confirmBehavior': 'single',
            'haptic': false,
          });

      // 同期を実行
      await syncManager.syncPreferencesFromCloud(testUid);

      // SettingsProviderのStateがクラウド設定に更新されていることを検証
      final settings = container.read(settingsProvider);
      expect(settings.themeMode, 'dark');
      expect(settings.audioFeedbackMode, 'voice');
      expect(settings.enableLiquidGlass, false);
      expect(settings.leftHanded, true);
      expect(settings.confirmBehavior, 'single');
      expect(settings.haptic, false);
    });

    test('2. 道場通信ルーム履歴 (dojo_history) のスマートマージとプッシュ', () async {
      final syncManager = container.read(userDataCloudSyncManagerProvider);

      // ローカル端末で履歴を追加
      await container
          .read(dojoRoomHistoryProvider.notifier)
          .addHistory('ROOM-LOCAL-1');
      await container
          .read(dojoRoomHistoryProvider.notifier)
          .addHistory('ROOM-SHARED');

      // 別端末からクラウドに別の履歴が保存されたと仮定
      await fakeFirestore
          .collection('users')
          .doc(testUid)
          .collection('settings')
          .doc('dojo_history')
          .set({
            'history': ['ROOM-CLOUD-1', 'ROOM-SHARED'],
          });

      // クラウド同期を実行（スマートマージ）
      await syncManager.syncDojoHistoryFromCloud(testUid);

      final history = container.read(dojoRoomHistoryProvider);
      // 重複排除され、ローカルとクラウドの双方が含まれていること
      expect(history.contains('ROOM-LOCAL-1'), isTrue);
      expect(history.contains('ROOM-SHARED'), isTrue);
      expect(history.contains('ROOM-CLOUD-1'), isTrue);
      expect(history.length, 3);
    });

    test('3. チーム名・対戦相手入力履歴 (input_history) のスマートマージとプッシュ', () async {
      final syncManager = container.read(userDataCloudSyncManagerProvider);

      // ローカル端末で履歴を追加
      await container
          .read(teamNameHistoryProvider.notifier)
          .addHistory('大阪洗心館');

      // 別端末からクラウドに別の履歴が保存されたと仮定
      await fakeFirestore
          .collection('users')
          .doc(testUid)
          .collection('settings')
          .doc('input_history')
          .set({
            'teamNames': ['東京剣友会', '京都修道館'],
          });

      // クラウド同期を実行（スマートマージ）
      await syncManager.syncInputHistoryFromCloud(testUid);

      final teamNames = container.read(teamNameHistoryProvider);
      expect(teamNames.contains('大阪洗心館'), isTrue);
      expect(teamNames.contains('東京剣友会'), isTrue);
      expect(teamNames.contains('京都修道館'), isTrue);
      expect(teamNames.length, 3);
    });

    test('4. タイマー設定 (timer_preferences) の保存と復元', () async {
      final syncManager = container.read(userDataCloudSyncManagerProvider);

      // クラウドにタイマー初期秒数 (240秒 = 4分) を格納
      await fakeFirestore
          .collection('users')
          .doc(testUid)
          .collection('settings')
          .doc('timer_preferences')
          .set({'initialSeconds': 240});

      // 同期を実行
      await syncManager.syncTimerPreferencesFromCloud(testUid);

      final timerState = container.read(dockTimerProvider);
      expect(timerState.initialSeconds, 240);
      expect(timerState.remainingSeconds, 240);
    });

    test('5. 未連携（overrideUid = null）時は例外なく安全にスキップされること', () async {
      final unlinkedContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          playerRepositoryProvider.overrideWithValue(_FakePlayerRepository()),
          userDataCloudSyncManagerProvider.overrideWith((ref) {
            return UserDataCloudSyncManager(
              ref,
              firestore: fakeFirestore,
              overrideUid: null, // 未連携
            );
          }),
        ],
      );

      final unlinkedSyncManager = unlinkedContainer.read(
        userDataCloudSyncManagerProvider,
      );

      // 全体同期を実行しても例外は発生しない
      await expectLater(unlinkedSyncManager.syncAll(), completes);

      unlinkedContainer.dispose();
    });
  });
}
