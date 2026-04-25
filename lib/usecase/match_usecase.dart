import '../models/match_model.dart';
import '../models/score_event.dart';
import '../models/match_rule.dart';
import '../domain/kendo_rule_engine.dart';

class MatchUseCase {
  final KendoRuleEngine _engine;

  MatchUseCase(this._engine);

  /// ==========================================
  /// ★ 修正：ロジックをEngineへ完全委譲
  /// ==========================================
  // ★ 修正：戻り値の型を Map<Side, ...> に変更
  static Map<Side, List<PointDisplay>> calculatePointDisplays(MatchModel match, KendoRuleEngine engine) {
    // 自前でループを回さず、エンジンの解析結果を返すだけ
    return engine.analyzeHistory(match.events, match, null).displays;
  }

  /// 1. スコアを追加する
  MatchModel addScore(MatchModel currentMatch, ScoreEvent newEvent, MatchRule rule) {
    final analysis = _engine.analyzeHistory(currentMatch.events, currentMatch, rule);

    final validation = _engine.validateEvent(currentMatch, newEvent, analysis.context);
    if (!validation.isValid) {
      throw DomainException(validation.reason ?? '不正な操作です');
    }

    final updatedEvents = List<ScoreEvent>.from(currentMatch.events)..add(newEvent);
    
    // 追加後の状況を再解析
    final nextAnalysis = _engine.analyzeHistory(updatedEvents, currentMatch, rule);
    MatchModel updatedMatch = currentMatch.copyWith(
      events: updatedEvents,
      redScore: nextAnalysis.context.redIppon,
      whiteScore: nextAnalysis.context.whiteIppon,
      isDirty: true, // 変更があったので同期フラグを立てる
      lastUpdatedAt: DateTime.now(), // 更新日時を記録
    );

    final result = _engine.decideResult(nextAnalysis.context);
    if (result != MatchResultStatus.inProgress) {
      updatedMatch = updatedMatch.copyWith(status: 'finished');
    }

    return updatedMatch;
  }

  /// 2. Undo (★ Phase 4: 非破壊Undoアーキテクチャ)
  MatchModel undoLastEvent(MatchModel currentMatch, MatchRule rule) {
    if (currentMatch.events.isEmpty) return currentMatch;

    final updatedEvents = List<ScoreEvent>.from(currentMatch.events);
    
    // ★ リストの後ろから「まだキャンセルされていない実際のスコア」を探す
    final lastValidIndex = updatedEvents.lastIndexWhere((e) => !e.isCanceled && e.type != PointType.undo);
    
    // 取り消せるイベントがなければ何もしない
    if (lastValidIndex == -1) return currentMatch; 

    // ★ 物理削除やダミーイベントの追加ではなく、対象イベントのフラグだけを更新（論理削除）
    updatedEvents[lastValidIndex] = updatedEvents[lastValidIndex].copyWith(isCanceled: true);

    // 更新された歴史（キャンセル済みを無視するエンジン）で再解析
    final analysis = _engine.analyzeHistory(updatedEvents, currentMatch, rule);

    return currentMatch.copyWith(
      events: updatedEvents,
      status: 'in_progress',
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      isDirty: true, 
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// 3. 時間切れ時の処理
  MatchModel handleTimeUp(MatchModel currentMatch, bool isEnchoEnabled, MatchRule rule) {
    final analysis = _engine.analyzeHistory(currentMatch.events, currentMatch, rule);
    final timeUpContext = MatchContext(
      redIppon: analysis.context.redIppon,
      whiteIppon: analysis.context.whiteIppon,
      redHansoku: analysis.context.redHansoku,
      whiteHansoku: analysis.context.whiteHansoku,
      isTimeUp: true,
      targetIppon: analysis.context.targetIppon,
      hasHantei: rule.hasHantei, // ★ 追加
    );

    if (_engine.shouldEnterEncho(timeUpContext, isEnchoEnabled)) {
      final newNote = currentMatch.note.isEmpty ? '延長' : '${currentMatch.note}, 延長';
      
      // ★ Phase 7-1: 無制限なら0（カウントアップ用）、指定なら分数×60（カウントダウン用）
      final enchoSeconds = rule.isEnchoUnlimited ? 0 : (rule.enchoTimeMinutes * 60).toInt();

      return currentMatch.copyWith(
        matchType: '延長戦',
        note: newNote,
        remainingSeconds: enchoSeconds, // ★ タイマーのリセット
        timerIsRunning: false,          // 自動開始を防ぐため一旦止める
        isDirty: true,
        lastUpdatedAt: DateTime.now(),
      ); 
    } else {
      return currentMatch.copyWith(
        status: 'finished',
        isDirty: true,
        lastUpdatedAt: DateTime.now(),
      );
    }
  }

  /// ==========================================
  /// ★ Step 4-4: 究極のリプレイ機能（完全修復）
  /// 万が一Snapshotが壊れても、このメソッドで歴史から真実を復元する
  /// ==========================================
  MatchModel rebuildFromEvents(MatchModel baseMatch, MatchRule rule) {
    final analysis = _engine.analyzeHistory(baseMatch.events, baseMatch, rule);
    final result = _engine.decideResult(analysis.context);

    // 歴史から再構築したデータも、最新のローカルデータとしてマーク
    return baseMatch.copyWith(
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      status: (result != MatchResultStatus.inProgress && baseMatch.status != 'approved') 
          ? 'finished' : baseMatch.status,
      isDirty: true,
      lastUpdatedAt: DateTime.now(),
    );
  }
}