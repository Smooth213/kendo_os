import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/audit_log.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/admin/providers/audit_provider.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';
import 'package:kendo_os/features/match/application/services/match_persistence_helper.dart';
import 'package:kendo_os/features/match/application/services/match_sound_helper.dart';
import 'package:kendo_os/features/match/application/services/match_snapshot_helper.dart';
import 'package:kendo_os/features/match/application/usecases/match_progress_calculator.dart';

/// 一本付与処理のオーケストレーションヘルパー
class MatchIpponHelper {
  final Ref _ref;
  final AddScoreUseCase _addScore;
  final MatchPersistenceHelper _persistenceHelper;
  final MatchSnapshotHelper _snapshotHelper;

  const MatchIpponHelper(
    this._ref,
    this._addScore,
    this._persistenceHelper,
    this._snapshotHelper,
  );

  /// 一本入力フローを実行
  Future<void> executeAddIppon({
    required String matchId,
    required Side side,
    required PointType type,
    bool isRetirement = false,
    int redFlags = 0,
    int whiteFlags = 0,
    required String traceId,
    required Future<void> Function(MatchModel updated, MatchModel initial)
    finalizeIfNeeded,
  }) async {
    final initialMatch = await _persistenceHelper.getMatchSafely(matchId);
    if (initialMatch == null) return;

    final MatchRule rule = initialMatch.rule ?? _ref.read(matchRuleProvider);
    final settings = _ref.read(settingsProvider);
    final currentUser = MatchProgressCalculator.getCurrentUser();

    final isKata = redFlags > 0 || whiteFlags > 0;
    final typeLabel = isRetirement
        ? '途中棄権'
        : (isKata
              ? '旗判定 ($redFlags-$whiteFlags)'
              : ({
                      PointType.men: 'メン',
                      PointType.kote: 'コテ',
                      PointType.doIdo: 'ドウ',
                      PointType.tsuki: 'ツキ',
                      PointType.hansoku: '反則',
                      PointType.fusen: '不戦勝',
                      PointType.hantei: '判定',
                    }[type] ??
                    type.name));

    var match = _snapshotHelper.addSnapshotToMatch(
      initialMatch,
      '【${side == Side.red ? "赤" : "白"}】$typeLabel 入力前',
    );

    int maxClock = match.events.isEmpty
        ? 0
        : match.events
              .map((e) => e.logicalClock)
              .reduce((a, b) => a > b ? a : b);

    final event = ScoreEventLegacyAdapter.fromLegacy(
      id: const Uuid().v4(),
      side: side,
      type: type,
      timestamp: DateTime.now(),
      userId: currentUser.id,
      sequence: match.events.isEmpty ? 1 : match.events.last.sequence + 1,
      logicalClock: maxClock + 1,
      isRetirement: isRetirement,
      redFlags: redFlags,
      whiteFlags: whiteFlags,
    );

    final permissionService = _ref.read(permissionServiceProvider);
    if (!permissionService.canAppend(currentUser, event)) {
      throw Exception('スコアを追加する権限がありません。');
    }

    final updatedMatch = _addScore.execute(currentUser, match, event, rule);

    MatchSoundHelper.playAddIpponSound(
      soundService: _ref.read(soundServiceProvider),
      audioFeedbackMode: settings.audioFeedbackMode,
      side: side,
      type: type,
      typeLabel: typeLabel,
      isMatchFinishedNow:
          updatedMatch.status == 'finished' && match.status != 'finished',
    );

    await _persistenceHelper.saveAndSync(updatedMatch);
    await _ref
        .read(auditProvider)
        .logAction(
          matchId: match.id,
          action: AuditAction.addScore,
          details: isKata
              ? '${side.name} kataJudge $redFlags-$whiteFlags'
              : '${side.name} ${type.name}',
          traceId: traceId,
        );

    await finalizeIfNeeded(updatedMatch, match);
  }
}
