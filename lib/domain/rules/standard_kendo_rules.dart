import 'package:kendo_os/domain/entities/match_context.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule_interface.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';

// ==========================================
// ★ Phase C: データ駆動型の標準剣道ルール実装
// すべてのハードコードを排除し、MatchRuleのパラメータに従って動く
// ==========================================

class StandardScoringRule implements ScoringRule {
  @override
  MatchContext apply(List<ScoreEvent> events, MatchContext currentContext, MatchRule? rule) {
    int red = 0;
    int white = 0;
    
    // C-3: 勝利に必要な本数を動的に決定
    int currentTarget = currentContext.targetIppon;
    if (rule != null) {
      if (rule.isIpponShobu) {
        currentTarget = 1;
      } else if (rule.ipponLimit > 0) {
        currentTarget = rule.ipponLimit;
      }
    }

    for (var e in events) {
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
    return MatchContext(
      redIppon: red,
      whiteIppon: white,
      redHansoku: currentContext.redHansoku,
      whiteHansoku: currentContext.whiteHansoku,
      isTimeUp: currentContext.isTimeUp,
      targetIppon: currentTarget, // 計算されたターゲットをコンテキストに上書き
      hasHantei: rule?.hasHantei ?? currentContext.hasHantei,
    );
  }
}

class StandardHansokuRule implements HansokuRule {
  @override
  MatchContext apply(List<ScoreEvent> events, MatchContext currentContext, MatchRule? rule) {
    int redHansoku = 0;
    int whiteHansoku = 0;
    int redIpponAdded = 0;
    int whiteIpponAdded = 0;
    
    // C-3: 反則何回で1本になるかを動的に決定（デフォルトは2回）
    final limit = rule?.hansokuLimit ?? 2;

    for (var e in events) {
      if (e.isCanceled) continue;
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) {
          redHansoku++;
          // limit（通常2）に到達するごとに相手に1本追加
          if (limit > 0 && redHansoku % limit == 0) whiteIpponAdded++;
        } else {
          whiteHansoku++;
          if (limit > 0 && whiteHansoku % limit == 0) redIpponAdded++;
        }
      }
    }

    return MatchContext(
      redIppon: currentContext.redIppon + redIpponAdded,
      whiteIppon: currentContext.whiteIppon + whiteIpponAdded,
      redHansoku: redHansoku,
      whiteHansoku: whiteHansoku,
      isTimeUp: currentContext.isTimeUp,
      targetIppon: currentContext.targetIppon,
      hasHantei: currentContext.hasHantei,
    );
  }
}

class StandardTimeRule implements TimeRule {
  @override
  MatchContext apply(MatchContext currentContext, double remainingSeconds, MatchRule? rule) {
    return MatchContext(
      redIppon: currentContext.redIppon,
      whiteIppon: currentContext.whiteIppon,
      redHansoku: currentContext.redHansoku,
      whiteHansoku: currentContext.whiteHansoku,
      isTimeUp: remainingSeconds <= 0,
      targetIppon: currentContext.targetIppon,
      hasHantei: currentContext.hasHantei,
    );
  }
}

class StandardVictoryRule implements VictoryRule {
  @override
  MatchResultStatus evaluate(MatchContext context, int redHantei, int whiteHantei, MatchRule? rule) {
    // 1. 規定本数（データから計算済み）到達の判定
    if (context.redIppon >= context.targetIppon) return MatchResultStatus.redWin;
    if (context.whiteIppon >= context.targetIppon) return MatchResultStatus.whiteWin;

    // 2. 時間切れ時の判定
    if (context.isTimeUp) {
      if (context.redIppon > context.whiteIppon) return MatchResultStatus.redWin;
      if (context.whiteIppon > context.redIppon) return MatchResultStatus.whiteWin;
      
      // 3. 判定(Hantei)による決着
      if (context.hasHantei) {
        return MatchResultStatus.inProgress;
      }
      return MatchResultStatus.draw;
    }

    return MatchResultStatus.inProgress;
  }
}