import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

import 'package:kendo_os/features/match/domain/match_state.dart';

import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/time/time_source.dart';

/// イベント履歴からの再構築 UseCase (読み取り専用なので関所不要)
class RebuildMatchFromEventsUseCase {
  final KendoRuleEngine _engine;
  final TimeSource _timeSource;

  RebuildMatchFromEventsUseCase(this._engine, this._timeSource);

  MatchModel execute(MatchModel baseMatch, MatchRule currentSystemRule) {
    MatchRule replayRule = currentSystemRule;

    if (baseMatch.events.isNotEmpty) {
      final oldestRuleVersion = baseMatch.events
          .map((e) => e.ruleVersion)
          .reduce((a, b) => a < b ? a : b);
      if (oldestRuleVersion < currentSystemRule.toRuleConfig.schemaVersion ||
          baseMatch.status == 'approved' ||
          baseMatch.status == 'finished') {
        replayRule = baseMatch.rule ?? currentSystemRule;
      }
    } else if (baseMatch.status == 'finished' ||
        baseMatch.status == 'approved') {
      replayRule = baseMatch.rule ?? currentSystemRule;
    }

    final analysis = _engine.analyzeHistory(
      baseMatch.events,
      baseMatch,
      replayRule,
    );
    final result = _engine.decideResult(analysis.context, replayRule);

    MatchLifecycleState currentState =
        MatchLifecycleStateLegacyExt.fromLegacyString(baseMatch.status);

    bool isJustUndone = false;
    if (baseMatch.events.isNotEmpty) {
      final latestEvent = baseMatch.events.reduce(
        (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
      );
      if (latestEvent.isCanceled ||
          latestEvent.isUndo ||
          latestEvent.type == PointType.undo) {
        isJustUndone = true;
      }
    }

    if (isJustUndone && baseMatch.status != 'approved') {
      if (currentState == MatchLifecycleState.completed ||
          currentState == MatchLifecycleState.fusen) {
        currentState = MatchStateMachine.transition(
          currentState,
          StateTransitionEvent.undo,
        );
      }
    } else if (result != MatchResultStatus.inProgress &&
        baseMatch.status != 'approved') {
      if (currentState != MatchLifecycleState.completed &&
          currentState != MatchLifecycleState.fusen) {
        currentState = MatchStateMachine.transition(
          currentState,
          StateTransitionEvent.decideWinner,
        );
      }
    }

    return baseMatch.copyWith(
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
      status: currentState.toLegacyString(),
      syncState: SyncState.localOnly,
      lastUpdatedAt: _timeSource.now(),
    );
  }
}

/// ポイント表示計算 UseCase (読み取り専用なので関所不要)
class CalculatePointDisplaysUseCase {
  final KendoRuleEngine _engine;

  CalculatePointDisplaysUseCase(this._engine);

  Map<Side, List<PointDisplay>> execute(MatchModel match) {
    return _engine.analyzeHistory(match.events, match, null).displays;
  }
}
