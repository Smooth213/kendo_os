import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('[E2E] 【分散競合E2E】ミリ秒同時打突入力 × 直後Undo双方向収束テスト', () {
    test(
      '主審(A)と副審(B)によるミリ秒同時打突入力が決定論的に同一順序へ収束し、直後のUndoが双方で完全に双方向同期されること',
      () async {
        final now = DateTime(2026, 9, 27, 10, 0, 0);
        final ruleEngine = KendoRuleEngine();
        final timeSource = SystemTimeSource();
        final rebuilder = RebuildMatchFromEventsUseCase(ruleEngine, timeSource);

        // 初期試合状態 (0 - 0)
        final baseMatch = MatchModel(
          id: 'crdt_conflict_m1',
          tournamentId: 't1',
          matchType: '個人戦',
          redName: '神武館: 佐藤',
          whiteName: '修道館: 田中',
          redScore: 0,
          whiteScore: 0,
          status: 'in_progress',
          rule: const MatchRule(),
        );

        // 1. 同一ミリ秒での同時打突入力シミュレーション
        // Client A (主審): 赤の「メ」を入力 (logicalClock: 1, timestamp: now)
        final eventA = ScoreEvent(
          id: 'ev_client_a_men',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: now,
          logicalClock: 1,
          sequence: 1,
          userId: 'user_referee_a',
        );

        // Client B (副審): 白の「コ」を入力 (logicalClock: 1, timestamp: now + 1ms)
        final eventB = ScoreEvent(
          id: 'ev_client_b_kote',
          side: Side.white,
          strikeType: StrikeType.kote,
          isIppon: true,
          timestamp: now.add(const Duration(milliseconds: 1)),
          logicalClock: 1,
          sequence: 1,
          userId: 'user_referee_b',
        );

        final clientAMatch = baseMatch.copyWith(pendingEvents: [eventA]);
        final clientBMatch = baseMatch.copyWith(pendingEvents: [eventB]);

        // 2. Client A 側でのマージ (Remote: B, Local: A)
        final clientAMerged = SyncCrdtMerger.mergeAndRebuild(
          remoteMatch: baseMatch.copyWith(events: [eventB]),
          localMatch: clientAMatch,
          rule: const MatchRule(),
          rebuilder: rebuilder,
        );

        // 3. Client B 側でのマージ (Remote: A, Local: B)
        final clientBMerged = SyncCrdtMerger.mergeAndRebuild(
          remoteMatch: baseMatch.copyWith(events: [eventA]),
          localMatch: clientBMatch,
          rule: const MatchRule(),
          rebuilder: rebuilder,
        );

        // 4. 双方向収束検証:
        // logicalClockが同じ(1)のため、timestamp順（now < now+1ms）により
        // [eventA, eventB] の順序で双方が完全一致すること
        expect(clientAMerged.events.length, 2);
        expect(clientBMerged.events.length, 2);
        expect(clientAMerged.events[0].id, 'ev_client_a_men');
        expect(clientAMerged.events[1].id, 'ev_client_b_kote');
        expect(clientBMerged.events[0].id, 'ev_client_a_men');
        expect(clientBMerged.events[1].id, 'ev_client_b_kote');

        // スコアも双方 1 - 1 で決定論的に一致
        expect(clientAMerged.redScore, 1);
        expect(clientAMerged.whiteScore, 1);
        expect(clientBMerged.redScore, 1);
        expect(clientBMerged.whiteScore, 1);

        // 5. 直後に Client A 側で「誤操作Undo（赤の面を取り消す）」を実行
        final undoEventA = ScoreEvent(
          id: 'ev_undo_client_a_men',
          side: Side.red,
          isUndo: true,
          targetId: 'ev_client_a_men',
          timestamp: now.add(const Duration(seconds: 1)),
          logicalClock: 2,
          sequence: 2,
          userId: 'user_referee_a',
        );

        // Client A 側でローカルリビルド
        final clientAAfterUndo = SyncCrdtMerger.mergeAndRebuild(
          remoteMatch: clientAMerged,
          localMatch: clientAMerged.copyWith(pendingEvents: [undoEventA]),
          rule: const MatchRule(),
          rebuilder: rebuilder,
        );

        // Client A 側: 赤の面が相殺され、白の小手のみ有効 (0 - 1)
        expect(clientAAfterUndo.redScore, 0);
        expect(clientAAfterUndo.whiteScore, 1);

        // 6. Undo イベントがネットワークを通じて Client B に伝播・同期
        final clientBAfterSync = SyncCrdtMerger.mergeAndRebuild(
          remoteMatch: clientAAfterUndo,
          localMatch: clientBMerged,
          rule: const MatchRule(),
          rebuilder: rebuilder,
        );

        // 7. Client B 側でも Eventual Consistency が成立し、0 - 1 に収束すること
        expect(clientBAfterSync.redScore, 0);
        expect(clientBAfterSync.whiteScore, 1);
        expect(clientBAfterSync.events.length, 3); // men, kote, undo_men
        expect(
          clientBAfterSync.events.map((e) => e.id).toList(),
          clientAAfterUndo.events.map((e) => e.id).toList(),
          reason: '双方のイベントSourcing履歴が完全同一に収束していること',
        );
      },
    );
  });
}
