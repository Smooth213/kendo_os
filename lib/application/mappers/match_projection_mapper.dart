import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/entities/match_aggregate.dart';

class MatchProjectionMapper {
  
  // ==========================================
  // ★ Phase 4-Step 2: タイムラインの生成
  // ScoreEventをUI表示用のTimelineEventに翻訳する
  // ==========================================
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

  // ==========================================
  // ★ Phase 4-Step 3: モメンタム（勢い）の算出
  // 直近のイベントやスコアから、どちらが優勢かを数値化（-1.0 〜 +1.0）
  // ==========================================
  static double _calculateMomentum(MatchModel model, MatchAnalysis analysis) {
    double momentum = 0.0;
    
    // スコアによる優勢度（一本取っている方が強い）
    momentum += (analysis.context.redIppon - analysis.context.whiteIppon) * 0.5;

    // 反則による劣勢度（反則している方は勢いが下がる）
    final redHansoku = model.events.where((e) => e.side == Side.red && e.isHansoku && !e.isCanceled).length;
    final whiteHansoku = model.events.where((e) => e.side == Side.white && e.isHansoku && !e.isCanceled).length;
    momentum -= (redHansoku - whiteHansoku) * 0.2;

    // 直近のイベントによる勢い（直近に技を決めた方に勢いが傾く）
    final recentStrikes = model.events.where((e) => e.isIppon && !e.isCanceled).toList();
    if (recentStrikes.isNotEmpty) {
      momentum += recentStrikes.last.side == Side.red ? 0.3 : -0.3;
    }

    // 値を -1.0 〜 +1.0 に丸める
    if (momentum > 1.0) return 1.0;
    if (momentum < -1.0) return -1.0;
    return momentum;
  }


  // 既存のメソッド（新機能を追加）
  static MatchProjection toProjection(MatchModel aggregate, MatchAnalysis analysis) {
    List<String> rMarks = analysis.displays[Side.red]?.map((d) => d.mark).toList() ?? [];
    List<String> wMarks = analysis.displays[Side.white]?.map((d) => d.mark).toList() ?? [];
    
    String firstPointSide = '';
    if (aggregate.events.isNotEmpty) {
      final firstPoint = aggregate.events.where((e) => e.isIppon && !e.isCanceled && !e.isUndo).firstOrNull;
      if (firstPoint != null) {
        firstPointSide = firstPoint.side == Side.red ? 'red' : 'white';
      }
    }

    // ★ Phase 4-Step 2 & 3 の結果を取得
    final timeline = _buildTimeline(aggregate.events);
    final momentum = _calculateMomentum(aggregate, analysis);

    return MatchProjection(
      id: aggregate.id,
      tournamentId: aggregate.tournamentId ?? '',
      matchOrder: aggregate.matchOrder ?? 0,
      matchType: aggregate.matchType,
      status: aggregate.status,
      groupName: '', 
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
      
      // ★ 追加
      timeline: timeline,
      momentum: momentum,
    );
  }

  static MatchProjection fromAggregate(MatchAggregate aggregate, MatchModel baseModel) {
    final mergedModel = baseModel.copyWith(
      events: aggregate.events,
      status: aggregate.status,
      remainingSeconds: aggregate.remainingSeconds,
      timerIsRunning: aggregate.timerIsRunning,
    );
    
    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(mergedModel.events, mergedModel, mergedModel.rule);
    
    return toProjection(mergedModel, analysis);
  }
}