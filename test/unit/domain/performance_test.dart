import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
// ※testフォルダの構造に合わせてパスを調整（ここでは unit フォルダ内と想定）
import '../../helpers/test_match_factory.dart'; 

void main() {
  group('⏱️ Phase 3-5: パフォーマンステスト (処理速度の限界検証)', () {
    final engine = KendoRuleEngine();

    test('1,000件の膨大なイベント履歴の解析が 50ms 以内で完了すること', () {
      final rule = const MatchRule(ipponLimit: 2, matchTimeMinutes: 3.0);
      final match = TestMatchFactory.createIndividualMatch(id: 'perf-match-001');

      // 1. 1000件のダミーイベントを生成（現実ではあり得ないほどの長期戦・Undo連発を想定）
      final events = List.generate(1000, (index) {
        return ScoreEventLegacyAdapter.fromLegacy(
          side: index % 2 == 0 ? Side.red : Side.white,
          type: PointType.men,
          sequence: index + 1,
          userId: 'perf_test_user',
          isCanceled: index % 3 == 0, // 3回に1回はキャンセル(Undo)済みとして混入し、計算を複雑にする
        );
      });

      // 2. ウォームアップ（DartのJITコンパイルの影響を排除するため、計測前に数回空回しする）
      for (int i = 0; i < 5; i++) {
        engine.analyzeHistory(events, match, rule);
      }

      // 3. 計測開始
      final stopwatch = Stopwatch()..start();
      
      final analysis = engine.analyzeHistory(events, match, rule);
      
      stopwatch.stop();

      // 4. 結果の検証
      // 1000件の解析でも、ユーザーが遅延を感じない 50ms 以内に終わるべき
      expect(stopwatch.elapsedMilliseconds, lessThan(50), 
        reason: 'パフォーマンス劣化: 1000件の解析に ${stopwatch.elapsedMilliseconds}ms かかりました（上限50ms）');
        
      // 念のため計算結果が存在することを確認
      expect(analysis.context.redIppon, greaterThanOrEqualTo(0));
    });
  });
}