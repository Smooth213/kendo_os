import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/models/score_event.dart';
import 'package:kendo_os/models/match_model.dart';
import 'package:kendo_os/providers/match_list_provider.dart';
import 'package:kendo_os/providers/match_view_state_provider.dart';
import 'package:kendo_os/providers/sync_provider.dart';
import 'package:kendo_os/providers/match_command_provider.dart';
import 'package:kendo_os/providers/settings_provider.dart';
import 'package:kendo_os/models/settings_model.dart';

// 設定プロバイダのモック
class MockSettingsNotifier extends SettingsNotifier {
  final SettingsModel initialSettings;
  MockSettingsNotifier(this.initialSettings);
  @override
  SettingsModel build() => initialSettings;
}

void main() {
  group('MatchViewStateProvider ユニットテスト', () {
    
    // テスト用の共通コンテナ作成
    ProviderContainer createContainer(MatchModel match) {
      return ProviderContainer(
        overrides: [
          // 1. 試合リストをテストデータで上書き
          matchListProvider.overrideWith((ref) => [match]),
          
          // 2. 同期ステータスを「同期済み」で固定
          syncStatusProvider.overrideWith((ref) => SyncStatus.synced),
          
          // 3. 処理中フラグを「false」で固定
          isMatchCommandProcessingProvider.overrideWith((ref) => false),
          
          // 4. 設定（ロック状態など）をデフォルト値で上書き
          settingsProvider.overrideWith(() => MockSettingsNotifier(const SettingsModel(isLocked: false))),
          
          // 5. Firebase依存を回避するため、テスト用のユーザーIDを固定
          matchViewStateUserIdProvider.overrideWith((ref) => 'test_user'),
        ],
      );
    }

    test('【正常系】初期状態(0-0)で、スコアとテキストが正しく表示されるか', () {
      final match = MatchModel(
        id: 'test_001',
        matchType: '先鋒',
        redName: '赤選手',
        whiteName: '白選手',
        redScore: 0,
        whiteScore: 0,
        status: 'in_progress',
      );

      final container = createContainer(match);
      final viewState = container.read(matchViewStateProvider('test_001'));

      expect(viewState.scoreText, '0 - 0');
      expect(viewState.statusText, '試合中');
      expect(viewState.winner, isNull);
      expect(viewState.canUndo, isFalse); // イベントがないので取り消し不可
    });

    test('【正常系】赤が2本勝ち(2-0)したとき、勝利判定が red になるか', () {
      final match = MatchModel(
        id: 'test_002',
        matchType: '中堅',
        redName: '赤選手',
        whiteName: '白選手',
        redScore: 2,
        whiteScore: 0,
        status: 'finished', // 試合終了
      );

      final container = createContainer(match);
      final viewState = container.read(matchViewStateProvider('test_002'));

      expect(viewState.scoreText, '2 - 0');
      expect(viewState.winner, 'red');
      expect(viewState.statusText, '終了');
    });

    test('【正常系】イベント履歴から「直前イベント」のテキストが正しく生成されるか', () {
      final now = DateTime.now();
      final match = MatchModel(
        id: 'test_003',
        matchType: '大将',
        redName: '赤選手',
        whiteName: '白選手',
        redScore: 1,
        whiteScore: 0,
        events: [
          ScoreEvent(
            id: 'e1',
            side: Side.red,
            type: PointType.men,
            timestamp: now,
          ),
        ],
      );

      final container = createContainer(match);
      final viewState = container.read(matchViewStateProvider('test_003'));

      expect(viewState.lastEventText, '赤 メン');
      expect(viewState.canUndo, isTrue); // イベントがあるので取り消し可能
    });

    test('【境界値】延長戦の判定が正しく反映されるか', () {
      final match = MatchModel(
        id: 'test_004',
        matchType: '先鋒',
        redName: '赤選手',
        whiteName: '白選手',
        note: '延長', // 延長フラグ
      );

      final container = createContainer(match);
      final viewState = container.read(matchViewStateProvider('test_004'));

      expect(viewState.isEncho, isTrue);
      expect(viewState.statusText, '延長');
    });

    test('【シナリオ】オフライン時に「未送信あり」となり、オンライン復帰で「同期済み」に変わるか', () {
      final match = MatchModel(id: 'sync_test', matchType: '大将', redName: '赤', whiteName: '白');
      final mockSyncStatus = StateProvider<SyncStatus>((ref) => SyncStatus.pending);

      // 1. 最初はオフライン状態をシミュレート
      final container = ProviderContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => [match]),
          // 通信状態を動的変更可能な StateProvider に連動させる
          syncStatusProvider.overrideWith((ref) => ref.watch(mockSyncStatus)),
          // 必須の依存関係をモック
          isMatchCommandProcessingProvider.overrideWith((ref) => false),
          settingsProvider.overrideWith(() => MockSettingsNotifier(const SettingsModel(isLocked: false))),
          matchViewStateUserIdProvider.overrideWith((ref) => 'test_user'),
        ],
      );

      var viewState = container.read(matchViewStateProvider('sync_test'));
      expect(viewState.syncStatus, SyncStatus.pending, reason: 'オフライン時はpendingであるべき');

      // 2. オンラインに復帰した状態をシミュレート (StateProviderの値を更新)
      container.read(mockSyncStatus.notifier).state = SyncStatus.synced;

      viewState = container.read(matchViewStateProvider('sync_test'));
      expect(viewState.syncStatus, SyncStatus.synced, reason: 'オンライン復帰後はsyncedになるべき');
    });

    test('【異常系】競合が発生した際に ViewState が正しく「未送信あり」を維持するか', () {
      final match = MatchModel(id: 'conflict_test', matchType: '大将', redName: '赤', whiteName: '白');

      final container = ProviderContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => [match]),
          // 競合状態（送信が止まっている状態）をシミュレート
          syncStatusProvider.overrideWith((ref) => SyncStatus.pending),
          // 必須の依存関係をモック
          isMatchCommandProcessingProvider.overrideWith((ref) => false),
          settingsProvider.overrideWith(() => MockSettingsNotifier(const SettingsModel(isLocked: false))),
          matchViewStateUserIdProvider.overrideWith((ref) => 'test_user'),
        ],
      );

      final viewState = container.read(matchViewStateProvider('conflict_test'));
      
      // UIが「未送信あり（オレンジ色）」を出すためのフラグが立っているか
      expect(viewState.syncStatus, SyncStatus.pending);
    });

    test('【境界値】不戦勝(フセン)が入力された際、即座に「2-0」として表示されるか', () {
      final now = DateTime.now();
      final match = MatchModel(
        id: 'fusen_test',
        matchType: '先鋒',
        redName: '赤選手',
        whiteName: '白(欠員)',
        redScore: 2, // エンジンが計算してセットしたと想定
        whiteScore: 0,
        events: [
          ScoreEvent(id: 'e1', side: Side.red, type: PointType.fusen, timestamp: now),
        ],
      );

      final container = createContainer(match);
      final viewState = container.read(matchViewStateProvider('fusen_test'));

      expect(viewState.scoreText, '2 - 0');
      // 不戦勝のマーク(◯)が正しく表示ロジックに渡るかは Engine のテストで保証されるが、
      // ViewStateとしてもスコアが反映されていることを確認
      expect(viewState.redScore, 2);
    });

    test('【団体戦】勝数・本数が完全に並んだ時、isTie が true になり代表戦を促せるか', () {
      // 団体戦の試合リストをシミュレート
      final match1 = MatchModel(id: 'm1', matchType: '先鋒', redName: '赤1', whiteName: '白1', groupName: 'team_A', redScore: 1, whiteScore: 0, status: 'approved'); // 赤勝ち
      final match2 = MatchModel(id: 'm2', matchType: '次鋒', redName: '赤2', whiteName: '白2', groupName: 'team_A', redScore: 0, whiteScore: 1, status: 'approved'); // 白勝ち
      final currentMatch = MatchModel(id: 'm3', matchType: '中堅', redName: '赤3', whiteName: '白3', groupName: 'team_A', redScore: 0, whiteScore: 0, status: 'approved'); // 引き分け

      final container = ProviderContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => [match1, match2, currentMatch]),
          // groupMatchStatusProvider は override せず、実際のロジックに計算させる
          syncStatusProvider.overrideWith((ref) => SyncStatus.synced),
          isMatchCommandProcessingProvider.overrideWith((ref) => false),
          settingsProvider.overrideWith(() => MockSettingsNotifier(const SettingsModel(isLocked: false))),
          matchViewStateUserIdProvider.overrideWith((ref) => 'test_user'),
        ],
      );

      final viewState = container.read(matchViewStateProvider('m3'));
      
      expect(viewState.isTie, isTrue, reason: '勝数1-1, 本数1-1なのでタイ判定になるべき');
      expect(viewState.isAllDone, isTrue);
    });

    test('【代表戦】1本勝負で勝敗がついたとき、winner が正しく判定されるか', () {
      final match = MatchModel(
        id: 'rep_match',
        matchType: '代表戦',
        redName: '赤代表',
        whiteName: '白代表',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
      );

      final container = createContainer(match);
      final viewState = container.read(matchViewStateProvider('rep_match'));

      expect(viewState.winner, 'red');
      expect(viewState.scoreText, '1 - 0');
    });

    test('【特殊】判定(Hantei)で決着した際、ステータスや勝敗が正しく反映されるか', () {
      final now = DateTime.now();
      final match = MatchModel(
        id: 'hantei_test',
        matchType: '大将',
        redName: '赤選手',
        whiteName: '白選手',
        redScore: 1, // 判定勝ちを1本としてカウントする運用を想定
        whiteScore: 0,
        status: 'finished',
        events: [
          ScoreEvent(
            id: 'h1',
            side: Side.red,
            type: PointType.hantei, // 判定イベント
            timestamp: now,
          ),
        ],
      );

      final container = createContainer(match);
      final viewState = container.read(matchViewStateProvider('hantei_test'));

      // ViewStateとしては winner と scoreText が正しければOK
      expect(viewState.winner, 'red');
      expect(viewState.scoreText, '1 - 0');
      expect(viewState.lastEventText, contains('判定')); // 拡張機能で「判定」と出るか
    });
  });
}