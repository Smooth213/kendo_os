import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/score/score_event.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/presentation/shared/widgets/match_tables/point_mark_badge.dart';

/// 試合データのパースや計算を補助する共通ヘルパー
class MatchCalculatorHelper {
  /// MatchModel から PointMark のリストを生成します（運営側・書き込みモデル用）
  static Map<String, List<PointMark>> extractPointsFromModel(MatchModel match) {
    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(match.events, match, match.rule);
    
    final redPts = (analysis.displays[Side.red] ?? [])
        .map((d) => PointMark(mark: d.mark, isFirst: d.isFirstMatchPoint))
        .toList();
    final whitePts = (analysis.displays[Side.white] ?? [])
        .map((d) => PointMark(mark: d.mark, isFirst: d.isFirstMatchPoint))
        .toList();

    return {'red': redPts, 'white': whitePts};
  }

  /// MatchListProjection から PointMark のリストを生成します（観戦側・読み取りモデル用）
  static Map<String, List<PointMark>> extractPointsFromProjection(MatchListProjection match) {
    final List<PointMark> redPts = [];
    final List<PointMark> whitePts = [];
    
    final bool rIsFirst = (match.firstPointSide == 'red');
    final bool wIsFirst = (match.firstPointSide == 'white');

    for (int i = 0; i < match.redPointMarks.length; i++) {
      redPts.add(PointMark(mark: match.redPointMarks[i], isFirst: i == 0 && rIsFirst));
    }
    for (int i = 0; i < match.whitePointMarks.length; i++) {
      whitePts.add(PointMark(mark: match.whitePointMarks[i], isFirst: i == 0 && wIsFirst));
    }

    return {'red': redPts, 'white': whitePts};
  }
}