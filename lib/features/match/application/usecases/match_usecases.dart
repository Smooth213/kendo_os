import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/application/usecases/match_undo_redo_usecase.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/match_state.dart';

import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_provider.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/time/time_source.dart';

export 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
export 'package:kendo_os/features/match/application/usecases/match_undo_redo_usecase.dart';

/// ① スコア追加 UseCase
class AddScoreUseCase {
  final KendoRuleEngine _engine;
  final PermissionService _permission;
  final TimeSource _timeSource;

  AddScoreUseCase(this._engine, this._permission, this._timeSource);

  MatchModel execute(
    User user,
    MatchModel currentMatch,
    ScoreEvent newEvent,
    MatchRule rule,
  ) {
    if (!_permission.canAppend(user, newEvent)) {
      throw UnauthorizedException('この操作を実行する権限がありません');
    }

    var finalEvent = newEvent.copyWith(
      ruleVersion: rule.toRuleConfig.schemaVersion,
    );

    if (finalEvent.isUndo || finalEvent.type == PointType.undo) {
      final activeEvents = _engine.filterActiveEvents(currentMatch.events);
      if (activeEvents.isNotEmpty) {
        finalEvent = finalEvent.copyWith(targetId: activeEvents.last.id);
      }
    }

    final expectedSequence = currentMatch.events.isEmpty
        ? 1
        : currentMatch.events.last.sequence + 1;
    if (finalEvent.sequence != 0 && finalEvent.sequence != expectedSequence) {
      throw DomainException('競合が発生しました。他の端末で先にデータが更新されています。');
    }

    final analysis = _engine.analyzeHistory(
      currentMatch.events,
      currentMatch,
      rule,
    );
    final validation = _engine.validateEvent(
      currentMatch,
      finalEvent,
      analysis.context,
    );
    if (!validation.isValid) {
      throw DomainException(validation.reason ?? '不正な操作です');
    }

    final updatedEvents = List<ScoreEvent>.from(currentMatch.events);
    final updatedPendingEvents = List<ScoreEvent>.from(
      currentMatch.pendingEvents,
    );

    updatedEvents.add(finalEvent);
    updatedPendingEvents.add(finalEvent);

    final nextAnalysis = _engine.analyzeHistory(
      updatedEvents,
      currentMatch,
      rule,
    );

    MatchLifecycleState currentState =
        MatchLifecycleStateLegacyExt.fromLegacyString(currentMatch.status);

    if (currentState == MatchLifecycleState.ready ||
        currentState == MatchLifecycleState.notStarted ||
        currentState == MatchLifecycleState.waitingForPlayers) {
      currentState = MatchStateMachine.transition(
        currentState,
        StateTransitionEvent.startMatch,
      );
    }

    final result = _engine.decideResult(nextAnalysis.context);
    if (result != MatchResultStatus.inProgress) {
      if (currentState != MatchLifecycleState.completed &&
          currentState != MatchLifecycleState.fusen) {
        currentState = MatchStateMachine.transition(
          currentState,
          StateTransitionEvent.decideWinner,
        );
      }
    } else {
      if (currentState == MatchLifecycleState.completed ||
          currentState == MatchLifecycleState.fusen) {
        currentState = MatchStateMachine.transition(
          currentState,
          StateTransitionEvent.undo,
        );
      }
    }

    final bool isRunningTimerMode = rule.isRunningTime;

    MatchModel updatedMatch = currentMatch;
    if (!isRunningTimerMode && currentMatch.timerIsRunning) {
      final elapsed = _timeSource
          .now()
          .difference(currentMatch.timerStartedAt!)
          .inMilliseconds;
      updatedMatch = currentMatch.copyWith(
        timerStartedAt: null,
        accumulatedPauseDurationMs:
            currentMatch.accumulatedPauseDurationMs + elapsed,
      );
    }

    return updatedMatch.copyWith(
      events: updatedEvents,
      redScore: nextAnalysis.context.redIppon,
      whiteScore: nextAnalysis.context.whiteIppon,
      timerStartedAt: updatedMatch.timerStartedAt,
      accumulatedPauseDurationMs: updatedMatch.accumulatedPauseDurationMs,
      status: currentState.toLegacyString(),
      syncState: SyncState.localOnly,
      pendingEvents: kIsWeb ? <ScoreEvent>[] : updatedPendingEvents,
      lastUpdatedAt: _timeSource.now(),
    );
  }
}

