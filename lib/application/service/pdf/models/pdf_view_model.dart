import '../../../../domain/match/score_event.dart';
import '../../../../models/match_model.dart';
import 'pdf_point_data.dart';

class PdfViewModel {
  static String toMark(PointType t) {
    switch (t) {
      case PointType.men: return 'メ';
      case PointType.kote: return 'コ';
      case PointType.doIdo: return 'ド';
      case PointType.tsuki: return 'ツ';
      case PointType.hansoku: return '反';
      case PointType.fusen: return '◯';
      default: return '';
    }
  }

  static Map<String, List<PdfPointData>> calculatePointsRaw(MatchModel match) {
    List<PdfPointData> redPts = [], whitePts = [];
    int rH = 0, wH = 0;
    bool isFirst = true; 
    for (var e in match.events) {
      if (e.type == PointType.undo) continue;
      if (e.isCanceled) continue; 
      
      String mark = '';
      Side side = e.side;
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) {
          rH++;
          if (rH == 2 || rH == 4) { mark = '反'; side = Side.white; } else { continue; }
        } else if (e.side == Side.white) {
          wH++;
          if (wH == 2 || wH == 4) { mark = '反'; side = Side.red; } else { continue; }
        }
      } else {
        mark = toMark(e.type);
      }
      
      if (side == Side.red) {
        redPts.add(PdfPointData(mark, isFirst));
        isFirst = false;
      } else if (side == Side.white) {
        whitePts.add(PdfPointData(mark, isFirst));
        isFirst = false;
      }
    }
    return {'red': redPts, 'white': whitePts};
  }

  static List<String> extractTechsForPdf(List<ScoreEvent> events, bool isRed, int count) {
    List<String> res = [];
    int hCount = 0;
    for (var e in events) {
      if (e.type == PointType.undo || e.isCanceled) continue;
      if (e.type == PointType.hansoku) {
        hCount++;
        if (hCount % 2 == 0) { if ((e.side == Side.red && !isRed) || (e.side == Side.white && isRed)) res.add('反'); }
      } else if ((e.side == Side.red) == isRed) {
        res.add(toMark(e.type));
      }
    }
    while (res.length < count) { res.add('◯'); }
    return res.take(count).toList();
  }

  static Map<String, List<MatchModel>> groupByMatchup(List<MatchModel> matches) {
    final matchups = <String, List<MatchModel>>{};
    for (var m in matches) {
      final t1 = m.redName.split(':').first.trim();
      final t2 = m.whiteName.split(':').first.trim();
      final key = [t1, t2]..sort();
      matchups.putIfAbsent(key.join(' vs '), () => []).add(m);
    }
    return matchups;
  }
}