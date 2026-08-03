import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

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
  static Map<String, List<PointMark>> extractPointsFromProjection(
    MatchListProjection match,
  ) {
    final List<PointMark> redPts = [];
    final List<PointMark> whitePts = [];

    final bool rIsFirst = (match.firstPointSide == 'red');
    final bool wIsFirst = (match.firstPointSide == 'white');

    for (int i = 0; i < match.redPointMarks.length; i++) {
      redPts.add(
        PointMark(mark: match.redPointMarks[i], isFirst: i == 0 && rIsFirst),
      );
    }
    for (int i = 0; i < match.whitePointMarks.length; i++) {
      whitePts.add(
        PointMark(mark: match.whitePointMarks[i], isFirst: i == 0 && wIsFirst),
      );
    }

    return {'red': redPts, 'white': whitePts};
  }

  /// MatchModel から延長戦判定を取得します
  static bool isEnchoFromModel(MatchModel match) {
    final isFinished = match.status == 'approved' || match.status == 'finished';
    if (!isFinished) return false;
    if (match.note.contains('延長')) return true;
    if (match.matchType == '代表戦' ||
        match.matchType == '大将延長戦' ||
        match.matchType.contains('代表') ||
        match.matchType.contains('延長')) {
      return true;
    }
    if (match.hasExtension && match.redScore != match.whiteScore) {
      return true;
    }
    return false;
  }

  /// MatchListProjection から延長戦判定を取得します
  static bool isEnchoFromProjection(MatchListProjection match) {
    final isFinished = match.status == 'approved' || match.status == 'finished';
    if (!isFinished) return false;
    if (match.note.contains('延長')) return true;
    if (match.matchType == '代表戦' ||
        match.matchType == '大将延長戦' ||
        match.matchType.contains('代表') ||
        match.matchType.contains('延長')) {
      return true;
    }
    return false;
  }
}
