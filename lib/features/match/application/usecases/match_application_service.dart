import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/audit_log.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/application/usecases/scorer_lock_usecase.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/admin/providers/audit_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/ui_message_provider.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';
import 'package:kendo_os/features/match/domain/services/match_domain_service.dart';
import 'package:kendo_os/admin/providers/metrics_provider.dart';
import 'package:kendo_os/features/match/application/services/match_auto_progression_service.dart';
import 'package:kendo_os/features/match/application/services/match_persistence_helper.dart';
import 'package:kendo_os/features/match/application/services/match_rewind_service.dart';
import 'package:kendo_os/features/match/application/services/match_hantei_finish_helper.dart';
import 'package:kendo_os/features/match/application/services/match_sound_helper.dart';
import 'package:kendo_os/features/match/application/services/match_retirement_helper.dart';
import 'package:kendo_os/features/match/application/services/match_snapshot_helper.dart';
import 'package:kendo_os/features/match/application/services/match_undo_helper.dart';

/// アプリケーション層オーケストレーションサービス
class MatchApplicationService {
  final Ref _ref;
  final AddScoreUseCase _addScore;
  final TimeUpUseCase _timeUp;
  final ScorerLockUseCase _scorerLock;
  final MatchPersistenceHelper _persistenceHelper;
  final MatchAutoProgressionService _progressionService;
  final MatchHanteiFinishHelper _hanteiFinishHelper;
  final MatchSnapshotHelper _snapshotHelper;
  final MatchUndoHelper _undoHelper;

  MatchApplicationService(
    this._ref,
    this._addScore,
    this._timeUp,
    MatchDomainService domainService, {
    ScorerLockUseCase scorerLock = const ScorerLockUseCase(),
    MatchPersistenceHelper? persistenceHelper,
    MatchAutoProgressionService? progressionService,
    MatchHanteiFinishHelper? hanteiFinishHelper,
    MatchSnapshotHelper? snapshotHelper,
    MatchUndoHelper? undoHelper,
  }) : _scorerLock = scorerLock,
       _persistenceHelper = persistenceHelper ?? MatchPersistenceHelper(_ref),
       _progressionService =
           progressionService ??
           MatchAutoProgressionService(_ref, domainService),
       _hanteiFinishHelper =
           hanteiFinishHelper ??
           MatchHanteiFinishHelper(
             _ref,
             persistenceHelper ?? MatchPersistenceHelper(_ref),
             _addScore,
           ),
       _snapshotHelper = snapshotHelper ?? const MatchSnapshotHelper(),
       _undoHelper =
           undoHelper ??
           MatchUndoHelper(
             _ref,
             _addScore,
             persistenceHelper ?? MatchPersistenceHelper(_ref),
             snapshotHelper ?? const MatchSnapshotHelper(),
           );

  User _getCurrentUser() {
    String uid = 'unknown_user';
    try {
      uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
    } catch (_) {
      uid = 'test_user';
    }
    return User(id: uid, role: Role.admin, organizationId: 'default_org');
  }

  Future<void> _safeExecute(
    Future<void> Function() action,
    String errorPrefix, {
    String? metricName,
    String? traceId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      await action();
      stopwatch.stop();
      if (metricName != null) {
        _ref
            .read(metricsProvider)
            .recordLatency(
              metricName,
              stopwatch.elapsedMilliseconds,
              traceId: traceId,
            );
      }
    } catch (e) {
      stopwatch.stop();
      if (e.toString().contains('Concurrency') ||
          e.toString().contains('競合') ||
          e.toString().contains('他の端末')) {
        _ref.read(metricsProvider).recordConcurrencyConflict(traceId: traceId);
      } else {
        _ref.read(metricsProvider).recordError(traceId: traceId);
      }
      _ref.read(uiMessageProvider.notifier).showError('$errorPrefix: $e');
      rethrow;
    }
  }

  Future<MatchModel?> _getMatchSafely(String matchId) =>
      _persistenceHelper.getMatchSafely(matchId);

