import 'package:uuid/uuid.dart'; // ★ 追加: UndoイベントのID生成用
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
    );

    final result = _engine.decideResult(nextAnalysis.context);
    if (result != MatchResultStatus.inProgress) {
      updatedMatch = updatedMatch.copyWith(status: 'finished');
    }

    return updatedMatch;
  }

  /// 2. Undo
  MatchModel undoLastEvent(MatchModel currentMatch, MatchRule rule) {
    if (currentMatch.events.isEmpty) return currentMatch;

    final undoEvent = ScoreEvent(
      id: const Uuid().v4(),
      side: Side.none, // ★ 修正：Side.none Enumを使用
      type: PointType.undo,
      timestamp: DateTime.now(),
      userId: currentMatch.scorerId,
      sequence: currentMatch.events.last.sequence + 1,
    );

    final updatedEvents = List<ScoreEvent>.from(currentMatch.events)..add(undoEvent);
    // ★ Step 7-3: Undo時はデバウンス用の記録をクリアし、即座に次の入力ができるようにする
    // (間違えてUndoした場合のリカバリ速度を優先)
    // ※ MatchCommand のインスタンスにアクセスできる場合はそちらをクリア
    final analysis = _engine.analyzeHistory(updatedEvents, currentMatch, rule);

    return currentMatch.copyWith(
      events: updatedEvents,
      status: 'in_progress',
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
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
    );

    if (_engine.shouldEnterEncho(timeUpContext, isEnchoEnabled)) {
      // ★ 修正：統合テストの期待値に合わせ、note に「延長」を記録するように変更
      final newNote = currentMatch.note.isEmpty ? '延長' : '${currentMatch.note}, 延長';
      return currentMatch.copyWith(
        matchType: '延長戦',
        note: newNote,
      ); 
    } else {
      return currentMatch.copyWith(status: 'finished');
    }
  }

  /// ==========================================
  /// ★ Step 4-4: 究極のリプレイ機能（完全修復）
  /// 万が一Snapshotが壊れても、このメソッドで歴史から真実を復元する
  /// ==========================================
  MatchModel rebuildFromEvents(MatchModel baseMatch, MatchRule rule) {
    final analysis = _engine.analyzeHistory(baseMatch.events, baseMatch, rule);
    final result = _engine.decideResult(analysis.context);

    // ★ 修正：現在のステータスを維持しつつ、スコアのみを「歴史の真実」に強制同期させる
    return baseMatch.copyWith(
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      status: (result != MatchResultStatus.inProgress && baseMatch.status != 'approved') 
          ? 'finished' : baseMatch.status,
    );
  }
}