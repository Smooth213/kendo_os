import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/rules/tournament_rule_config.dart';
import 'package:kendo_os/domain/rules/rule_config_validator.dart';
import 'package:kendo_os/domain/rules/rule_factory.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import '../helpers/test_match_factory.dart';

// ==========================================
// ★ Phase 11: Chaos Test (ルール爆発・クラッシュ耐性)
// 極限状態・矛盾状態のルール組み合わせにシステムが耐えられるかを検証
// ==========================================
void main() {
  group('🌪️ Phase 11: Chaos & Fuzzing Tests', () {
    
    test('11-1 & 11-3: Random Rule Combination & Invalid Input (1000パターンの異常設定耐性)', () {
      final random = Random(999);
      int crashCount = 0;
      int invalidDetectedCount = 0;

      for (int i = 0; i < 1000; i++) {
        // 意図的にマイナス値や矛盾を含むカオスなConfigを生成
        final config = TournamentRuleConfig(
          time: TimeConfig(matchTimeMinutes: random.nextDouble() * 10 - 2), // -2〜8分 (マイナス時間)
          scoring: ScoringConfig(
            isIpponShobu: random.nextBool(),
            ipponLimit: random.nextInt(5) - 1, // -1〜3本 (マイナス本数)
          ),
          encho: EnchoConfig(
            isEnchoUnlimited: random.nextBool(),
            enchoCount: random.nextInt(3),
            enchoTimeMinutes: random.nextDouble() * 5 - 1,
          ),
          hansoku: HansokuConfig(hansokuLimit: random.nextInt(4) - 1), // -1〜2回
          team: TeamConfig(
            isKachinuki: random.nextBool(),
            kachinukiUnlimitedType: random.nextBool() ? '大将引き分け延長' : '大将対大将',
          ),
          draw: DrawConfig(hasHantei: random.nextBool()),
        );

        // Validator が無効値を正しく検知できるか
        final errors = RuleConfigValidator.validate(config);
        if (errors.isNotEmpty) {
          invalidDetectedCount++;
        }

        try {
          // どんな異常値でも Resolver が落ちずに RuleSet を構築できること
          RuleResolver.build(config);
        } catch (e) {
          crashCount++;
        }
      }

      expect(crashCount, 0, reason: 'カオスなルールの組み合わせで Resolver がクラッシュしました');
      expect(invalidDetectedCount, greaterThan(0), reason: 'Validator が異常値(マイナス等)を全く検知していません');
    });

    test('11-2: Replay Fuzzing (無作為なイベント×無作為なルールでのエンジン解析耐性)', () {
      final engine = KendoRuleEngine();
      final random = Random(777);
      int crashCount = 0;

      for (int i = 0; i < 100; i++) {
        // 解析に通すためのランダムルール
        final rule = MatchRule(
          matchTimeMinutes: random.nextDouble() * 5 + 0.1,
          ipponLimit: random.nextInt(3) + 1,
          hansokuLimit: random.nextInt(3),
          isIpponShobu: random.nextBool(),
          hasHantei: random.nextBool(),
        );

        var match = TestMatchFactory.createIndividualMatch(id: 'fuzz-$i').copyWith(rule: rule);
        final events = <ScoreEvent>[];

        // ランダムに無茶苦茶なイベントを詰め込む
        final eventCount = random.nextInt(20);
        for (int j = 0; j < eventCount; j++) {
          events.add(ScoreEvent(
            id: 'evt-$i-$j',
            schemaVersion: 2,
            ruleVersion: 1,
            side: random.nextBool() ? Side.red : Side.white,
            strikeType: random.nextBool() ? StrikeType.men : StrikeType.none,
            isHansoku: random.nextBool(),
            isUndo: random.nextBool() && random.nextDouble() > 0.8, // 稀にUndo
            timestamp: DateTime.now().add(Duration(seconds: j)),
          ));
        }

        try {
          // どんなイベントとルールの組み合わせでも例外(Exception)で落ちないこと
          engine.analyzeHistory(events, match, rule);
        } catch (e) {
          crashCount++;
        }
      }
      
      expect(crashCount, 0, reason: 'ファジング(ランダムイベント×ランダムルール)によりエンジンがクラッシュしました');
    });

  });
}