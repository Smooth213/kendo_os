import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/bunaiksen_infinite_engine_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';

void main() {
  group('[Unit] 部内戦勝ち残り無限エンジン・待機キュー・連勝ライフサイクルテスト', () {
    late ProviderContainer container;
    late BunaiksenInfiniteEngine engine;
    late BunaiksenInfiniteQueueNotifier queueNotifier;

    setUp(() {
      container = ProviderContainer();
      engine = container.read(bunaiksenInfiniteEngineProvider);
      queueNotifier = container.read(bunaiksenInfiniteQueueProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('赤(元立ち)勝利時: 赤の連勝加算、白の連勝リセットと最後尾移動、次の挑戦者ポップが行われること', () async {
      queueNotifier.setPlayers(['選手C', '選手D', '選手E']);

      final currentMatch = MatchModel(
        id: 'match_1',
        matchType: '勝ち残り戦',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        events: [
          ScoreEvent(
            id: 'ev_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: DateTime(2026, 4, 29, 10, 0),
          ),
        ],
      );

      final nextMatch = await engine.processMatchResult(currentMatch, 'red');
      expect(nextMatch, isNotNull);
      expect(nextMatch!.redName, '選手A', reason: '勝者の赤(元立ち)がそのまま残留');
      expect(nextMatch.whiteName, '選手C', reason: '待機列先頭の選手Cが挑戦者として登壇');
      expect(nextMatch.redScore, 0, reason: '新規試合のスコアは0リセット');
      expect(nextMatch.whiteScore, 0);
      expect(nextMatch.status, 'waiting');
      expect(nextMatch.events, isEmpty, reason: '前試合のイベント履歴は完全に初期化されること');

      final streaks = container.read(bunaiksenInfiniteStreakProvider);
      final queue = container.read(bunaiksenInfiniteQueueProvider);
      expect(streaks['選手A'], 1, reason: '選手Aは1連勝');
      expect(streaks['選手B'], 0, reason: '敗れた選手Bの連勝は0');
      expect(queue, ['選手D', '選手E', '選手B'], reason: '選手Bは待機列最後尾へ移動');
    });

    test('白(挑戦者)勝利時: 白が新元立ち(赤)へ昇格、赤の連勝リセットと最後尾移動が行われること', () async {
      queueNotifier.setPlayers(['選手C', '選手D']);

      const currentMatch = MatchModel(
        id: 'match_2',
        matchType: '勝ち残り戦',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 0,
        whiteScore: 1,
        status: 'finished',
      );

      final nextMatch = await engine.processMatchResult(currentMatch, 'white');
      expect(nextMatch, isNotNull);
      expect(nextMatch!.redName, '選手B', reason: '剣道ルールに従い勝者が赤(元立ち)にセット');
      expect(nextMatch.whiteName, '選手C', reason: '待機列先頭が挑戦者にセット');

      final streaks = container.read(bunaiksenInfiniteStreakProvider);
      final queue = container.read(bunaiksenInfiniteQueueProvider);
      expect(streaks['選手B'], 1, reason: '新元立ち選手Bは1勝目');
      expect(streaks['選手A'], 0, reason: '敗れた前元立ち選手Aはリセット');
      expect(queue, ['選手D', '選手A']);
    });

    test('引き分け時: 両者退場、両者連勝リセット、待機列先頭2名が次試合に配備されること', () async {
      queueNotifier.setPlayers(['選手C', '選手D', '選手E']);

      const currentMatch = MatchModel(
        id: 'match_3',
        matchType: '勝ち残り戦',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
      );

      final nextMatch = await engine.processMatchResult(currentMatch, 'draw');
      expect(nextMatch, isNotNull);
      expect(nextMatch!.redName, '選手C', reason: '待機列1番目が赤にセット');
      expect(nextMatch.whiteName, '選手D', reason: '待機列2番目が白にセット');

      final streaks = container.read(bunaiksenInfiniteStreakProvider);
      final queue = container.read(bunaiksenInfiniteQueueProvider);
      expect(streaks['選手A'], 0);
      expect(streaks['選手B'], 0);
      expect(queue, ['選手E', '選手A', '選手B'], reason: '引き分けた両者が末尾に順次追加');
    });

    test('待機キューの動的操作（reorder, remove, moveToLast）が正しく機能すること', () {
      queueNotifier.setPlayers(['選手1', '選手2', '選手3', '選手4']);

      // 1. reorder: 選手1をインデックス2（選手3の後ろ）へ移動
      queueNotifier.reorder(0, 3);
      expect(container.read(bunaiksenInfiniteQueueProvider), [
        '選手2',
        '選手3',
        '選手1',
        '選手4',
      ]);

      // 2. removePlayer: 選手3が負傷離脱
      queueNotifier.removePlayer('選手3');
      expect(container.read(bunaiksenInfiniteQueueProvider), [
        '選手2',
        '選手1',
        '選手4',
      ]);

      // 3. moveToLast: 選手2を最後尾へ
      queueNotifier.moveToLast('選手2');
      expect(container.read(bunaiksenInfiniteQueueProvider), [
        '選手1',
        '選手4',
        '選手2',
      ]);
    });
  });
}
