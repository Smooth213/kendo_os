import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/audit_log.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/admin/providers/audit_provider.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';
import 'package:kendo_os/features/match/application/services/match_persistence_helper.dart';
import 'package:kendo_os/features/match/application/services/match_sound_helper.dart';
import 'package:kendo_os/features/match/application/usecases/match_progress_calculator.dart';

/// 時間切れ処理のオーケストレーションヘルパー
class MatchTimeUpHelper {
  final Ref _ref;
  final TimeUpUseCase _timeUp;
  final MatchPersistenceHelper _persistenceHelper;

  const MatchTimeUpHelper(this._ref, this._timeUp, this._persistenceHelper);

  /// 時間切れフローを実行
  Future<void> executeTimeUp({
    required String matchId,
    required String traceId,
    required Future<void> Function(MatchModel updated, MatchModel initial)
    finalizeIfNeeded,
  }) async {
    final match = await _persistenceHelper.getMatchSafely(matchId);
    if (match == null) return;

    final MatchRule rule = match.rule ?? _ref.read(matchRuleProvider);
    final currentUser = MatchProgressCalculator.getCurrentUser();

    final permissionService = _ref.read(permissionServiceProvider);
    if (!permissionService.canTimeUp(currentUser)) {
      throw Exception('時間切れ処理を実行する権限がありません。');
    }

    final canExtend = rule.isEnchoUnlimited || rule.enchoCount > 0;
    final updatedMatch = _timeUp.execute(currentUser, match, canExtend, rule);

    MatchSoundHelper.playTimeUpSound(
      soundService: _ref.read(soundServiceProvider),
      audioFeedbackMode: _ref.read(settingsProvider).audioFeedbackMode,
      isMatchFinished: updatedMatch.status == 'finished',
    );

    await _persistenceHelper.saveAndSync(updatedMatch);
    await _ref
        .read(auditProvider)
        .logAction(
          matchId: match.id,
          action: AuditAction.timeUp,
          details: '時間切れ',
          traceId: traceId,
        );

    await finalizeIfNeeded(updatedMatch, match);
  }
}
