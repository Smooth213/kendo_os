import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'pdf_point_data.dart';

class PdfViewModel {
  static String toMark(PointType t) {
    switch (t) {
      case PointType.men:
        return 'メ';
      case PointType.kote:
        return 'コ';
      case PointType.doIdo:
        return 'ド';
      case PointType.tsuki:
        return 'ツ';
      case PointType.hansoku:
        return '反';
      case PointType.fusen:
        return '◯';
      default:
        return '';
    }
  }

  static Map<String, List<PdfPointData>> calculatePointsRaw(dynamic match) {
    List<PdfPointData> redPts = [], whitePts = [];

    if (match is MatchModel) {
      final engine = KendoRuleEngine();
      final analysis = engine.analyzeHistory(match.events, match, match.rule);

      for (var d in analysis.displays[Side.red] ?? []) {
        redPts.add(PdfPointData(d.mark, d.isFirstMatchPoint));
      }
      for (var d in analysis.displays[Side.white] ?? []) {
        whitePts.add(PdfPointData(d.mark, d.isFirstMatchPoint));
      }
    } else {
      try {
        bool rIsFirst = (match.firstPointSide == 'red');
        bool wIsFirst = (match.firstPointSide == 'white');
        for (int i = 0; i < (match.redPointMarks as List).length; i++) {
          redPts.add(PdfPointData(match.redPointMarks[i], i == 0 && rIsFirst));
        }
        for (int i = 0; i < (match.whitePointMarks as List).length; i++) {
          whitePts.add(
            PdfPointData(match.whitePointMarks[i], i == 0 && wIsFirst),
          );
        }
      } catch (_) {}
    }
    return {'red': redPts, 'white': whitePts};
  }

  static List<String> extractTechsForPdf(
    List<ScoreEvent> events,
    bool isRed,
    int count,
  ) {
    List<String> res = [];
    int hCount = 0;
    final activeEvents = KendoRuleEngine().filterActiveEvents(events);
    for (var e in activeEvents) {
      if (e.type == PointType.hansoku) {
        hCount++;
        if (hCount % 2 == 0) {
          if ((e.side == Side.red && !isRed) ||
              (e.side == Side.white && isRed)) {
            res.add('反');
          }
        }
      } else if ((e.side == Side.red) == isRed) {
        res.add(toMark(e.type));
      }
    }
    while (res.length < count) {
      res.add('◯');
    }
    return res.take(count).toList();
  }

  static Map<String, List<dynamic>> groupByMatchup(List<dynamic> matches) {
    final matchups = <String, List<dynamic>>{};
    for (var m in matches) {
      final t1 = m.redName.split(':').first.trim();
      final t2 = m.whiteName.split(':').first.trim();
      final key = [t1, t2]..sort();
      matchups.putIfAbsent(key.join(' vs '), () => []).add(m);
    }
    return matchups;
  }
}
