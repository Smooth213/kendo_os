import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/bunaiksen_infinite_engine_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';

void main() {
  group('[Unit] 部内戦（勝ち残り戦）動的途中エントリー・負傷棄権・連勝記録即時更新テスト', () {
    test('待機キュー運用・連勝進行・途中負傷棄権・動的エントリー追加・連勝リセットのフルサイクルが正しく検証されること', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queueNotifier = container.read(
        bunaiksenInfiniteQueueProvider.notifier,
      );
      final engine = container.read(bunaiksenInfiniteEngineProvider);

      // 初期参加者5名: 佐藤、鈴木、高橋、田中、伊藤
      final initialPlayers = ['高橋', '田中', '伊藤']; // 待機キュー
      queueNotifier.setPlayers(initialPlayers);

      // 初戦: 赤(佐藤) vs 白(鈴木)
      var currentMatch = const MatchModel(
        id: 'infinite_m1',
        matchType: '勝ち残り戦',
        redName: '佐藤',
        whiteName: '鈴木',
        status: 'finished',
        redScore: 2,
        whiteScore: 0,
      );

      // 第1試合結果処理: 佐藤が鈴木に勝利 (赤勝ち)
      var nextMatch = await engine.processMatchResult(currentMatch, 'red');
      expect(nextMatch, isNotNull);
      expect(nextMatch!.redName, '佐藤');
      expect(nextMatch.whiteName, '高橋');

      var streaks = container.read(bunaiksenInfiniteStreakProvider);
      var queue = container.read(bunaiksenInfiniteQueueProvider);
      expect(streaks['佐藤'], 1);
      expect(streaks['鈴木'], 0);
      expect(queue, ['田中', '伊藤', '鈴木']);

      // 第2試合: 佐藤 vs 高橋
      currentMatch = nextMatch.copyWith(
        redScore: 2,
        whiteScore: 1,
        status: 'finished',
      );
      nextMatch = await engine.processMatchResult(currentMatch, 'red');
      expect(nextMatch, isNotNull);
      expect(nextMatch!.redName, '佐藤');
      expect(nextMatch.whiteName, '田中');

      streaks = container.read(bunaiksenInfiniteStreakProvider);
      queue = container.read(bunaiksenInfiniteQueueProvider);
      expect(streaks['佐藤'], 2, reason: '佐藤が2連勝');
      expect(streaks['高橋'], 0);
      expect(queue, ['伊藤', '鈴木', '高橋']);

      // 負傷棄権イベント
      queueNotifier.removePlayer('鈴木');
      queue = container.read(bunaiksenInfiniteQueueProvider);
      expect(queue.contains('鈴木'), isFalse, reason: '負傷棄権した鈴木が待機列から完全除外される');
      expect(queue, ['伊藤', '高橋']);

      // 動的途中エントリー
      queueNotifier.addPlayer('渡辺');
      queue = container.read(bunaiksenInfiniteQueueProvider);
      expect(queue.last, '渡辺', reason: '途中エントリーの渡辺がキュー最後尾へ配備される');
      expect(queue, ['伊藤', '高橋', '渡辺']);

      // 第3試合: 佐藤 vs 田中
      currentMatch = nextMatch.copyWith(
        redScore: 0,
        whiteScore: 1,
        status: 'finished',
      );
      nextMatch = await engine.processMatchResult(currentMatch, 'white');
      expect(nextMatch, isNotNull);
      expect(nextMatch!.redName, '田中');
      expect(nextMatch.whiteName, '伊藤');

      streaks = container.read(bunaiksenInfiniteStreakProvider);
      queue = container.read(bunaiksenInfiniteQueueProvider);
      expect(streaks['田中'], 1, reason: '田中が新元立ちとして1勝目');
      expect(streaks['佐藤'], 0, reason: '敗れた佐藤の連勝記録はリセット');
      expect(queue, ['高橋', '渡辺', '佐藤']);

      // 第4試合: 田中 vs 伊藤
      currentMatch = nextMatch.copyWith(
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
      );
      nextMatch = await engine.processMatchResult(currentMatch, 'draw');
      expect(nextMatch, isNotNull);
      expect(nextMatch!.redName, '高橋');
      expect(nextMatch.whiteName, '渡辺', reason: '途中エントリーの渡辺が順当に登壇');

      streaks = container.read(bunaiksenInfiniteStreakProvider);
      queue = container.read(bunaiksenInfiniteQueueProvider);
      expect(streaks['田中'], 0);
      expect(streaks['伊藤'], 0);
      expect(queue, ['佐藤', '田中', '伊藤']);
    });
  });
}
