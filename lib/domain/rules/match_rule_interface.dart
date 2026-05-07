import 'package:kendo_os/domain/entities/match_context.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';

// ==========================================
// ★ Phase 6: Rule分割 - 専門特化したルールの型定義
// C-2: MatchRule (Config) を引数として受け取るように変更
// ==========================================

/// ① スコア（得点）に関するルール
abstract class ScoringRule {
  MatchContext apply(List<ScoreEvent> events, MatchContext currentContext, MatchRule? rule);
}

/// ② 反則に関するルール
abstract class HansokuRule {
  MatchContext apply(List<ScoreEvent> events, MatchContext currentContext, MatchRule? rule);
}

/// ③ 試合時間に関するルール
abstract class TimeRule {
  MatchContext apply(MatchContext currentContext, double remainingSeconds, MatchRule? rule);
}

/// ④ 勝敗判定に関するルール
abstract class VictoryRule {
  MatchResultStatus evaluate(MatchContext context, int redHantei, int whiteHantei, MatchRule? rule);
}