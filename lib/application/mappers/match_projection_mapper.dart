import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/domain/entities/score_event.dart';

class MatchProjectionMapper {
  static MatchProjection toProjection(MatchModel aggregate, MatchAnalysis analysis) {
    
    // UI用のマーク抽出（Stringのリストに変換）
    List<String> rMarks = analysis.displays[Side.red]?.map((d) => d.mark).toList() ?? [];
    List<String> wMarks = analysis.displays[Side.white]?.map((d) => d.mark).toList() ?? [];
    
    // 最初のポイント取得者を判定（簡易的）
    String firstPointSide = '';
    if (aggregate.events.isNotEmpty) {
      final firstPoint = aggregate.events.where((e) => e.isIppon && !e.isCanceled && !e.isUndo).firstOrNull;
      if (firstPoint != null) {
        firstPointSide = firstPoint.side == Side.red ? 'red' : 'white';
      }
    }

    return MatchProjection(
      id: aggregate.id,
      tournamentId: aggregate.tournamentId ?? '',
      matchOrder: aggregate.matchOrder ?? 0,
      matchType: aggregate.matchType,
      status: aggregate.status,
      groupName: '', // MatchModelにない場合は一旦空
      isKachinuki: aggregate.matchType == '勝ち抜き戦',
      redName: aggregate.redName,
      whiteName: aggregate.whiteName,
      redRemaining: aggregate.redRemaining,
      whiteRemaining: aggregate.whiteRemaining,
      
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      redDisplays: analysis.displays[Side.red] ?? [],
      whiteDisplays: analysis.displays[Side.white] ?? [],
      
      firstPointSide: firstPointSide,
      redPointMarks: rMarks,
      whitePointMarks: wMarks,
      
      remainingSeconds: aggregate.remainingSeconds,
      timerIsRunning: aggregate.timerIsRunning,
      note: aggregate.note,
    );
  }
}