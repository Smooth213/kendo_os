import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/rules/tournament_rule_config.dart'; // ★ Phase 5変更: 依存を旧MatchRuleから新Configへ

// ==========================================
// ★ ⑥ Contextの純化：副作用を持たない純粋なデータ構造
// ルールエンジンが計算した「現在の状況」をUIや保存処理へ伝えるための器です。
// ==========================================

enum MatchResultStatus { inProgress, redWin, whiteWin, draw }

class MatchContext {
  final int redIppon;
  final int whiteIppon;
  final int redHansoku;
  final int whiteHansoku;
  final bool isTimeUp;
  final int targetIppon;
  final bool hasHantei; 

  MatchContext({
    required this.redIppon,
    required this.whiteIppon,
    required this.redHansoku,
    required this.whiteHansoku,
    required this.isTimeUp,
    required this.targetIppon,
    required this.hasHantei,
  });
}

// ==========================================
// ★ Phase 2: Rule Interface統一 - 共通データ構造
// あらゆるルール計算に必要な情報を一つにまとめた「入力」と、
// ルール適用後の状態変化を示す「出力」を定義します。
// ==========================================

/// ルールを適用するための入力コンテキスト
class RuleContext {
  final MatchContext matchState;           // 現在の計算状態（スコア等）
  final List<ScoreEvent> events;           // 歴史（打突や反則の履歴）
  final TournamentRuleConfig tournamentConfig; // ★ Phase 5変更完了: 階層型Configに完全移行
  final double clock;                      // 残り時間 (remainingSeconds)

  RuleContext({
    required this.matchState,
    required this.events,
    required this.tournamentConfig,
    required this.clock,
  });
}

/// ルール適用による状態の変化（差分）
class MatchTransition {
  final MatchContext updatedState;
  final MatchResultStatus? resultStatus;

  MatchTransition({
    required this.updatedState,
    this.resultStatus,
  });
}

/// ルールの実行結果
class RuleResult {
  final bool allowed;                  // このルールが適用可能だったか（矛盾がないか）
  final MatchTransition? transition;   // 適用後の状態変化

  RuleResult({
    required this.allowed,
    this.transition,
  });
}