/// ③ 時間切れ処理 UseCase
class TimeUpUseCase {
  final KendoRuleEngine _engine;
  final PermissionService _permission;
  final TimeSource _timeSource;

  TimeUpUseCase(this._engine, this._permission, this._timeSource);

  MatchModel execute(
    User user,
    MatchModel currentMatch,
    bool isEnchoEnabled,
    MatchRule rule,
  ) {
    if (!_permission.canTimeUp(user)) {
      throw UnauthorizedException('時間切れ操作を実行する権限がありません');
    }

    final analysis = _engine.analyzeHistory(
      currentMatch.events,
      currentMatch,
      rule,
    );
    final timeUpContext = MatchContext(
      redIppon: analysis.context.redIppon,
      whiteIppon: analysis.context.whiteIppon,
      redHansoku: analysis.context.redHansoku,
      whiteHansoku: analysis.context.whiteHansoku,
      isTimeUp: true,
      targetIppon: analysis.context.targetIppon,
      hasHantei: rule.hasHantei,
    );

    MatchLifecycleState currentState =
        MatchLifecycleStateLegacyExt.fromLegacyString(currentMatch.status);

    if (_engine.shouldEnterEncho(timeUpContext, isEnchoEnabled)) {
      currentState = MatchStateMachine.transition(
        currentState,
        StateTransitionEvent.startEncho,
      );
      final newNote = currentMatch.note.isEmpty
          ? '延長'
          : '${currentMatch.note}, 延長';
      final enchoSeconds = rule.isEnchoUnlimited
          ? 0
          : (rule.enchoTimeMinutes * 60).toInt();

      MatchModel updated = currentMatch.copyWith(
        matchType: '延長戦',
        note: newNote,
        syncState: SyncState.localOnly,
        lastUpdatedAt: _timeSource.now(),
        status: currentState.toLegacyString(),
      );

      updated = updated
          .updateRemainingSeconds(enchoSeconds, _timeSource.now())
          .copyWith(timerStartedAt: null);
      return updated;
    } else {
      currentState = MatchStateMachine.transition(
        currentState,
        StateTransitionEvent.timeUp,
      );
      return currentMatch.copyWith(
        status: currentState.toLegacyString(),
        syncState: SyncState.localOnly,
        lastUpdatedAt: _timeSource.now(),
      );
    }
  }
}

// ★ DI 用のプロバイダ定義
final permissionServiceProvider = Provider((ref) => PermissionService());

final addScoreUseCaseProvider = Provider(
  (ref) => AddScoreUseCase(
    ref.watch(kendoRuleEngineProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(timeSourceProvider),
  ),
);
final undoScoreUseCaseProvider = Provider(
  (ref) => UndoScoreUseCase(
    ref.watch(kendoRuleEngineProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(timeSourceProvider),
  ),
);
final redoScoreUseCaseProvider = Provider(
  (ref) => RedoScoreUseCase(
    ref.watch(kendoRuleEngineProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(timeSourceProvider),
  ),
);
final timeUpUseCaseProvider = Provider(
  (ref) => TimeUpUseCase(
    ref.watch(kendoRuleEngineProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(timeSourceProvider),
  ),
);

final rebuildMatchFromEventsUseCaseProvider = Provider(
  (ref) => RebuildMatchFromEventsUseCase(
    ref.watch(kendoRuleEngineProvider),
    ref.watch(timeSourceProvider),
  ),
);
final calculatePointDisplaysUseCaseProvider = Provider(
  (ref) => CalculatePointDisplaysUseCase(ref.watch(kendoRuleEngineProvider)),
);
