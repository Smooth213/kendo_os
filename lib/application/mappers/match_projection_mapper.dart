import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/entities/match_aggregate.dart';

class MatchProjectionMapper {
  
  // タイムライン生成
  static List<TimelineEvent> _buildTimeline(List<ScoreEvent> events) {
    return events.map((e) {
      String side = e.side == Side.red ? 'red' : (e.side == Side.white ? 'white' : 'none');
      String actionName = 'イベント';
      bool isImportant = false;

      if (e.isUndo) {
        actionName = '直前の判定を取り消し';
      } else if (e.isRestore) {
        actionName = 'バックアップから復元';
      } else if (e.isHansoku) {
        actionName = '反則';
      } else if (e.isFusen) {
        actionName = '不戦勝';
        isImportant = true;
      } else if (e.isHantei) {
        actionName = '判定勝ち';
        isImportant = true;
      } else if (e.strikeType != StrikeType.none) {
        actionName = {
          StrikeType.men: 'メン',
          StrikeType.kote: 'コテ',
          StrikeType.dou: 'ドウ',
          StrikeType.tsuki: 'ツキ'
        }[e.strikeType] ?? '打突';
        isImportant = true;
      }

      return TimelineEvent(
        id: e.id,
        timestamp: e.timestamp,
        side: side,
        actionName: actionName,
        isImportant: isImportant,
      );
    }).toList();
  }

  // モメンタム算出
  static double _calculateMomentum(MatchModel model, MatchAnalysis analysis) {
    double momentum = 0.0;
    momentum += (analysis.context.redIppon - analysis.context.whiteIppon) * 0.5;
    final redHansoku = model.events.where((e) => e.side == Side.red && e.isHansoku).length;
    final whiteHansoku = model.events.where((e) => e.side == Side.white && e.isHansoku).length;
    momentum -= (redHansoku - whiteHansoku) * 0.2;

    // ★ 修正: filterActiveEventsを使って有効イベントのみを考慮
    final engine = KendoRuleEngine();
    final activeEvents = engine.filterActiveEvents(model.events);
    if (activeEvents.isNotEmpty) {
      final last = activeEvents.last;
      if (last.isIppon) momentum += last.side == Side.red ? 0.3 : -0.3;
    }

    return momentum.clamp(-1.0, 1.0);
  }

  // ★ 互換性維持: 既存の画面が toProjection を探しているため、エイリアスとして残す
  static MatchProjection toProjection(MatchModel model, MatchAnalysis analysis) => toMatchProjection(model, analysis);

  // ★ Phase 5: 軽量版にも集計に必要なデータを詰め込む
  static MatchListProjection toListProjection(MatchModel model, MatchAnalysis analysis) {
    List<String> rMarks = analysis.displays[Side.red]?.map((d) => d.mark).toList() ?? [];
    List<String> wMarks = analysis.displays[Side.white]?.map((d) => d.mark).toList() ?? [];
    
    String firstPointSide = '';
    // ★ 修正: KendoRuleEngineのfilterActiveEventsを通して、Undoされたイベントを正確に除外する
    final engine = KendoRuleEngine();
    final activeEvents = engine.filterActiveEvents(model.events);
    final firstPoint = activeEvents.where((e) => e.isIppon).firstOrNull;
    if (firstPoint != null) {
      firstPointSide = firstPoint.side == Side.red ? 'red' : 'white';
    }

    return MatchListProjection(
      id: model.id,
      tournamentId: model.tournamentId ?? '',
      matchOrder: model.matchOrder ?? 0,
      matchType: model.matchType,
      status: model.status,
      redName: model.redName,
      whiteName: model.whiteName,
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      groupName: model.groupName ?? '',
      isKachinuki: model.isKachinuki,
      note: model.note,
      firstPointSide: firstPointSide,
      redPointMarks: rMarks,
      whitePointMarks: wMarks,
    );
  }

  // 詳細・記録用リッチ射影
  static MatchProjection toMatchProjection(MatchModel model, MatchAnalysis analysis) {
    // 表示用マーク（メ、コ、反など）のリスト生成
    List<String> rMarks = analysis.displays[Side.red]?.map((d) => d.mark).toList() ?? [];
    List<String> wMarks = analysis.displays[Side.white]?.map((d) => d.mark).toList() ?? [];
    
    // ★ 修正: 初取（先取）のサイド判定にも有効イベント抽出を適用
    String firstPointSide = '';
    if (model.events.isNotEmpty) {
      final engine = KendoRuleEngine();
      final activeEvents = engine.filterActiveEvents(model.events);
      final firstPoint = activeEvents.where((e) => e.isIppon).firstOrNull;
      if (firstPoint != null) {
        firstPointSide = firstPoint.side == Side.red ? 'red' : 'white';
      }
    }

    return MatchProjection(
      id: model.id,
      tournamentId: model.tournamentId ?? '',
      matchOrder: model.matchOrder ?? 0,
      matchType: model.matchType,
      status: model.status,
      groupName: model.groupName ?? '',
      isKachinuki: model.isKachinuki,
      redName: model.redName,
      whiteName: model.whiteName,
      redRemaining: model.redRemaining,
      whiteRemaining: model.whiteRemaining,
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      redDisplays: analysis.displays[Side.red] ?? [],
      whiteDisplays: analysis.displays[Side.white] ?? [],
      
      // ★ 復元された値をセット
      firstPointSide: firstPointSide,
      redPointMarks: rMarks,
      whitePointMarks: wMarks,

      remainingSeconds: model.remainingSeconds,
      timerIsRunning: model.timerIsRunning,
      note: model.note,
      timeline: _buildTimeline(model.events),
      momentum: _calculateMomentum(model, analysis),
    );
  }

  static MatchProjection fromAggregate(MatchAggregate aggregate, MatchModel baseModel) {
    final mergedModel = baseModel.copyWith(
      events: aggregate.events,
      status: aggregate.status,
      timerStartedAt: aggregate.timerStartedAt,
      accumulatedPauseDurationMs: aggregate.accumulatedPauseDurationMs,
    );
    
    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(mergedModel.events, mergedModel, mergedModel.rule);
    
    return toMatchProjection(mergedModel, analysis);
  }
}