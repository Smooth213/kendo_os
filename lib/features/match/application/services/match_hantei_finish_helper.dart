import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/application/services/match_persistence_helper.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

/// 試合の判定・手動終了・承認処理ヘルパー
class MatchHanteiFinishHelper {
  final Ref _ref;
  final MatchPersistenceHelper _persistenceHelper;
  final AddScoreUseCase _addScore;

  MatchHanteiFinishHelper(this._ref, this._persistenceHelper, this._addScore);

  Future<void> approveMatch(String matchId, String traceId) async {
    final match = await _persistenceHelper.getMatchSafely(matchId);
    if (match == null) return;
    await _persistenceHelper.saveAndSync(match.copyWith(status: 'approved'));
  }

  Future<MatchModel?> finishMatch(String matchId) async {
    final match = await _persistenceHelper.getMatchSafely(matchId);
    if (match == null) return null;

    final updated = match.copyWith(
      status: 'finished',
      timerStartedAt: null,
      hasExtension: false,
      scorerId: null,
      syncState: SyncState.localOnly,
      lastUpdatedAt: DateTime.now(),
    );
    await _persistenceHelper.saveAndSync(updated);
    return updated;
  }

  Future<MatchModel?> finishMatchManually({
    required String matchId,
    required User currentUser,
    Side? hanteiWinner,
  }) async {
    final match = await _persistenceHelper.getMatchSafely(matchId);
    if (match == null) return null;

    final MatchRule rule = match.rule ?? _ref.read(matchRuleProvider);

    int maxClock = match.events.isEmpty
        ? 0
        : match.events
              .map((e) => e.logicalClock)
              .reduce((a, b) => a > b ? a : b);

    final side = hanteiWinner ?? Side.none;
    final event = ScoreEventLegacyAdapter.fromLegacy(
      id: const Uuid().v4(),
      side: side,
      type: PointType.hantei,
      timestamp: DateTime.now(),
      userId: currentUser.id,
      sequence: match.events.isEmpty ? 1 : match.events.last.sequence + 1,
      logicalClock: maxClock + 1,
    );

    final permissionService = _ref.read(permissionServiceProvider);
    if (!permissionService.canAppend(currentUser, event)) {
      throw Exception('判定を入力する権限がありません。');
    }

    MatchModel updated = _addScore.execute(currentUser, match, event, rule);
    updated = updated.copyWith(
      status: 'finished',
      timerStartedAt: null,
      hasExtension: false,
      scorerId: null,
      syncState: SyncState.localOnly,
      lastUpdatedAt: DateTime.now(),
    );

    await _persistenceHelper.saveAndSync(updated);

    final settings = _ref.read(settingsProvider);
    final mode = settings.audioFeedbackMode;
    if (updated.status == 'finished' && match.status != 'finished') {
      if (mode == 'voice') {
        _ref.read(soundServiceProvider).speak('試合終了です');
      } else if (mode == 'effect') {
        _ref.read(soundServiceProvider).playFinishFanfare();
      }
    }

    return updated;
  }
}
