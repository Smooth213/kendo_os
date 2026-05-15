import 'package:kendo_os/domain/entities/match_context.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule_interface.dart';

// ==========================================
// ★ Phase 13: Dead Code削除
// if文で分岐していた「移行用プロキシ (StandardScoringRule等)」を完全削除しました。
// ==========================================

// --- Scoring Rule Modules ---
abstract class BaseScoringRule implements ScoringRule {
  int determineTarget(RuleContext context);

  @override
  RuleResult apply(RuleContext context) {
    int red = 0;
    int white = 0;
    int currentTarget = determineTarget(context);

    for (var e in context.events) {
      if (e.isCanceled) continue;
      if (e.type != PointType.hansoku && e.type != PointType.fusen) {
        if (e.side == Side.red) red++;
        if (e.side == Side.white) white++;
      }
      if (e.type == PointType.fusen) {
        if (e.side == Side.red) red += currentTarget;
        if (e.side == Side.white) white += currentTarget;
      }
    }
    
    final newState = MatchContext(
      redIppon: red,
      whiteIppon: white,
      redHansoku: context.matchState.redHansoku,
      whiteHansoku: context.matchState.whiteHansoku,
      isTimeUp: context.matchState.isTimeUp,
      targetIppon: currentTarget,
      hasHantei: context.tournamentConfig.draw.hasHantei,
    );
    return RuleResult(allowed: true, transition: MatchTransition(updatedState: newState));
  }
}

class LimitScoringRule extends BaseScoringRule {
  @override
  int determineTarget(RuleContext context) {
    return context.tournamentConfig.scoring.ipponLimit > 0
        ? context.tournamentConfig.scoring.ipponLimit 
        : context.matchState.targetIppon;
  }
}

class IpponShobuScoringRule extends BaseScoringRule {
  @override
  int determineTarget(RuleContext context) => 1;
}

// --- Hansoku Rule Modules ---
class LimitHansokuRule implements HansokuRule {
  @override
  RuleResult apply(RuleContext context) {
    int redHansoku = 0;
    int whiteHansoku = 0;
    int redIpponAdded = 0;
    int whiteIpponAdded = 0;
    
    final limit = context.tournamentConfig.hansoku.hansokuLimit;

    for (var e in context.events) {
      if (e.isCanceled) continue;
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) {
          redHansoku++;
          if (redHansoku % limit == 0) whiteIpponAdded++;
        } else {
          whiteHansoku++;
          if (whiteHansoku % limit == 0) redIpponAdded++;
        }
      }
    }

    final newState = MatchContext(
      redIppon: context.matchState.redIppon + redIpponAdded,
      whiteIppon: context.matchState.whiteIppon + whiteIpponAdded,
      redHansoku: redHansoku,
      whiteHansoku: whiteHansoku,
      isTimeUp: context.matchState.isTimeUp,
      targetIppon: context.matchState.targetIppon,
      hasHantei: context.matchState.hasHantei,
    );
    return RuleResult(allowed: true, transition: MatchTransition(updatedState: newState));
  }
}

class NoHansokuRule implements HansokuRule {
  @override
  RuleResult apply(RuleContext context) {
    return RuleResult(allowed: true, transition: MatchTransition(updatedState: context.matchState));
  }
}

// --- Time Rule Modules ---
class StandardTimeRule implements TimeRule {
  @override
  RuleResult apply(RuleContext context) {
    final newState = MatchContext(
      redIppon: context.matchState.redIppon,
      whiteIppon: context.matchState.whiteIppon,
      redHansoku: context.matchState.redHansoku,
      whiteHansoku: context.matchState.whiteHansoku,
      isTimeUp: context.clock <= 0,
      targetIppon: context.matchState.targetIppon,
      hasHantei: context.matchState.hasHantei,
    );
    return RuleResult(allowed: true, transition: MatchTransition(updatedState: newState));
  }
}

// --- Victory Rule Modules ---
abstract class BaseVictoryRule implements VictoryRule {
  MatchResultStatus handleTimeUpTie(RuleContext context);

  @override
  RuleResult apply(RuleContext context) {
    MatchResultStatus status = MatchResultStatus.inProgress;
    final state = context.matchState;

    // ★ Phase 8: イベント履歴に明示的な勝敗決定（判定・引き分け）があれば最優先で適用する
    for (var e in context.events) {
      if (e.isCanceled) continue;
      final eStr = e.toString().toLowerCase();
      
      // 判定勝ちイベントの評価
      if (e.isHantei || eStr.contains('hantei')) {
        if (e.side == Side.red) {
          return RuleResult(allowed: true, transition: MatchTransition(updatedState: state, resultStatus: MatchResultStatus.redWin));
        } else if (e.side == Side.white) {
          return RuleResult(allowed: true, transition: MatchTransition(updatedState: state, resultStatus: MatchResultStatus.whiteWin));
        }
      }
      
      // 引き分けイベントの評価
      if (eStr.contains('draw') || eStr.contains('hikiwake') || eStr.contains('tie')) {
        return RuleResult(allowed: true, transition: MatchTransition(updatedState: state, resultStatus: MatchResultStatus.draw));
      }
    }

    if (state.redIppon >= state.targetIppon) {
      status = MatchResultStatus.redWin;
    } else if (state.whiteIppon >= state.targetIppon) {
      status = MatchResultStatus.whiteWin;
    } else if (state.isTimeUp) {
      if (state.redIppon > state.whiteIppon) {
        status = MatchResultStatus.redWin;
      } else if (state.whiteIppon > state.redIppon) {
        status = MatchResultStatus.whiteWin;
      } else {
        status = handleTimeUpTie(context);
      }
    }

    return RuleResult(
      allowed: true, 
      transition: MatchTransition(updatedState: state, resultStatus: status)
    );
  }
}

class DrawVictoryRule extends BaseVictoryRule {
  @override
  MatchResultStatus handleTimeUpTie(RuleContext context) => MatchResultStatus.draw;
}

class HanteiVictoryRule extends BaseVictoryRule {
  @override
  MatchResultStatus handleTimeUpTie(RuleContext context) => MatchResultStatus.inProgress;
}