  // 1. 一本入力フロー
  Future<void> addIppon(
    String matchId,
    Side side,
    PointType type, {
    bool isRetirement = false,
  }) async {
    final traceId = const Uuid().v4();
    await _safeExecute(
      () async {
        final initialMatch = await _getMatchSafely(matchId);
        if (initialMatch == null) return;

        final MatchRule rule =
            initialMatch.rule ?? _ref.read(matchRuleProvider);
        final settings = _ref.read(settingsProvider);
        final currentUser = _getCurrentUser();

        final typeLabel = isRetirement
            ? '途中棄権'
            : ({
                    PointType.men: 'メン',
                    PointType.kote: 'コテ',
                    PointType.doIdo: 'ドウ',
                    PointType.tsuki: 'ツキ',
                    PointType.hansoku: '反則',
                    PointType.fusen: '不戦勝',
                    PointType.hantei: '判定',
                  }[type] ??
                  type.name);
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
              details: '${side.name} ${type.name}',
              traceId: traceId,
            );

        await _finalizeIfNeeded(updatedMatch, match);
      },
      '端末にスコアが保存されませんでした。もう一度お試しください',
      metricName: 'event_append',
      traceId: traceId,
    );
  }

  /// 途中棄権の記録（全日本剣道連盟ルール準拠：相手に不戦勝2本を付与し試合終了）
  Future<void> recordRetirement(String matchId, Side retiredSide) async {
    final traceId = const Uuid().v4();
    await _safeExecute(
      () async {
        final initialMatch = await _getMatchSafely(matchId);
        if (initialMatch == null) return;

        final MatchRule rule =
            initialMatch.rule ?? _ref.read(matchRuleProvider);
        final settings = _ref.read(settingsProvider);
        final currentUser = _getCurrentUser();
        final winnerSide = retiredSide == Side.red ? Side.white : Side.red;

        final matchWithSnapshot = _snapshotHelper.addSnapshotToMatch(
          initialMatch,
          '【${retiredSide == Side.red ? "赤" : "白"}】途中棄権 記録前',
        );

        final helper = MatchRetirementHelper(_addScore);
        final updatedMatch = helper.processRetirement(
          user: currentUser,
          match: matchWithSnapshot,
          retiredSide: retiredSide,
          rule: rule,
        );

        MatchSoundHelper.playAddIpponSound(
          soundService: _ref.read(soundServiceProvider),
          audioFeedbackMode: settings.audioFeedbackMode,
          side: winnerSide,
          type: PointType.fusen,
          typeLabel: '途中棄権',
          isMatchFinishedNow: true,
        );

        await _persistenceHelper.saveAndSync(updatedMatch);
        await _ref
            .read(auditProvider)
            .logAction(
              matchId: matchWithSnapshot.id,
              action: AuditAction.addScore,
              details: '${winnerSide.name} 途中棄権不戦勝',
              traceId: traceId,
            );

        await _finalizeIfNeeded(updatedMatch, matchWithSnapshot);
      },
      '端末にスコアが保存されませんでした。もう一度お試しください',
      metricName: 'event_append',
      traceId: traceId,
    );
  }

  // 2. Undoフロー
  Future<void> undo(String matchId) async {
    final traceId = const Uuid().v4();
    await _safeExecute(
      () => _undoHelper.executeUndo(
        matchId: matchId,
        currentUser: _getCurrentUser(),
        traceId: traceId,
      ),
      '操作を取り消せませんでした。もう一度お試しください',
      metricName: 'event_undo',
      traceId: traceId,
    );
  }

  // 3. タイムトラベル（巻き戻し）
  Future<void> rewindTo(String matchId, int targetVersion) async {
    final traceId = const Uuid().v4();
    await _safeExecute(
      () async {
        final initialMatch = await _getMatchSafely(matchId);
        if (initialMatch == null) return;

        final engine = KendoRuleEngine();
        final validEvents = engine.filterActiveEvents(initialMatch.events);
        if (validEvents.length <= targetVersion) return;

        var match = _snapshotHelper.addSnapshotToMatch(
          initialMatch,
          '巻き戻し実行 (Version: $targetVersion へ)',
        );

        final currentUser = _getCurrentUser();
        final MatchRule rule = match.rule ?? _ref.read(matchRuleProvider);

        final permissionService = _ref.read(permissionServiceProvider);
        if (!permissionService.canUndo(currentUser)) {
          throw Exception('データを巻き戻す権限がありません。');
        }

        final updatedMatch = MatchRewindService.executeRewind(
          initialMatch: match,
          targetVersion: targetVersion,
          currentUser: currentUser,
          rule: rule,
          addScore: _addScore,
        );

        await _persistenceHelper.saveAndSync(updatedMatch);
        await _ref
            .read(auditProvider)
            .logAction(
              matchId: match.id,
              action: AuditAction.undo,
              details: 'タイムトラベル実行: $targetVersion件目のイベントまで復元',
              traceId: traceId,
            );
      },
      'データの巻き戻しに失敗しました',
      traceId: traceId,
    );
  }

  // 4. 時間切れ（TimeUp）
  Future<void> handleTimeUp(String matchId) async {
    final traceId = const Uuid().v4();
    await _safeExecute(
      () async {
        final match = await _getMatchSafely(matchId);
        if (match == null) return;

        final MatchRule rule = match.rule ?? _ref.read(matchRuleProvider);
        final currentUser = _getCurrentUser();

        final permissionService = _ref.read(permissionServiceProvider);
        if (!permissionService.canTimeUp(currentUser)) {
          throw Exception('時間切れ処理を実行する権限がありません。');
        }

        final canExtend = rule.isEnchoUnlimited || rule.enchoCount > 0;
        final updatedMatch = _timeUp.execute(
          currentUser,
          match,
          canExtend,
          rule,
        );

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

        await _finalizeIfNeeded(updatedMatch, match);
      },
      '時間切れ処理に失敗しました',
      traceId: traceId,
    );
  }

  // 5. 保存・同期オーケストレーション
  Future<void> saveMatch(MatchModel match) async =>
      _safeExecute(() => _persistenceHelper.saveMatch(match), '保存に失敗しました');

  Future<void> saveMatchesBulk(List<MatchModel> newMatches) async =>
      _safeExecute(
        () => _persistenceHelper.saveMatchesBulk(newMatches),
        '一括保存に失敗しました',
      );

  // 6. スコアラーロック
  Future<bool> claimScorer(String matchId, String userId) async {
    final match = await _getMatchSafely(matchId);
    if (match == null) return false;
    final updated = _scorerLock.tryClaimScorer(match, userId);
    if (updated != null) {
      await saveMatch(updated);
      return true;
    }
    return false;
  }

  Future<void> releaseScorer(String matchId, String userId) async {
    final match = await _getMatchSafely(matchId);
    if (match == null) return;
    final updated = _scorerLock.releaseScorer(match, userId);
    if (updated != null) await saveMatch(updated);
  }

  Future<void> forceClaimScorer(String matchId, String userId) async {
    final match = await _getMatchSafely(matchId);
    if (match == null) return;
    final updated = _scorerLock.forceClaimScorer(match, userId);
    await saveMatch(updated);
  }

  // 7. 手動ステータス変更
  Future<void> approveMatch(String matchId) async {
    final traceId = const Uuid().v4();
    await _safeExecute(
      () => _hanteiFinishHelper.approveMatch(matchId, traceId),
      '試合の確定ができませんでした。もう一度お試しください',
      traceId: traceId,
    );
  }

  Future<void> finishMatch(String matchId) async {
    final traceId = const Uuid().v4();
    await _safeExecute(
      () async {
        final initial = await _getMatchSafely(matchId);
        if (initial == null) return;
        final updated = await _hanteiFinishHelper.finishMatch(matchId);
        if (updated != null) await _finalizeIfNeeded(updated, initial);
      },
      '試合終了の保存に失敗しました',
      traceId: traceId,
    );
  }

  Future<void> finishMatchManually(String matchId, {Side? hanteiWinner}) async {
    final traceId = const Uuid().v4();
    await _safeExecute(
      () async {
        final initial = await _getMatchSafely(matchId);
        if (initial == null) return;
        final updated = await _hanteiFinishHelper.finishMatchManually(
          matchId: matchId,
          currentUser: _getCurrentUser(),
          hanteiWinner: hanteiWinner,
        );
        if (updated != null) await _finalizeIfNeeded(updated, initial);
      },
      '試合の終了保存に失敗しました',
      traceId: traceId,
    );
  }

  Future<void> _finalizeIfNeeded(MatchModel updated, MatchModel old) =>
      _progressionService.finalizeIfNeeded(
        updatedMatch: updated,
        oldMatch: old,
        onApprove: approveMatch,
        onFinish: finishMatch,
        onAddIppon: addIppon,
        onSaveAndSync: _persistenceHelper.saveAndSync,
      );
}

final matchApplicationServiceProvider = Provider<MatchApplicationService>((
  ref,
) {
  return MatchApplicationService(
    ref,
    ref.watch(addScoreUseCaseProvider),
    ref.watch(timeUpUseCaseProvider),
    MatchDomainService(),
    scorerLock: ref.watch(scorerLockUseCaseProvider),
  );
});
