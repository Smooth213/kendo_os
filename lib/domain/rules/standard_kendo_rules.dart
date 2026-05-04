import 'package:kendo_os/domain/entities/match_context.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule_interface.dart';

// ==========================================
// ★ Phase 6: Rule分割 - 標準剣道ルールの具体実装
// ==========================================

class StandardScoringRule implements ScoringRule {
  @override
  MatchContext apply(List<ScoreEvent> events, MatchContext currentContext) {
    int red = 0;
    int white = 0;
    for (var e in events) {
      if (e.isCanceled) continue;
      // ★ 修正: hantei を除外せず、得点としてカウントさせる
      if (e.type != PointType.hansoku && e.type != PointType.fusen) {
        if (e.side == Side.red) red++;
        if (e.side == Side.white) white++;
      }
      if (e.type == PointType.fusen) {
        if (e.side == Side.red) red += currentContext.targetIppon.toInt();
        if (e.side == Side.white) white += currentContext.targetIppon.toInt();
      }
    }
    return MatchContext(
      redIppon: red,
      whiteIppon: white,
      redHansoku: currentContext.redHansoku,
      whiteHansoku: currentContext.whiteHansoku,
      isTimeUp: currentContext.isTimeUp,
      targetIppon: currentContext.targetIppon,
      hasHantei: currentContext.hasHantei,
    );
  }
}

class StandardHansokuRule implements HansokuRule {
  @override
  MatchContext apply(List<ScoreEvent> events, MatchContext currentContext) {
    int redHansoku = 0;
    int whiteHansoku = 0;
    int redIpponAdded = 0;
    int whiteIpponAdded = 0;

    for (var e in events) {
      if (e.isCanceled) continue;
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) {
          redHansoku++;
          if (redHansoku % 2 == 0) whiteIpponAdded++;
        } else {
          whiteHansoku++;
          if (whiteHansoku % 2 == 0) redIpponAdded++;
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
  MatchContext apply(MatchContext currentContext, double remainingSeconds) {
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
  MatchResultStatus evaluate(MatchContext context, int redHantei, int whiteHantei) {
    // 1. 規定本数到達の判定
    if (context.redIppon >= context.targetIppon) return MatchResultStatus.redWin;
    if (context.whiteIppon >= context.targetIppon) return MatchResultStatus.whiteWin;

    // 2. 時間切れ時の判定
    if (context.isTimeUp) {
      if (context.redIppon > context.whiteIppon) return MatchResultStatus.redWin;
      if (context.whiteIppon > context.redIppon) return MatchResultStatus.whiteWin;
      
      // 3. 判定(Hantei)による決着
      if (context.hasHantei) {
        // Hanteiはスコアとして入るようになったため、ここに到達するのは判定入力待ちの同点状態のみ。
        return MatchResultStatus.inProgress;
      }
      return MatchResultStatus.draw;
    }

    return MatchResultStatus.inProgress;
  }
}