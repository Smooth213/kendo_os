import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../models/score_event.dart';
import '../models/match_rule.dart';
import '../domain/kendo_rule_engine.dart';
import '../providers/match_provider.dart'; // ★ 追加: kendoRuleEngineProvider を参照するため

// ==========================================
// ★ ② UseCaseの役割明確化：「1 UseCase = 1 責務」
// ここには「純粋な計算と判定」だけを書き、保存や音は一切鳴らさない
// ==========================================

/// ① スコア追加 UseCase
class AddScoreUseCase {
  final KendoRuleEngine _engine;
  AddScoreUseCase(this._engine);

  MatchModel execute(MatchModel currentMatch, ScoreEvent newEvent, MatchRule rule) {
    final analysis = _engine.analyzeHistory(currentMatch.events, currentMatch, rule);
    final validation = _engine.validateEvent(currentMatch, newEvent, analysis.context);
    if (!validation.isValid) throw DomainException(validation.reason ?? '不正な操作です');

    final updatedEvents = List<ScoreEvent>.from(currentMatch.events)..add(newEvent);
    final nextAnalysis = _engine.analyzeHistory(updatedEvents, currentMatch, rule);
    
    MatchModel updatedMatch = currentMatch.copyWith(
      events: updatedEvents,
      redScore: nextAnalysis.context.redIppon,
      whiteScore: nextAnalysis.context.whiteIppon,
      isDirty: true,
      lastUpdatedAt: DateTime.now(),
    );

    final result = _engine.decideResult(nextAnalysis.context);
    if (result != MatchResultStatus.inProgress) {
      updatedMatch = updatedMatch.copyWith(status: 'finished');
    }
    return updatedMatch;
  }
}

/// ② Undo UseCase
class UndoScoreUseCase {
  final KendoRuleEngine _engine;
  UndoScoreUseCase(this._engine);

  MatchModel execute(MatchModel currentMatch, MatchRule rule) {
    if (currentMatch.events.isEmpty) return currentMatch;
    
    final updatedEvents = List<ScoreEvent>.from(currentMatch.events);
    final lastValidIndex = updatedEvents.lastIndexWhere((e) => !e.isCanceled && e.type != PointType.undo && e.type != PointType.restore);
    
    if (lastValidIndex == -1) {
      final analysis = _engine.analyzeHistory(updatedEvents, currentMatch, rule);
      return currentMatch.copyWith(redScore: analysis.context.redIppon, whiteScore: analysis.context.whiteIppon, isDirty: true, lastUpdatedAt: DateTime.now());
    }

    updatedEvents[lastValidIndex] = updatedEvents[lastValidIndex].copyWith(isCanceled: true);
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
}

/// ③ 時間切れ処理 UseCase
class TimeUpUseCase {
  final KendoRuleEngine _engine;
  TimeUpUseCase(this._engine);

  MatchModel execute(MatchModel currentMatch, bool isEnchoEnabled, MatchRule rule) {
    final analysis = _engine.analyzeHistory(currentMatch.events, currentMatch, rule);
    final timeUpContext = MatchContext(
      redIppon: analysis.context.redIppon, whiteIppon: analysis.context.whiteIppon,
      redHansoku: analysis.context.redHansoku, whiteHansoku: analysis.context.whiteHansoku,
      isTimeUp: true, targetIppon: analysis.context.targetIppon, hasHantei: rule.hasHantei,
    );

    if (_engine.shouldEnterEncho(timeUpContext, isEnchoEnabled)) {
      final newNote = currentMatch.note.isEmpty ? '延長' : '${currentMatch.note}, 延長';
      final enchoSeconds = rule.isEnchoUnlimited ? 0 : (rule.enchoTimeMinutes * 60).toInt();
      return currentMatch.copyWith(
        matchType: '延長戦', note: newNote, remainingSeconds: enchoSeconds,
        timerIsRunning: false, isDirty: true, lastUpdatedAt: DateTime.now(),
      ); 
    } else {
      return currentMatch.copyWith(status: 'finished', isDirty: true, lastUpdatedAt: DateTime.now());
    }
  }
}

// ★ DI (依存性の注入) 用のプロバイダ定義
final addScoreUseCaseProvider = Provider((ref) => AddScoreUseCase(ref.watch(kendoRuleEngineProvider)));
final undoScoreUseCaseProvider = Provider((ref) => UndoScoreUseCase(ref.watch(kendoRuleEngineProvider)));
final timeUpUseCaseProvider = Provider((ref) => TimeUpUseCase(ref.watch(kendoRuleEngineProvider)));