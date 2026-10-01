import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('[E2E] 複合Redoオフライン切断およびCRDT競合収束テスト', () {
    test('回線切断下でのUndoおよびRedo操作が再接続時にリモートの新規打突と衝突せず決定論的に収束すること', () async {
      final now = DateTime(2026, 10, 1, 15, 0, 0);
      final ruleEngine = KendoRuleEngine();
      final timeSource = SystemTimeSource();
      final rebuilder = RebuildMatchFromEventsUseCase(ruleEngine, timeSource);

      // 1. 基本試合状態
      final baseMatch = const MatchModel(
        id: 'crdt_redo_m1',
        tournamentId: 't_crdt',
        matchType: '個人戦',
        redName: '神武館: 佐藤',
        whiteName: '修道館: 田中',
        redScore: 0,
        whiteScore: 0,
        status: 'in_progress',
        rule: MatchRule(),
      );

      // 2. 主審端末が赤の面を入力 (seq: 1, logicalClock: 1)
      final evMen = ScoreEvent(
        id: 'ev_men_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
        sequence: 1,
        logicalClock: 1,
        userId: 'referee_main',
      );

      final matchWithMen = baseMatch.copyWith(events: [evMen], redScore: 1);

      // 3. 主審が一旦誤審としてUndoを実行 (seq: 2, logicalClock: 2)
      final evUndo = ScoreEvent(
        id: 'ev_undo_1',
        side: Side.red,
        isUndo: true,
        targetId: 'ev_men_1',
        timestamp: now.add(const Duration(seconds: 1)),
        sequence: 2,
        logicalClock: 2,
        userId: 'referee_main',
      );

      // 4. ここで主審端末が一時的に「完全オフライン」になり、合議で面が有効と判断されてRedoを実行 (seq: 3, logicalClock: 3)
      final evRedo = ScoreEvent(
        id: 'ev_redo_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        isRestore: true,
        targetId: 'ev_men_1',
        timestamp: now.add(const Duration(seconds: 2)),
        sequence: 3,
        logicalClock: 3,
        userId: 'referee_main',
      );

      // オフライン主審端末のローカル状態
      final localOfflineMatch = matchWithMen.copyWith(
        events: [evMen, evUndo, evRedo],
        pendingEvents: [evUndo, evRedo],
        redScore: 1,
        syncState: SyncState.localOnly,
      );

      // 5. 一方、副審（リモート端末）は接続を維持しており、白の小手を入力 (seq: 4, logicalClock: 4)
      final evRemoteKote = ScoreEvent(
        id: 'ev_remote_kote',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 3)),
        sequence: 4,
        logicalClock: 4,
        userId: 'referee_sub',
      );

      final remoteMatch = matchWithMen.copyWith(
        events: [evMen, evRemoteKote],
        redScore: 1,
        whiteScore: 1,
      );

      // 6. 主審端末がネットワークへ復帰し、CRDTマージを実行
      final mergedMatch = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: remoteMatch,
        localMatch: localOfflineMatch,
        rule: const MatchRule(),
        rebuilder: rebuilder,
      );

      // 7. CRDT調停検証:
      // イベント集合に evMen, evUndo, evRedo, evRemoteKote がすべて決定論的に統合され、
      // 赤の面はRedoによって有効、白の小手も有効となり、スコア 1 - 1 に決定論的収束すること
      expect(mergedMatch.events.any((e) => e.id == 'ev_men_1'), isTrue);
      expect(mergedMatch.events.any((e) => e.id == 'ev_undo_1'), isTrue);
      expect(mergedMatch.events.any((e) => e.id == 'ev_redo_1'), isTrue);
      expect(mergedMatch.events.any((e) => e.id == 'ev_remote_kote'), isTrue);

      expect(mergedMatch.redScore, 1);
      expect(mergedMatch.whiteScore, 1);
    });
  });
}
