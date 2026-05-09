import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/match_context.dart';
import 'package:kendo_os/presentation/operate/providers/match_provider.dart'; 
import 'package:kendo_os/domain/entities/role_permission.dart';
import 'package:kendo_os/domain/entities/match_state.dart'; // ★ Phase 1: FSMのインポート

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
    // 認可チェック
    if (!_permission.canAppend(user, newEvent)) {
      throw UnauthorizedException('この操作を実行する権限がありません');
    }

    // ★ Phase 10: イベントに当時のルールバージョンを刻み込む
    final finalEvent = newEvent.copyWith(ruleVersion: rule.toRuleConfig.schemaVersion);

    // 競合チェック
    final expectedSequence = currentMatch.events.isEmpty ? 1 : currentMatch.events.last.sequence + 1;
    if (finalEvent.sequence != 0 && finalEvent.sequence != expectedSequence) {
      throw DomainException('競合が発生しました。他の端末で先にデータが更新されています。');
    }

    final analysis = _engine.analyzeHistory(currentMatch.events, currentMatch, rule);
    final validation = _engine.validateEvent(currentMatch, finalEvent, analysis.context);
    if (!validation.isValid) throw DomainException(validation.reason ?? '不正な操作です');

    final updatedEvents = List<ScoreEvent>.from(currentMatch.events);
    final updatedPendingEvents = List<ScoreEvent>.from(currentMatch.pendingEvents);

    if (finalEvent.isUndo || finalEvent.type == PointType.undo) {
      int skipCount = 0;
      for (int i = updatedEvents.length - 1; i >= 0; i--) {
        if (updatedEvents[i].isCanceled) continue;
        if (updatedEvents[i].isUndo || updatedEvents[i].type == PointType.undo) {
          skipCount++;
          continue;
        }
        if (updatedEvents[i].isRestore || updatedEvents[i].type == PointType.restore) {
          skipCount = skipCount > 0 ? skipCount - 1 : 0;
          continue;
        }
        
        if (skipCount == 0) {
          updatedEvents[i] = updatedEvents[i].copyWith(isCanceled: true);
          final pIndex = updatedPendingEvents.indexWhere((e) => e.id == updatedEvents[i].id);
          if (pIndex != -1) updatedPendingEvents[pIndex] = updatedEvents[i];
          break; // 直近1件のみを取り消す
        } else {
          skipCount--;
        }
      }
    } else if (finalEvent.isRestore || finalEvent.type == PointType.restore) {
      // Redo互換: isCanceled を false に戻す
      for (int i = updatedEvents.length - 1; i >= 0; i--) {
        if (updatedEvents[i].isCanceled) {
          updatedEvents[i] = updatedEvents[i].copyWith(isCanceled: false);
          final pIndex = updatedPendingEvents.indexWhere((e) => e.id == updatedEvents[i].id);
          if (pIndex != -1) updatedPendingEvents[pIndex] = updatedEvents[i];
          break;
        }
      }
    }

    updatedEvents.add(finalEvent);
    updatedPendingEvents.add(finalEvent);

    final nextAnalysis = _engine.analyzeHistory(updatedEvents, currentMatch, rule);
    
    MatchLifecycleState currentState = MatchLifecycleStateLegacyExt.fromLegacyString(currentMatch.status);

    if (currentState == MatchLifecycleState.ready || currentState == MatchLifecycleState.notStarted || currentState == MatchLifecycleState.waitingForPlayers) {
      currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.startMatch);
    }

    final result = _engine.decideResult(nextAnalysis.context);
    if (result != MatchResultStatus.inProgress) {
      if (currentState != MatchLifecycleState.completed && currentState != MatchLifecycleState.fusen) {
        currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.decideWinner);
      }
    } else {
      if (currentState == MatchLifecycleState.completed || currentState == MatchLifecycleState.fusen) {
        currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.undo);
      }
    }

    final bool isRunningTimerMode = rule.isRunningTime;

    return currentMatch.copyWith(
      events: updatedEvents,
      redScore: nextAnalysis.context.redIppon,
      whiteScore: nextAnalysis.context.whiteIppon,
      timerIsRunning: isRunningTimerMode ? currentMatch.timerIsRunning : false, 
      status: currentState.toLegacyString(),
      syncState: SyncState.localOnly, 
      pendingEvents: updatedPendingEvents, 
      lastUpdatedAt: DateTime.now(),
    );
  }
}

/// ② Undo UseCase
class UndoScoreUseCase {
  final KendoRuleEngine _engine;
  final PermissionService _permission;
  
  UndoScoreUseCase(this._engine, this._permission);

