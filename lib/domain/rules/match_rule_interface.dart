import 'package:kendo_os/domain/entities/match_context.dart';

// ==========================================
// ★ Phase 2: Rule Interface統一 - Base Interface
// すべてのルール（時間、延長、反則、勝敗など）は、
// 単一の apply メソッドを持つこのインターフェースを実装します。
// ==========================================
abstract class RuleModule {
  RuleResult apply(RuleContext context);
}

// ==========================================
// ★ Phase 6: Rule分割 - 専門特化したルールの型定義
// C-2: MatchRule (Config) を引数として受け取るように変更
// ==========================================

/// ① スコア（得点）に関するルール
abstract class ScoringRule implements RuleModule {}

/// ② 反則に関するルール
abstract class HansokuRule implements RuleModule {}

/// ③ 試合時間に関するルール
abstract class TimeRule implements RuleModule {}

/// ④ 勝敗判定に関するルール
abstract class VictoryRule implements RuleModule {}