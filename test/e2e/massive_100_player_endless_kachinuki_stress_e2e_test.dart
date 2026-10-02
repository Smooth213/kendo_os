import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';

void main() {
  group('[E2E] 100名規模・部内戦無限勝ち抜きストレステスト', () {
    test('100名参加・50試合連続進行において、待機キュー・飛び入り・棄権・連勝記録（Streak）が破綻せず整合すること', () {
      final queueNotifier = BunaiksenInfiniteQueueNotifier();
      final streakNotifier = BunaiksenInfiniteStreakNotifier();

      // 1. 100名の選手を待機列に初期登録
      final initialPlayers = List.generate(100, (i) => '部内選手_${i + 1}');
      queueNotifier.setPlayers(initialPlayers);

      expect(queueNotifier.state.length, 100);

      // 2. 50試合連続シミュレーション
      String currentKing = queueNotifier.popFirst()!; // 初代コート主

      for (int matchIndex = 1; matchIndex <= 50; matchIndex++) {
        final challenger = queueNotifier.popFirst()!;

        // 10試合目ごとに飛び入り選手が追加される
        if (matchIndex % 10 == 0) {
          queueNotifier.addPlayer('飛び入り選手_$matchIndex');
        }

        // 15試合目ごとに待機列の選手が1名途中棄権する
        if (matchIndex % 15 == 0 && queueNotifier.state.isNotEmpty) {
          final dropout = queueNotifier.state.last;
          queueNotifier.removePlayer(dropout);
        }

        // 試合結果シミュレーション（偶数回はKing防衛、奇数回はChallenger勝利）
        if (matchIndex % 2 == 0) {
          // King勝利: 連勝増加、Challengerは待機列末尾へ
          streakNotifier.incrementStreak(currentKing);
          streakNotifier.resetStreak(challenger);
          queueNotifier.moveToLast(challenger);
        } else {
          // Challenger勝利: 旧Kingの連勝リセット＆末尾へ、新King誕生
          streakNotifier.resetStreak(currentKing);
          streakNotifier.incrementStreak(challenger);
          queueNotifier.moveToLast(currentKing);
          currentKing = challenger;
        }
      }

      // 検証: キューの整合性と連勝状態の完全性
      expect(queueNotifier.state.isNotEmpty, isTrue);
      expect(
        queueNotifier.state.contains(currentKing),
        isFalse,
      ); // 現在試合中のKingは待機列外
      expect(streakNotifier.state[currentKing], greaterThan(0));
    });
  });
}
