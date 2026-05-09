import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import '../helpers/test_match_factory.dart';

// ==========================================
// ★ Phase 10: Event/Replayer整合
// ルールが変更されても、過去の試合結果が改変されないことを証明するテスト
// ==========================================
void main() {
  group('⏪ Phase 10: Historical Replay 保証 (歴史改変防止)', () {
    test('1本勝負(v1)で終了した過去の試合を、3本勝負(v2)の現在ルールでリプレイしても、1本勝ちのまま終了状態が維持されること', () {
      final engine = KendoRuleEngine();
      final useCase = RebuildMatchFromEventsUseCase(engine);

      // 【過去の事実】1本勝負(v1)のルールで行われ、赤が1本取って終了した試合
      final historicalRule = const MatchRule(isIpponShobu: true); // Schema Version 1相当
      
      final pastEvent = ScoreEvent(
        id: 'evt-1',
        schemaVersion: 2,
        ruleVersion: 1, // ★ 当時は v1 だった
        side: Side.red,
        strikeType: StrikeType.men,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      );

      final pastMatch = TestMatchFactory.createIndividualMatch(id: 'past-match').copyWith(
        rule: historicalRule,
        events: [pastEvent],
        redScore: 1,
        whiteScore: 0,
        status: 'finished', // 当時のルール(1本勝負)で終了済み
      );

      // 【現在の状況】システムがバージョンアップし、デフォルトが3本勝負(v2)になった
      final currentSystemRule = const MatchRule(isIpponShobu: false); // Schema Version 2相当
      
      // 【Replay実行】
      final rebuiltMatch = useCase.execute(pastMatch, currentSystemRule);

      // 【検証】
      // 3本勝負で再計算されて in_progress に戻ってしまう「歴史改変バグ」が起きず、
      // 当時の1本勝負ルールが尊重され、finished(赤の1本勝ち)が維持されていること。
      expect(rebuiltMatch.redScore, 1);
      expect(rebuiltMatch.status, 'finished', reason: '現在のルール(3本勝負)に引っ張られて試合が再開されてはならない（歴史改変の防止）');
    });
  });
}