  MatchModel execute(User user, MatchModel currentMatch, MatchRule rule) {
    if (!_permission.canUndo(user)) {
      throw UnauthorizedException('操作を取り消す権限がありません');
    }

    if (currentMatch.events.isEmpty) return currentMatch;
    
    final newSequence = currentMatch.events.isEmpty ? 1 : currentMatch.events.last.sequence + 1;
    
    final undoEvent = ScoreEvent(
      id: 'undo-${DateTime.now().microsecondsSinceEpoch}',
      schemaVersion: 2,
      side: Side.none,
      strikeType: StrikeType.none,
      isUndo: true,
      timestamp: DateTime.now(),
      sequence: newSequence,
      userId: user.id,
      ruleVersion: rule.toRuleConfig.schemaVersion, // ★ Phase 10
    );

    final updatedEvents = List<ScoreEvent>.from(currentMatch.events);
    final updatedPendingEvents = List<ScoreEvent>.from(currentMatch.pendingEvents);

    int skipCount = 0;
    for (int i = updatedEvents.length - 1; i >= 0; i--) {
      if (updatedEvents[i].isCanceled) continue;
      if (updatedEvents[i].isUndo || updatedEvents[i].type == PointType.undo) {
        skipCount++;
        continue;
      }
      if (updatedEvents[i].isRestore || updatedEvents[i].type == PointType.restore) {
        skipCount = skipCount > 0 ? skipCount - 1 : 0;
        continue;
      }
      if (skipCount == 0) {
        updatedEvents[i] = updatedEvents[i].copyWith(isCanceled: true);
        final pIndex = updatedPendingEvents.indexWhere((e) => e.id == updatedEvents[i].id);
        if (pIndex != -1) updatedPendingEvents[pIndex] = updatedEvents[i];
        break;
      } else {
        skipCount--;
      }
    }

    updatedEvents.add(undoEvent);
    updatedPendingEvents.add(undoEvent);

    final analysis = _engine.analyzeHistory(updatedEvents, currentMatch, rule);

    MatchLifecycleState currentState = MatchLifecycleStateLegacyExt.fromLegacyString(currentMatch.status);
    if (currentState == MatchLifecycleState.completed || currentState == MatchLifecycleState.fusen) {
      currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.undo);
    }

    return currentMatch.copyWith(
      events: updatedEvents, 
      status: currentState.toLegacyString(), 
      pendingEvents: updatedPendingEvents,
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      syncState: SyncState.localOnly,
      lastUpdatedAt: DateTime.now(),
    );
  }
}

/// ★ Phase 2-3: Redo(やり直し) UseCase
class RedoScoreUseCase {
  final KendoRuleEngine _engine;
  final PermissionService _permission;
  
  RedoScoreUseCase(this._engine, this._permission);

  MatchModel execute(User user, MatchModel currentMatch, MatchRule rule) {
    if (!_permission.canUndo(user)) { 
      throw UnauthorizedException('操作をやり直す権限がありません');
    }

    if (currentMatch.events.isEmpty) return currentMatch;
    
    final newSequence = currentMatch.events.last.sequence + 1;
    final redoEvent = ScoreEvent(
      id: 'redo-${DateTime.now().microsecondsSinceEpoch}',
      schemaVersion: 2,
      side: Side.none,
      strikeType: StrikeType.none,
      isRestore: true, 
      timestamp: DateTime.now(),
      sequence: newSequence,
      userId: user.id,
      ruleVersion: rule.toRuleConfig.schemaVersion, // ★ Phase 10
    );

    final updatedEvents = List<ScoreEvent>.from(currentMatch.events)..add(redoEvent);
    final updatedPendingEvents = List<ScoreEvent>.from(currentMatch.pendingEvents)..add(redoEvent);
    final analysis = _engine.analyzeHistory(updatedEvents, currentMatch, rule);

    MatchLifecycleState currentState = MatchLifecycleStateLegacyExt.fromLegacyString(currentMatch.status);
    final result = _engine.decideResult(analysis.context);
    
    if (result != MatchResultStatus.inProgress) {
      if (currentState != MatchLifecycleState.completed && currentState != MatchLifecycleState.fusen) {
        currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.decideWinner);
      }
    } else {
      if (currentState == MatchLifecycleState.completed || currentState == MatchLifecycleState.fusen) {
        currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.undo);
      }
    }

    return currentMatch.copyWith(
      events: updatedEvents, 
      status: currentState.toLegacyString(),
      pendingEvents: updatedPendingEvents,
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      syncState: SyncState.localOnly,
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
    if (!_permission.canTimeUp(user)) {
      throw UnauthorizedException('時間切れ操作を実行する権限がありません');
    }

    final analysis = _engine.analyzeHistory(currentMatch.events, currentMatch, rule);
    final timeUpContext = MatchContext(
      redIppon: analysis.context.redIppon, whiteIppon: analysis.context.whiteIppon,
      redHansoku: analysis.context.redHansoku, whiteHansoku: analysis.context.whiteHansoku,
      isTimeUp: true, targetIppon: analysis.context.targetIppon, hasHantei: rule.hasHantei,
    );

    // ★ Phase 1: FSMによる厳密な状態遷移
    MatchLifecycleState currentState = MatchLifecycleStateLegacyExt.fromLegacyString(currentMatch.status);

    if (_engine.shouldEnterEncho(timeUpContext, isEnchoEnabled)) {
      currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.startEncho);
      final newNote = currentMatch.note.isEmpty ? '延長' : '${currentMatch.note}, 延長';
      final enchoSeconds = rule.isEnchoUnlimited ? 0 : (rule.enchoTimeMinutes * 60).toInt();
      return currentMatch.copyWith(
        matchType: '延長戦', note: newNote, remainingSeconds: enchoSeconds,
        timerIsRunning: false, syncState: SyncState.localOnly, lastUpdatedAt: DateTime.now(),
        status: currentState.toLegacyString(), // ★ FSMの判定結果のみを適用
      ); 
    } else {
      currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.timeUp);
      return currentMatch.copyWith(
        status: currentState.toLegacyString(), // ★ FSMの判定結果のみを適用
        syncState: SyncState.localOnly, lastUpdatedAt: DateTime.now()
      );
    }
  }
}

