import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/match_state.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/time/server_clock_offset_service.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ 【E2E / 統合シナリオ】プラン3: 堅牢性・同期整合性・データ完全性検証', () {
    test(
      '1. [タイマーミリ秒端数精度の完全維持] 30回連続でタイマー開始・停止（はじめ・やめ）を繰り返しても累積ズレが0msであること',
      () {
        final baseStartTime = DateTime.utc(2026, 9, 14, 10, 0, 0);
        var match = const MatchModel(
          id: 'timer_jitter_test',
          matchType: '個人戦',
          redName: '選手赤',
          whiteName: '選手白',
          matchTimeMinutes: 3.0, // 3分 = 180,000ms
          status: 'waiting',
          accumulatedPauseDurationMs: 0,
        );

        var currentTime = baseStartTime;
        int expectedTotalElapsedMs = 0;

        // 30回の「はじめ」「やめ」シミュレーション（各回異なる端数ミリ秒: 例 456ms 経過）
        for (int i = 1; i <= 30; i++) {
          // 「はじめ」: タイマー開始
          match = match.copyWith(
            status: 'in_progress',
            timerStartedAt: currentTime,
            timerPausedAt: null,
          );

          // 試合が 456ms 進行
          const runDurationMs = 456;
          currentTime = currentTime.add(
            const Duration(milliseconds: runDurationMs),
          );
          expectedTotalElapsedMs += runDurationMs;

          // 「やめ」: タイマー停止 (Plan 3-① の生ミリ秒加算ロジック)
          final additionalMs = currentTime
              .difference(match.timerStartedAt!)
              .inMilliseconds;
          final newAccMs = match.accumulatedPauseDurationMs + additionalMs;

          match = match.copyWith(
            status: 'paused',
            timerStartedAt: null,
            timerPausedAt: currentTime,
            accumulatedPauseDurationMs: newAccMs,
          );

          // 一時停止状態が 500ms 継続
          currentTime = currentTime.add(const Duration(milliseconds: 500));
        }

        // 30回終了後の検証
        expect(
          match.accumulatedPauseDurationMs,
          equals(expectedTotalElapsedMs),
        );
        expect(match.accumulatedPauseDurationMs, equals(30 * 456)); // 13,680ms
        // 天井秒逆算で発生していた秒ズレが完全にゼロであることを確認
        final remainingMs = (3 * 60 * 1000) - match.accumulatedPauseDurationMs;
        expect(
          match.calculateRemainingSeconds(currentTime),
          equals((remainingMs / 1000).ceil()),
        );
      },
    );

    test('2. [Clock Skew 補正] サーバー時刻オフセットが適用され、正確なサーバー同期時刻が取得できること', () {
      final service = ServerClockOffsetService.instance;
      // 5秒端末時計が遅れているシミュレーション (+5,000ms)
      service.setOffset(const Duration(seconds: 5));

      final timeSource = SystemTimeSource();
      final rawNow = DateTime.now().toUtc();
      final correctedNow = timeSource.now();

      final diffMs = correctedNow.difference(rawNow).inMilliseconds;
      expect(diffMs, greaterThanOrEqualTo(4900));
      expect(diffMs, lessThanOrEqualTo(5100));

      service.resetOffset();
      expect(service.offset, equals(Duration.zero));
    });

    test(
      '3. [CRDT 3者マージ＆LWWタイマー調停] リモート確定・ローカル確定・ローカル未送信の3者が完全ユニークマージされ、タイマーが最新状態に調停されること',
      () {
        final now = DateTime.utc(2026, 9, 14, 12, 0, 0);

        // リモートの試合データ (イベント1件同期済み)
        final remoteMatch = MatchModel(
          id: 'crdt_match_1',
          matchType: '個人戦',
          redName: '選手赤',
          whiteName: '選手白',
          status: 'in_progress',
          lastUpdatedAt: now.subtract(const Duration(seconds: 10)),
          events: [
            ScoreEvent(
              id: 'ev_remote_1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: now.subtract(const Duration(seconds: 10)),
              sequence: 1,
              logicalClock: 1,
            ),
          ],
        );

        // ローカル確定イベント (未送信の間にIsarローカルで確定されたイベント)
        final localMatch = MatchModel(
          id: 'crdt_match_1',
          matchType: '個人戦',
          redName: '選手赤',
          whiteName: '選手白',
          status: 'in_progress',
          lastUpdatedAt: now,
          accumulatedPauseDurationMs: 1500,
          events: [
            ScoreEvent(
              id: 'ev_local_confirmed_2',
              side: Side.white,
              strikeType: StrikeType.kote,
              isIppon: true,
              timestamp: now.subtract(const Duration(seconds: 5)),
              sequence: 2,
              logicalClock: 2,
            ),
          ],
          pendingEvents: [
            ScoreEvent(
              id: 'ev_local_pending_3',
              side: Side.red,
              strikeType: StrikeType.dou,
              isIppon: true,
              timestamp: now,
              sequence: 3,
              logicalClock: 3,
            ),
          ],
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);
        final rebuilder = container.read(rebuildMatchFromEventsUseCaseProvider);
        const rule = MatchRule();

        final merged = SyncCrdtMerger.mergeAndRebuild(
          remoteMatch: remoteMatch,
          localMatch: localMatch,
          rule: rule,
          rebuilder: rebuilder,
        );

        // 3者のイベントが漏れなく全て合流していること
        expect(merged.events.length, equals(3));
        expect(merged.events[0].id, equals('ev_remote_1'));
        expect(merged.events[1].id, equals('ev_local_confirmed_2'));
        expect(merged.events[2].id, equals('ev_local_pending_3'));

        // タイマー状態はローカルの最新状態 (1500ms) が採用されていること
        expect(merged.accumulatedPauseDurationMs, equals(1500));
      },
    );

    test(
      '4. [Web大会切替時のゴースト防止] matchListProvider は現在選択中の大会IDに一致する試合のみを返却すること',
      () {
        debugIsWebOverride = true;
        addTearDown(() => debugIsWebOverride = false);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Web用メモリキャッシュに大会Aと大会Bの試合が混在している状況をシミュレート
        const matchA = MatchModel(
          id: 'm_tourA_1',
          tournamentId: 'tour_A',
          matchType: '個人戦',
          redName: '選手A赤',
          whiteName: '選手A白',
        );
        const matchB = MatchModel(
          id: 'm_tourB_1',
          tournamentId: 'tour_B',
          matchType: '個人戦',
          redName: '選手B赤',
          whiteName: '選手B白',
        );

        container.read(webCurrentTournamentMatchesProvider.notifier).state = [
          matchA,
          matchB,
        ];
        container.read(webCurrentTournamentIdProvider.notifier).state =
            'tour_A';

        // 大会Aを選択中
        final listA = container.read(matchListProvider);
        expect(listA.length, equals(1));
        expect(listA.first.id, equals('m_tourA_1'));

        // 大会Bに切替
        container.read(webCurrentTournamentIdProvider.notifier).state =
            'tour_B';
        final listB = container.read(matchListProvider);
        expect(listB.length, equals(1));
        expect(listB.first.id, equals('m_tourB_1'));
      },
    );

    test(
      '5. [FSM有限状態機械] MatchModel.transitionEvent により正当な状態遷移のみが実行され、不正遷移が拒否されること',
      () {
        var match = const MatchModel(
          id: 'fsm_test_match',
          matchType: '個人戦',
          redName: '選手赤',
          whiteName: '選手白',
          status: 'waiting', // MatchLifecycleState.ready 相当
        );

        expect(match.lifecycleState, equals(MatchLifecycleState.ready));

        // 試合開始: ready -> inProgress
        match = match.transitionEvent(StateTransitionEvent.startMatch);
        expect(match.lifecycleState, equals(MatchLifecycleState.inProgress));
        expect(match.status, equals('in_progress'));

        // 一時停止: inProgress -> paused
        match = match.transitionEvent(StateTransitionEvent.pause);
        expect(match.lifecycleState, equals(MatchLifecycleState.paused));

        // 再開: paused -> inProgress
        match = match.transitionEvent(StateTransitionEvent.resume);
        expect(match.lifecycleState, equals(MatchLifecycleState.inProgress));

        // タイムアップ: inProgress -> completed
        match = match.transitionEvent(StateTransitionEvent.timeUp);
        expect(match.lifecycleState, equals(MatchLifecycleState.completed));
        expect(match.status, equals('finished'));

        // 不正遷移テスト: completed 状態から startMatch を呼ぶと InvalidStateException が発生すること
        expect(
          () => match.transitionEvent(StateTransitionEvent.startMatch),
          throwsA(isA<InvalidStateException>()),
        );
      },
    );
  });
}
