import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

import 'package:kendo_os/features/match/domain/match_state.dart';

import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/time/time_source.dart';

/// Undo UseCase
class UndoScoreUseCase {
  final KendoRuleEngine _engine;
  final PermissionService _permission;
  final TimeSource _timeSource;

  UndoScoreUseCase(this._engine, this._permission, this._timeSource);

  MatchModel execute(User user, MatchModel currentMatch, MatchRule rule) {
    if (!_permission.canUndo(user)) {
      throw UnauthorizedException('操作を取り消す権限がありません');
    }

    final activeEvents = _engine.filterActiveEvents(currentMatch.events);
    if (activeEvents.isEmpty) return currentMatch;

    final targetEventId = activeEvents.last.id;
    final newSequence = currentMatch.events.isEmpty
        ? 1
        : currentMatch.events.last.sequence + 1;

    final undoEvent = ScoreEvent(
      id: 'undo-${_timeSource.now().microsecondsSinceEpoch}',
      schemaVersion: 2,
      side: Side.none,
      strikeType: StrikeType.none,
      isUndo: true,
      targetId: targetEventId,
      timestamp: _timeSource.now(),
      sequence: newSequence,
      logicalClock: newSequence,
      userId: user.id,
      ruleVersion: rule.toRuleConfig.schemaVersion,
    );

    final updatedEvents = List<ScoreEvent>.from(currentMatch.events)
      ..add(undoEvent);
    final updatedPendingEvents = List<ScoreEvent>.from(
      currentMatch.pendingEvents,
    )..add(undoEvent);

    final analysis = _engine.analyzeHistory(updatedEvents, currentMatch, rule);

    MatchLifecycleState currentState =
        MatchLifecycleStateLegacyExt.fromLegacyString(currentMatch.status);
    if (currentState == MatchLifecycleState.completed ||
        currentState == MatchLifecycleState.fusen) {
      currentState = MatchStateMachine.transition(
        currentState,
        StateTransitionEvent.undo,
      );
    }

    return currentMatch.copyWith(
      events: updatedEvents,
      status: currentState.toLegacyString(),
      pendingEvents: kIsWeb ? <ScoreEvent>[] : updatedPendingEvents,
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      syncState: SyncState.localOnly,
      lastUpdatedAt: _timeSource.now(),
    );
  }
}

/// Redo(やり直し) UseCase
class RedoScoreUseCase {
  final KendoRuleEngine _engine;
  final PermissionService _permission;
  final TimeSource _timeSource;

  RedoScoreUseCase(this._engine, this._permission, this._timeSource);

  MatchModel execute(User user, MatchModel currentMatch, MatchRule rule) {
    if (!_permission.canUndo(user)) {
      throw UnauthorizedException('操作をやり直す権限がありません');
    }

    if (currentMatch.events.isEmpty) return currentMatch;

    final newSequence = currentMatch.events.last.sequence + 1;

    final redoEvent = ScoreEvent(
      id: 'redo-${_timeSource.now().microsecondsSinceEpoch}',
      schemaVersion: 2,
      side: Side.none,
      strikeType: StrikeType.none,
      isRestore: true,
      timestamp: _timeSource.now(),
      sequence: newSequence,
      logicalClock: newSequence,
      userId: user.id,
      ruleVersion: rule.toRuleConfig.schemaVersion,
    );

    final updatedEvents = List<ScoreEvent>.from(currentMatch.events)
      ..add(redoEvent);
    final updatedPendingEvents = List<ScoreEvent>.from(
      currentMatch.pendingEvents,
    )..add(redoEvent);

    final analysis = _engine.analyzeHistory(updatedEvents, currentMatch, rule);

    MatchLifecycleState currentState =
        MatchLifecycleStateLegacyExt.fromLegacyString(currentMatch.status);
    final result = _engine.decideResult(analysis.context);

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

    return currentMatch.copyWith(
      events: updatedEvents,
      status: currentState.toLegacyString(),
      pendingEvents: kIsWeb ? <ScoreEvent>[] : updatedPendingEvents,
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      syncState: SyncState.localOnly,
      lastUpdatedAt: _timeSource.now(),
    );
  }
}
