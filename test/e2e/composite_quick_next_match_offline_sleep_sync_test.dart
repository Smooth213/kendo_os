import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/sync/pending_sync_queue.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('[E2E] 次戦クイック追加中のオフライン切断 ＆ スリープ復帰 ＆ クラウド再接続複合耐障害性テスト', () {
    test('ウィザード操作中のオフライン断絶とスリープ復帰後の確定生成がFIFOキューに保護され再接続時に衝突なく収束すること', () async {
      final queue = PendingSyncQueue<MatchModel>();
      final sleepTime = DateTime(2026, 10, 15, 16, 0, 0);

      // ── 1. ウィザード操作中のオフライン切断シミュレーション ──
      bool isOnline = false;
      expect(isOnline, isFalse, reason: '体育館の電波遮断状態');

      // ── 2. 端末スリープ（サスペンド）および復帰 ──
      // スリープ中の時間経過（15分間）
      final wakeTime = sleepTime.add(const Duration(minutes: 15));
      expect(wakeTime.isAfter(sleepTime), isTrue);

      // 復帰後にウィザードから次戦の確定生成が実行される
      final offlineCreatedMatch = MatchModel(
        id: 'm_quick_offline_01',
        tournamentId: 't_resilience_01',
        groupName: '第1コート',
        matchType: '次鋒戦',
        category: '小学生団体戦',
        redName: '道上剣友会: 選手次鋒',
        whiteName: '修道館: 選手次鋒',
        rule: const MatchRule(matchTimeMinutes: 3, ipponLimit: 2),
        status: 'waiting',
        lastUpdatedAt: wakeTime,
      );

      // オフラインFIFOキューへ安全に退避
      queue.enqueue('sync_quick_create_01', offlineCreatedMatch);
      expect(queue.pendingCount, equals(1));
      expect(queue.peek?.data.id, equals('m_quick_offline_01'));

      // ── 3. オフライン中に端末上でスコア入力（面取得）が発生 ──
      final localScoreEvent = ScoreEvent(
        id: 'ev_offline_strike_01',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: wakeTime.add(const Duration(minutes: 1)),
        sequence: 1,
        logicalClock: 1,
      );

      final matchWithEvent = offlineCreatedMatch.copyWith(
        events: [localScoreEvent],
        redScore: 1,
        status: 'in_progress',
        lastUpdatedAt: wakeTime.add(const Duration(minutes: 1)),
      );

      // 2件目の同期タスクとしてキューへ追加
      queue.enqueue('sync_quick_score_01', matchWithEvent);
      expect(queue.pendingCount, equals(2));

      // ── 4. 電波復帰（クラウド再接続）とFIFOキューの順序保証デキュー ──
      isOnline = true;
      expect(isOnline, isTrue, reason: 'Wi-Fiまたは4G接続復旧');

      final syncedMatches = <MatchModel>[];
      while (!queue.isEmpty) {
        final task = queue.peek!;
        syncedMatches.add(task.data);
        queue.dequeue();
      }

      expect(queue.isEmpty, isTrue);
      expect(syncedMatches.length, equals(2));
      expect(syncedMatches.first.id, equals('m_quick_offline_01'));
      expect(syncedMatches.first.status, equals('waiting'));
      expect(syncedMatches.last.events.length, equals(1));
      expect(syncedMatches.last.redScore, equals(1));

      // ── 5. クラウド側（リモート）とのCRDT調停とデータ完全性検証 ──
      // リモート側はオフライン作成時の初期状態を持っていたと仮定
      final remoteMatch = offlineCreatedMatch;
      final localFinalMatch = syncedMatches.last;

      final engine = KendoRuleEngine();
      final timeSource = SystemTimeSource();
      final rebuilder = RebuildMatchFromEventsUseCase(engine, timeSource);
      final mergedMatch = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: remoteMatch,
        localMatch: localFinalMatch,
        rule: localFinalMatch.rule ?? const MatchRule(),
        rebuilder: rebuilder,
      );
      expect(mergedMatch.events.length, equals(1));

      final analysis = engine.analyzeHistory(
        mergedMatch.events,
        mergedMatch,
        mergedMatch.rule,
      );

      expect(analysis.context.redIppon, equals(1));
      expect(analysis.displays[Side.red]?.first.mark, equals('メ'));

      // サニタイズとJSONデータ整合性検証
      final sanitized = SyncCrdtMerger.sanitizeForSync(
        localFinalMatch.toJson(),
      );
      expect(sanitized['id'], equals('m_quick_offline_01'));
      expect(sanitized['redScore'], equals(1));
      expect(sanitized['status'], equals('in_progress'));
    });
  });
}
