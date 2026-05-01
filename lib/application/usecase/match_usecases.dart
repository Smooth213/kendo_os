import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/match_model.dart';
import '../../domain/match/score_event.dart';
import '../../domain/match/match_rule.dart';
import '../../domain/kendo_rule_engine.dart';
import '../../domain/match/match_context.dart';
import '../../presentation/provider/match_provider.dart'; // ★ 追加: kendoRuleEngineProvider を参照するため

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
    
    // ★ 錬成モード（ランニングタイマー）への完全対応
    // ルール設定から「流し時間」のフラグを正確に取得
    final bool isRunningTimerMode = rule.isRunningTime;

    MatchModel updatedMatch = currentMatch.copyWith(
      events: updatedEvents,
      redScore: nextAnalysis.context.redIppon,
      whiteScore: nextAnalysis.context.whiteIppon,
      // ★ 改善：流し時間モードなら現在のタイマー状態をそのまま維持、通常モードなら「やめ」に合わせて時計を止める
      timerIsRunning: isRunningTimerMode ? currentMatch.timerIsRunning : false, 
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

/// ④ イベント履歴からの再構築 UseCase
/// 試合のイベント履歴を元に、現在のスコアやステータスを再計算して整合性を保証します。
class RebuildMatchFromEventsUseCase {
  final KendoRuleEngine _engine;
  RebuildMatchFromEventsUseCase(this._engine);

  MatchModel execute(MatchModel baseMatch, MatchRule rule) {
    final analysis = _engine.analyzeHistory(baseMatch.events, baseMatch, rule);
    final result = _engine.decideResult(analysis.context);

    // 歴史から再構築したデータも、最新のローカルデータとしてマーク
    return baseMatch.copyWith(
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      status: (result != MatchResultStatus.inProgress && baseMatch.status != 'approved')
          ? 'finished'
          : baseMatch.status,
      isDirty: true,
      lastUpdatedAt: DateTime.now(),
    );
  }
}

/// ⑤ ポイント表示計算 UseCase
/// 試合のイベント履歴を解析し、UI表示用のデータを生成します。
class CalculatePointDisplaysUseCase {
  final KendoRuleEngine _engine;
  CalculatePointDisplaysUseCase(this._engine);

  Map<Side, List<PointDisplay>> execute(MatchModel match) {
    // 移行元のロジックでは rule が null で渡されていたため、ここでも null を渡します
    return _engine.analyzeHistory(match.events, match, null).displays;
  }
}

// ★ DI (依存性の注入) 用のプロバイダ定義
final addScoreUseCaseProvider = Provider((ref) => AddScoreUseCase(ref.watch(kendoRuleEngineProvider)));
final undoScoreUseCaseProvider = Provider((ref) => UndoScoreUseCase(ref.watch(kendoRuleEngineProvider)));
final timeUpUseCaseProvider = Provider((ref) => TimeUpUseCase(ref.watch(kendoRuleEngineProvider)));

/// 新しく追加したUseCaseのプロバイダ
final rebuildMatchFromEventsUseCaseProvider =
    Provider((ref) => RebuildMatchFromEventsUseCase(ref.watch(kendoRuleEngineProvider)));
final calculatePointDisplaysUseCaseProvider =
    Provider((ref) => CalculatePointDisplaysUseCase(ref.watch(kendoRuleEngineProvider)));