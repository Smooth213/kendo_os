import '../match_rule.dart';
import 'match_rule_interface.dart';
import 'standard_kendo_rules.dart';

// ==========================================
// ★ Phase 6: Rule設定のデータ化 (合成とFactory)
// ==========================================

/// 分割された4つの専門ルールを束ねる「合成（Composite）」クラス
class MatchRuleSet {
  final ScoringRule scoring;
  final VictoryRule victory;
  final TimeRule time;
  final HansokuRule hansoku;

  MatchRuleSet({
    required this.scoring,
    required this.victory,
    required this.time,
    required this.hansoku,
  });
}

/// JSON等（MatchRule）の設定値から、最適なルール部品を選択・組み立てる工場
class RuleFactory {
  static MatchRuleSet fromConfig(MatchRule? config) {
    // ★ 将来的には、config.category（大会形式など）を見て
    // 「勝ち抜き戦用の勝敗ルール」などに動的に差し替える処理をここに書きます。
    // 現時点では、標準的な剣道ルールセットを組み立てて返します。
    return MatchRuleSet(
      scoring: StandardScoringRule(),
      victory: StandardVictoryRule(),
      time: StandardTimeRule(),
      hansoku: StandardHansokuRule(),
    );
  }
}