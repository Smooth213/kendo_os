import 'match_rule_interface.dart';
import 'standard_kendo_rules.dart';
import 'tournament_rule_config.dart';

// ==========================================
// ★ Phase 6 & 13: Rule設定のデータ化 (合成とFactory)
// 古い RuleFactory (Dead Code) を完全に削除し、Resolverのみを残しました
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

// ==========================================
// ★ Phase 4: Rule Resolver導入
// 大会設定(Config)から、必要なルール部品を動的にDI(注入)して組み立てる
// ==========================================
class RuleResolver {
  static MatchRuleSet build(TournamentRuleConfig config) {
    return MatchRuleSet(
      scoring: config.scoring.isIpponShobu ? IpponShobuScoringRule() : LimitScoringRule(),
      victory: config.draw.hasHantei ? HanteiVictoryRule() : DrawVictoryRule(),
      time: StandardTimeRule(),
      hansoku: config.hansoku.hansokuLimit > 0 ? LimitHansokuRule() : NoHansokuRule(),
    );
  }
}