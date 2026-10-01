import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/services/match_domain_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('[E2E] 勝ち抜き代表戦・動的コート振替・オフラインCRDT収束 極限複合テスト', () {
    late MatchDomainService domainService;

    setUp(() {
      domainService = MatchDomainService();
    });

    test('勝ち抜き戦大将引き分け代表戦の発生からコート振替およびオフライン競合CRDT収束が完全整合すること', () {
      const rule = MatchRule(
        isKachinuki: true,
        matchTimeMinutes: 3.0,
        positions: ['先鋒', '中堅', '大将'],
        kachinukiUnlimitedType: '大将引き分け延長',
      );

      final now = DateTime(2026, 10, 1, 10, 0, 0);

      // 1. 第1コートで大将戦が引き分け
      final boutTaisho = MatchModel(
        id: 'bout_k_taisho',
        tournamentId: 't_comp_1',
        matchType: '勝ち抜き戦',
        note: '第1試合場, 大将戦',
        isKachinuki: true,
        redName: '赤大将',
        whiteName: '白大将',
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
        redRemaining: [],
        whiteRemaining: [],
        order: 3.0,
        lastUpdatedAt: now,
      );

      // 2. 代表戦（大将延長戦）が自動生成される
      final boutDaihyo = domainService.generateNextKachinukiMatch(
        boutTaisho,
        rule,
      );
      expect(boutDaihyo, isNotNull);
      expect(boutDaihyo!.matchType, '大将延長戦');

      // 3. 現場都合により急遽「第2試合場」へコート振替
      final reassignedDaihyo = boutDaihyo.copyWith(note: '第2試合場, 大将延長戦');
      expect(reassignedDaihyo.note.contains('第2試合場'), isTrue);

      // 4. オフライン環境でのCRDT競合・イベントマージシミュレーション
      // リモート確定イベント（メ先取）
      final remoteMatch = reassignedDaihyo.copyWith(
        events: [
          ScoreEvent(
            id: 'ev_remote_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now,
            logicalClock: 1,
          ),
        ],
      );

      // ローカル待機イベント（コ先取）
      final localMatch = reassignedDaihyo.copyWith(
        pendingEvents: [
          ScoreEvent(
            id: 'ev_local_2',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 5)),
            logicalClock: 2,
          ),
        ],
      );

      final ruleEngine = KendoRuleEngine();
      final timeSource = SystemTimeSource();
      final rebuilder = RebuildMatchFromEventsUseCase(ruleEngine, timeSource);

      final merged = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: remoteMatch,
        localMatch: localMatch,
        rule: rule,
        rebuilder: rebuilder,
      );

      expect(merged.events.length, 2);
      expect(merged.events.any((e) => e.strikeType == StrikeType.men), isTrue);
      expect(merged.events.any((e) => e.strikeType == StrikeType.kote), isTrue);
      expect(merged.note.contains('第2試合場'), isTrue);
    });
  });
}
