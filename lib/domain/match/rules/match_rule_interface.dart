import '../match_context.dart';
import '../score_event.dart';

// ==========================================
// ★ Phase 6: Rule分割 - 専門特化したルールの型定義
// ==========================================

/// ① スコア（得点）に関するルール
abstract class ScoringRule {
  MatchContext apply(List<ScoreEvent> events, MatchContext currentContext);
}

/// ② 反則に関するルール
abstract class HansokuRule {
  MatchContext apply(List<ScoreEvent> events, MatchContext currentContext);
}

/// ③ 試合時間に関するルール
abstract class TimeRule {
  MatchContext apply(MatchContext currentContext, double remainingSeconds);
}

/// ④ 勝敗判定に関するルール
abstract class VictoryRule {
  MatchResultStatus evaluate(MatchContext context, int redHantei, int whiteHantei);
}