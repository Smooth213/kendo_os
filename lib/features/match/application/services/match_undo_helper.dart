import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/admin/providers/audit_provider.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/application/services/match_persistence_helper.dart';
import 'package:kendo_os/features/match/application/services/match_snapshot_helper.dart';
import 'package:kendo_os/features/match/application/services/match_sound_helper.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';
import 'package:kendo_os/shared/domain/entities/audit_log.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

/// Undo（取り消し）処理実行ヘルパー
class MatchUndoHelper {
  final Ref _ref;
  final AddScoreUseCase _addScore;
  final MatchPersistenceHelper _persistenceHelper;
  final MatchSnapshotHelper _snapshotHelper;

  const MatchUndoHelper(
    this._ref,
    this._addScore,
    this._persistenceHelper, [
    this._snapshotHelper = const MatchSnapshotHelper(),
  ]);

  Future<void> executeUndo({
    required String matchId,
    required User currentUser,
    required String traceId,
  }) async {
    final initialMatch = await _persistenceHelper.getMatchSafely(matchId);
    if (initialMatch == null) return;
    if (initialMatch.events.isEmpty) return;

    var match = _snapshotHelper.addSnapshotToMatch(initialMatch, '取り消し 実行前');
    final MatchRule rule = match.rule ?? _ref.read(matchRuleProvider);

    final permissionService = _ref.read(permissionServiceProvider);
    if (!permissionService.canUndo(currentUser)) {
      throw Exception('操作を取り消す権限がありません。');
    }

    int maxClock = match.events.isEmpty
        ? 0
        : match.events
              .map((e) => e.logicalClock)
              .reduce((a, b) => a > b ? a : b);

    final undoEvent = ScoreEventLegacyAdapter.fromLegacy(
      id: 'undo-${DateTime.now().microsecondsSinceEpoch}',
      side: Side.none,
      type: PointType.undo,
      timestamp: DateTime.now(),
      userId: currentUser.id,
      sequence: match.events.last.sequence + 1,
      logicalClock: maxClock + 1,
    );

    MatchModel updatedMatch = _addScore.execute(
      currentUser,
      match,
      undoEvent,
      rule,
    );

    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(
      updatedMatch.events,
      updatedMatch,
      rule,
    );

    updatedMatch = updatedMatch.copyWith(
      status: 'in_progress',
      redScore: analysis.context.redIppon,
      whiteScore: analysis.context.whiteIppon,
    );

    MatchSoundHelper.playUndoSound(
      soundService: _ref.read(soundServiceProvider),
      audioFeedbackMode: _ref.read(settingsProvider).audioFeedbackMode,
    );

    await _persistenceHelper.saveAndSync(updatedMatch);
    await _ref
        .read(auditProvider)
        .logAction(
          matchId: match.id,
          action: AuditAction.undo,
          details: '取消',
          traceId: traceId,
        );
  }
}
