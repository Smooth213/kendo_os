import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/match_domain_service.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

/// 🥋 試合終了時の自動判定・進行・名前伝播オーケストレーター
class MatchAutoProgressionService {
  final Ref _ref;
  final MatchDomainService _domainService;

  MatchAutoProgressionService(this._ref, this._domainService);

  /// 試合終了判定および次試合への引き継ぎ処理を実行
  Future<void> finalizeIfNeeded({
    required MatchModel updatedMatch,
    required MatchModel oldMatch,
    required Future<void> Function(String matchId) onApprove,
    required Future<void> Function(String matchId) onFinish,
    required Future<void> Function(String matchId, Side side, PointType type)
    onAddIppon,
    required Future<void> Function(MatchModel match) onSaveAndSync,
  }) async {
    // 1. 自動で不戦勝を入れる処理
    await autoProcessFusenIfNeeded(
      match: updatedMatch,
      onAddIppon: onAddIppon,
      onFinish: onFinish,
    );

    // 2. 勝敗が決定（規定本数到達）していれば自動で終了処理へ
    if (updatedMatch.status != 'finished' &&
        updatedMatch.status != 'approved') {
      final MatchRule rule = updatedMatch.rule ?? _ref.read(matchRuleProvider);
      final engine = KendoRuleEngine();
      final analysis = engine.analyzeHistory(
        updatedMatch.events,
        updatedMatch,
        rule,
      );
      final result = engine.decideResult(analysis.context, rule);

      if (result != MatchResultStatus.inProgress &&
          result != MatchResultStatus.draw) {
        final settings = _ref.read(settingsProvider);
        if (settings.confirmBehavior == 'single') {
          await onApprove(updatedMatch.id);
        } else {
          await onFinish(updatedMatch.id);
        }
        return;
      }
    }

    // 3. 試合が終了した場合の次への引き継ぎ処理
    if (updatedMatch.status == 'finished' && oldMatch.status != 'finished') {
      await propagateNameToNextMatch(
        finishedMatch: updatedMatch,
        onSaveAndSync: onSaveAndSync,
      );
      await generateNextKachinukiMatchIfNeeded(
        match: updatedMatch,
        onSaveAndSync: onSaveAndSync,
      );
      autoActivateNextMatch(
        finishedMatch: updatedMatch,
        onSaveAndSync: onSaveAndSync,
      );
    }
  }

  Future<void> autoProcessFusenIfNeeded({
    required MatchModel match,
    required Future<void> Function(String matchId, Side side, PointType type)
    onAddIppon,
    required Future<void> Function(String matchId) onFinish,
  }) async {
    final fusenEvents = _domainService.generateAutoFusenEvents(match);
    for (var event in fusenEvents) {
      await onAddIppon(match.id, event.side, event.type);
    }
    if (match.redName.contains('欠員') &&
        match.whiteName.contains('欠員') &&
        match.status != 'finished') {
      await onFinish(match.id);
    }
  }

  Future<void> generateNextKachinukiMatchIfNeeded({
    required MatchModel match,
    required Future<void> Function(MatchModel match) onSaveAndSync,
  }) async {
    final MatchRule rule = match.rule ?? _ref.read(matchRuleProvider);
    final nextMatch = _domainService.generateNextKachinukiMatch(match, rule);
    if (nextMatch != null) {
      await onSaveAndSync(nextMatch);
    }
  }

  Future<void> propagateNameToNextMatch({
    required MatchModel finishedMatch,
    required Future<void> Function(MatchModel match) onSaveAndSync,
  }) async {
    final localRepo = _ref.read(localMatchRepositoryProvider);
    final matches = await localRepo.getPendingMatches();
    final updatedMatches = _domainService.propagateNameToNextMatches(
      finishedMatch,
      matches,
    );
    for (var m in updatedMatches) {
      await onSaveAndSync(m);
    }
  }

  void autoActivateNextMatch({
    required MatchModel finishedMatch,
    required Future<void> Function(MatchModel match) onSaveAndSync,
  }) async {
    if (finishedMatch.groupName == null || finishedMatch.groupName!.isEmpty) {
      return;
    }
    final matches = _ref.read(matchListProvider);
    final groupMatches = matches
        .where((m) => m.groupName == finishedMatch.groupName)
        .toList();
    groupMatches.sort((a, b) => a.order.compareTo(b.order));
    final currentIndex = groupMatches.indexWhere(
      (m) => m.id == finishedMatch.id,
    );
    if (currentIndex != -1 && currentIndex < groupMatches.length - 1) {
      final nextMatch = groupMatches[currentIndex + 1];
      if (nextMatch.status == 'waiting') {
        await onSaveAndSync(nextMatch.copyWith(status: 'in_progress'));
      }
    }
  }
}

final matchAutoProgressionServiceProvider =
    Provider<MatchAutoProgressionService>((ref) {
      return MatchAutoProgressionService(ref, MatchDomainService());
    });