/// ④ イベント履歴からの再構築 UseCase (読み取り専用なので関所不要)
class RebuildMatchFromEventsUseCase {
  final KendoRuleEngine _engine;
  RebuildMatchFromEventsUseCase(this._engine);

  MatchModel execute(MatchModel baseMatch, MatchRule currentSystemRule) {
    // ==========================================
    // ★ Phase 10: 10-2 Historical Replay 保証 & 10-3 Rule Migration Strategy
    // 過去の試合を再構築する際、現在のシステム設定(currentSystemRule)で上書きしてしまうと、
    // 「昔は1本勝負だったのに、今は3本勝負だから試合が再開されてしまう」という歴史改変(バグ)が起きる。
    // これを防ぐため、イベントに刻まれた ruleVersion や baseMatch.rule を最優先する。
    // ==========================================
    MatchRule replayRule = currentSystemRule;
    
    if (baseMatch.events.isNotEmpty) {
      final oldestRuleVersion = baseMatch.events.map((e) => e.ruleVersion).reduce((a, b) => a < b ? a : b);
      // イベント当時のルールバージョンが現在のシステムより古い場合、
      // 試合当時の設定（baseMatch.rule）を「真実のルール」として強制適用する（後方互換性）
      if (oldestRuleVersion < currentSystemRule.toRuleConfig.schemaVersion || baseMatch.status == 'approved' || baseMatch.status == 'finished') {
         replayRule = baseMatch.rule ?? currentSystemRule;
      }
    } else if (baseMatch.status == 'finished' || baseMatch.status == 'approved') {
      // イベントが無くても終了済みの過去試合なら当時のルールを適用
      replayRule = baseMatch.rule ?? currentSystemRule;
    }

    final analysis = _engine.analyzeHistory(baseMatch.events, baseMatch, replayRule);
    final result = _engine.decideResult(analysis.context, replayRule); // ★ Replay用のルールを渡す

    // ★ Phase 1: FSMによる厳密な状態遷移
    MatchLifecycleState currentState = MatchLifecycleStateLegacyExt.fromLegacyString(baseMatch.status);
    
    bool isJustUndone = false;
    if (baseMatch.events.isNotEmpty) {
      final latestEvent = baseMatch.events.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
      if (latestEvent.isCanceled || latestEvent.isUndo || latestEvent.type == PointType.undo) {
        isJustUndone = true;
      }
    }

    if (isJustUndone && baseMatch.status != 'approved') {
      if (currentState == MatchLifecycleState.completed || currentState == MatchLifecycleState.fusen) {
        currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.undo);
      }
    } else if (result != MatchResultStatus.inProgress && baseMatch.status != 'approved') {
      if (currentState != MatchLifecycleState.completed && currentState != MatchLifecycleState.fusen) {
        currentState = MatchStateMachine.transition(currentState, StateTransitionEvent.decideWinner);
      }
    }

    return baseMatch.copyWith(
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      status: currentState.toLegacyString(),
      syncState: SyncState.localOnly,
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
final redoScoreUseCaseProvider = Provider((ref) => RedoScoreUseCase(ref.watch(kendoRuleEngineProvider), ref.watch(permissionServiceProvider)));
final timeUpUseCaseProvider = Provider((ref) => TimeUpUseCase(ref.watch(kendoRuleEngineProvider), ref.watch(permissionServiceProvider)));

final rebuildMatchFromEventsUseCaseProvider = Provider((ref) => RebuildMatchFromEventsUseCase(ref.watch(kendoRuleEngineProvider)));
final calculatePointDisplaysUseCaseProvider = Provider((ref) => CalculatePointDisplaysUseCase(ref.watch(kendoRuleEngineProvider)));