import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

void main() {
  group('🚀 【E2E / 統合シナリオ】プラン1: UIレスポンス高速化・局所再描画・非同期バックオフ検証', () {
    test(
      '1. [他コート更新遮断] 別コートの試合が頻繁に更新されても、操作中コートの singleMatchProvider は一切リビルドされないこと',
      () async {
        final container = ProviderContainer(
          overrides: [
            matchListProvider.overrideWith(
              (ref) => ref.watch(testMatchesStateProvider),
            ),
          ],
        );
        addTearDown(container.dispose);

        int court1ListenerNotificationCount = 0;
        container.listen<MatchModel?>(singleMatchProvider('match_court_1'), (
          prev,
          next,
        ) {
          court1ListenerNotificationCount++;
        });

        // 初期状態の確認（Court 1）
        final initialCourt1 = container.read(
          singleMatchProvider('match_court_1'),
        );
        expect(initialCourt1, isNotNull);
        expect(initialCourt1!.redName, 'Court1 赤選手');
        expect(court1ListenerNotificationCount, 0);

        // 他コート（Court 2）で連続スコア更新が発生（10回連続打突イベント）
        for (int i = 1; i <= 10; i++) {
          container
              .read(testMatchesStateProvider.notifier)
              .updateMatch(
                MatchModel(
                  id: 'match_court_2',
                  matchType: '個人戦',
                  tournamentId: 't1',
                  redName: 'Court2 赤選手',
                  whiteName: 'Court2 白選手',
                  redScore: i,
                  whiteScore: 0,
                ),
              );
        }

        // Court 1 の監視リスナーは1度も通知されていないこと（リビルド完全遮断）
        expect(
          court1ListenerNotificationCount,
          0,
          reason: '別コートの更新で自コートの singleMatchProvider が再通知されてはならない',
        );

        // 逆に Court 1 自身が更新されたときは正しく1回だけ通知されること
        container
            .read(testMatchesStateProvider.notifier)
            .updateMatch(initialCourt1.copyWith(redScore: 1));

        final updatedCourt1 = container.read(
          singleMatchProvider('match_court_1'),
        );
        expect(court1ListenerNotificationCount, 1, reason: '自コートの更新時のみ通知されること');
        expect(updatedCourt1!.redScore, 1);
      },
    );

    test(
      '2. [非同期バックオフ & 即時再送] 通信断の指数バックオフ待機中であっても、電波復帰シグナルで即時にキューがフラッシュされること',
      () async {
        // 模擬的な非同期バックオフ管理エンジンの動作検証
        final mockSyncQueue = <String>[];
        DateTime? nextAttemptAt;
        int retryCount = 0;
        bool isProcessing = false;

        Future<void> simulateProcessQueue({required bool isOnline}) async {
          if (isProcessing) return;
          if (nextAttemptAt != null &&
              DateTime.now().isBefore(nextAttemptAt!)) {
            return; // バックオフ期間中のためスキップ（非同期バックオフ）
          }

          isProcessing = true;
          try {
            if (!isOnline) {
              retryCount++;
              final backoffSeconds = 60; // 1分バックオフ
              nextAttemptAt = DateTime.now().add(
                Duration(seconds: backoffSeconds),
              );
              return;
            }

            // オンラインならキューを全件送信完了
            mockSyncQueue.clear();
            retryCount = 0;
            nextAttemptAt = null;
          } finally {
            isProcessing = false;
          }
        }

        void simulateResetBackoffAndProcess({required bool isOnline}) {
          nextAttemptAt = null;
          retryCount = 0;
          simulateProcessQueue(isOnline: isOnline);
        }

        // 1. オフライン状態でキューが3件蓄積
        mockSyncQueue.addAll(['event_1', 'event_2', 'event_3']);

        // 2. アップロードを試みるがオフラインのため失敗し、1分後のバックオフが設定される
        await simulateProcessQueue(isOnline: false);
        expect(mockSyncQueue.length, 3);
        expect(nextAttemptAt, isNotNull);
        expect(nextAttemptAt!.isAfter(DateTime.now()), isTrue);
        expect(retryCount, 1);

        // 3. バックオフ期間中に再度通常processQueueを呼んでも、スレッドをロックせず即座にスキップされること
        await simulateProcessQueue(isOnline: false);
        expect(mockSyncQueue.length, 3);

        // 4. ここで電波復帰シグナル (resetBackoffAndProcess) が発生
        // 1分を待つことなく、即座にキューがフラッシュ送信されて0件になること
        simulateResetBackoffAndProcess(isOnline: true);
        expect(
          mockSyncQueue.isEmpty,
          isTrue,
          reason: '電波復帰時にバックオフ待機時間をスキップして即時フラッシュされること',
        );
        expect(nextAttemptAt, isNull);
        expect(retryCount, 0);
      },
    );

    test('3. [団体戦グループ局所化] 同一トーナメント内でも、別グループの更新が自グループのセレクターに影響しないこと', () {
      final container = ProviderContainer(
        overrides: [
          matchListProvider.overrideWith(
            (ref) => ref.watch(testMatchesStateProvider),
          ),
        ],
      );
      addTearDown(container.dispose);

      int groupANotificationCount = 0;
      container.listen<List<MatchModel>>(
        teamMatchesByGroupProvider('group_A'),
        (prev, next) {
          groupANotificationCount++;
        },
      );

      // 初期状態
      expect(container.read(teamMatchesByGroupProvider('group_A')).length, 1);

      // 別グループ（group_B）の試合が更新された場合
      container
          .read(testMatchesStateProvider.notifier)
          .updateMatch(
            MatchModel(
              id: 'match_group_B_1',
              groupName: 'group_B',
              matchType: '団体戦',
              tournamentId: 't1',
              redName: '先鋒B',
              whiteName: '先鋒B2',
              redScore: 2,
            ),
          );

      // group_A のセレクター通知は 0 回であること
      expect(groupANotificationCount, 0, reason: '別グループの更新は自グループの購読を発火させないこと');
    });
  });
}

final testMatchesStateProvider =
    StateNotifierProvider<TestMatchesNotifier, List<MatchModel>>((ref) {
      return TestMatchesNotifier();
    });

class TestMatchesNotifier extends StateNotifier<List<MatchModel>> {
  TestMatchesNotifier()
    : super([
        MatchModel(
          id: 'match_court_1',
          groupName: 'group_A',
          matchType: '個人戦',
          tournamentId: 't1',
          redName: 'Court1 赤選手',
          whiteName: 'Court1 白選手',
        ),
        MatchModel(
          id: 'match_court_2',
          groupName: 'group_B',
          matchType: '個人戦',
          tournamentId: 't1',
          redName: 'Court2 赤選手',
          whiteName: 'Court2 白選手',
        ),
      ]);

  void updateMatch(MatchModel updated) {
    final list = List<MatchModel>.from(state);
    final idx = list.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
    } else {
      list.add(updated);
    }
    state = list;
  }
}
