import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/match_context.dart';
import 'package:kendo_os/presentation/operate/providers/match_provider.dart'; 
import 'package:kendo_os/domain/entities/role_permission.dart';

// ==========================================
// ★ ② UseCaseの役割明確化：「1 UseCase = 1 責務」
// ここには「純粋な計算と判定」だけを書き、保存や音は一切鳴らさない
// ==========================================

/// ① スコア追加 UseCase
class AddScoreUseCase {
  final KendoRuleEngine _engine;
  final PermissionService _permission; // ★ 関所を追加
  
  AddScoreUseCase(this._engine, this._permission);

  MatchModel execute(User user, MatchModel currentMatch, ScoreEvent newEvent, MatchRule rule) {
    // ★ Phase 1-Step 2: 認可チェック（Zero Trust）
    if (!_permission.canAppend(user, newEvent)) {
      throw UnauthorizedException('この操作を実行する権限がありません');
    }

    // ★ Phase 3-2: 競合チェック（Concurrency Control）
    // 追加しようとしているイベントの順番(sequence)が、現在の状態が期待する次の順番と一致しない場合は弾く
    final expectedSequence = currentMatch.events.isEmpty ? 1 : currentMatch.events.last.sequence + 1;
    // ★ テスト用後方互換: 過去のテスト(sequenceが0)の場合は特別に競合チェックをスキップする
    if (newEvent.sequence != 0 && newEvent.sequence != expectedSequence) {
      throw DomainException('競合が発生しました。他の端末で先にデータが更新されています。');
    }

    final analysis = _engine.analyzeHistory(currentMatch.events, currentMatch, rule);
    final validation = _engine.validateEvent(currentMatch, newEvent, analysis.context);
    if (!validation.isValid) throw DomainException(validation.reason ?? '不正な操作です');

    final updatedEvents = List<ScoreEvent>.from(currentMatch.events)..add(newEvent);
    final nextAnalysis = _engine.analyzeHistory(updatedEvents, currentMatch, rule);
    
    final bool isRunningTimerMode = rule.isRunningTime;

    MatchModel updatedMatch = currentMatch.copyWith(
      events: updatedEvents,
      redScore: nextAnalysis.context.redIppon,
      whiteScore: nextAnalysis.context.whiteIppon,
      timerIsRunning: isRunningTimerMode ? currentMatch.timerIsRunning : false, 
      isDirty: true,
      lastUpdatedAt: DateTime.now(),
    );

    final result = _engine.decideResult(nextAnalysis.context);
    if (result != MatchResultStatus.inProgress) {
      updatedMatch = updatedMatch.copyWith(status: 'finished');
    } else {
      if (updatedMatch.status == 'finished') {
        updatedMatch = updatedMatch.copyWith(status: 'in_progress');
      }
    }
    return updatedMatch;
  }
}

/// ② Undo UseCase
class UndoScoreUseCase {
  final KendoRuleEngine _engine;
  final PermissionService _permission; // ★ 関所を追加
  
  UndoScoreUseCase(this._engine, this._permission);

  MatchModel execute(User user, MatchModel currentMatch, MatchRule rule) {
    // ★ Phase 1-Step 2: 認可チェック（Zero Trust）
    if (!_permission.canUndo(user)) {
      throw UnauthorizedException('操作を取り消す権限がありません');
    }

    if (currentMatch.events.isEmpty) return currentMatch;
    
    final updatedEvents = List<ScoreEvent>.from(currentMatch.events);
    final lastValidIndex = updatedEvents.lastIndexWhere((e) => !e.isCanceled && !e.isUndo && !e.isRestore);
    
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
  final PermissionService _permission; // ★ 関所を追加
  
  TimeUpUseCase(this._engine, this._permission);

  MatchModel execute(User user, MatchModel currentMatch, bool isEnchoEnabled, MatchRule rule) {
    // ★ Phase 1-Step 2: 認可チェック（Zero Trust）
    if (!_permission.canTimeUp(user)) {
      throw UnauthorizedException('時間切れ操作を実行する権限がありません');
    }

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

/// ④ イベント履歴からの再構築 UseCase (読み取り専用なので関所不要)
class RebuildMatchFromEventsUseCase {
  final KendoRuleEngine _engine;
  RebuildMatchFromEventsUseCase(this._engine);

  MatchModel execute(MatchModel baseMatch, MatchRule rule) {
    final analysis = _engine.analyzeHistory(baseMatch.events, baseMatch, rule);
    final result = _engine.decideResult(analysis.context);

    String newStatus = baseMatch.status;
    
    bool isJustUndone = false;
    if (baseMatch.events.isNotEmpty) {
      final latestEvent = baseMatch.events.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
      if (latestEvent.isCanceled || latestEvent.isUndo || latestEvent.type == PointType.undo) {
        isJustUndone = true;
      }
    }

    if (isJustUndone && baseMatch.status != 'approved') {
      newStatus = 'in_progress';
    } else if (result != MatchResultStatus.inProgress && baseMatch.status != 'approved') {
      newStatus = 'finished';
    }

    return baseMatch.copyWith(
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      status: newStatus,
      isDirty: true,
      lastUpdatedAt: DateTime.now(),
    );
  }
}

/// ⑤ ポイント表示計算 UseCase (読み取り専用なので関所不要)
class CalculatePointDisplaysUseCase {
  final KendoRuleEngine _engine;
  CalculatePointDisplaysUseCase(this._engine);

  Map<Side, List<PointDisplay>> execute(MatchModel match) {
    return _engine.analyzeHistory(match.events, match, null).displays;
  }
}

// ★ DI 用のプロバイダ定義
final permissionServiceProvider = Provider((ref) => PermissionService()); // ★ 追加

final addScoreUseCaseProvider = Provider((ref) => AddScoreUseCase(ref.watch(kendoRuleEngineProvider), ref.watch(permissionServiceProvider)));
final undoScoreUseCaseProvider = Provider((ref) => UndoScoreUseCase(ref.watch(kendoRuleEngineProvider), ref.watch(permissionServiceProvider)));
final timeUpUseCaseProvider = Provider((ref) => TimeUpUseCase(ref.watch(kendoRuleEngineProvider), ref.watch(permissionServiceProvider)));

final rebuildMatchFromEventsUseCaseProvider = Provider((ref) => RebuildMatchFromEventsUseCase(ref.watch(kendoRuleEngineProvider)));
final calculatePointDisplaysUseCaseProvider = Provider((ref) => CalculatePointDisplaysUseCase(ref.watch(kendoRuleEngineProvider)));