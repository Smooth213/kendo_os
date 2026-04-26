import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/match_model.dart';
import '../../domain/match/score_event.dart'; // ★ 修正: models -> domain/match
import '../usecase/match_usecases.dart'; 
import '../../presentation/provider/match_list_provider.dart';
import '../../presentation/provider/match_rule_provider.dart';
import '../../presentation/provider/settings_provider.dart';
import '../../presentation/provider/match_command_provider.dart';
import '../../presentation/provider/audit_provider.dart';
import 'sound_service.dart';

class MatchApplicationService {
  final Ref _ref;
  final AddScoreUseCase _addScore;
  final UndoScoreUseCase _undoScore;
  final TimeUpUseCase _timeUp;

  MatchApplicationService(this._ref, this._addScore, this._undoScore, this._timeUp);

  Future<void> addIppon(String matchId, Side side, PointType type) async {
    final match = _ref.read(matchListProvider).firstWhere((m) => m.id == matchId); // ★ Null安全のためfirstWhereに変更
    final rule = _ref.read(matchRuleProvider);
    final settings = _ref.read(settingsProvider);

    final event = ScoreEvent(
      id: const Uuid().v4(),
      side: side,
      type: type,
      timestamp: DateTime.now(),
      userId: match.scorerId,
      sequence: match.events.isEmpty ? 1 : match.events.last.sequence + 1,
    );

    final updatedMatch = _addScore.execute(match, event, rule);

    if (settings.sound) {
      if (type == PointType.hansoku) {
        _ref.read(soundServiceProvider).playHansokuSound();
      } else {
        _ref.read(soundServiceProvider).playScoreSound(side == Side.red);
      }
      if (updatedMatch.status == 'finished' && match.status != 'finished') {
        _ref.read(soundServiceProvider).playFinishFanfare();
      }
    }

    await _saveAndSync(updatedMatch);
    await _ref.read(auditProvider).logAction(matchId: match.id, action: 'add_score', details: '${side.name} ${type.name}');
    await _finalizeIfNeeded(updatedMatch, match);
  }

  Future<void> undo(String matchId) async {
    final match = _ref.read(matchListProvider).firstWhere((m) => m.id == matchId);
    final rule = _ref.read(matchRuleProvider);
    final updatedMatch = _undoScore.execute(match, rule);
    
    if (_ref.read(settingsProvider).sound) {
      _ref.read(soundServiceProvider).playUndoSound();
    }
    await _saveAndSync(updatedMatch);
    await _ref.read(auditProvider).logAction(matchId: match.id, action: 'undo', details: '取消');
  }

  Future<void> handleTimeUp(String matchId) async {
    final match = _ref.read(matchListProvider).firstWhere((m) => m.id == matchId);
    final rule = _ref.read(matchRuleProvider);
    final canExtend = rule.isEnchoUnlimited || rule.enchoCount > 0;
    final updatedMatch = _timeUp.execute(match, canExtend, rule);
    
    if (_ref.read(settingsProvider).sound && updatedMatch.status == 'finished') {
      _ref.read(soundServiceProvider).playFinishFanfare(); 
    }
    await _saveAndSync(updatedMatch);
    await _ref.read(auditProvider).logAction(matchId: match.id, action: 'time_up', details: '時間切れ');
    await _finalizeIfNeeded(updatedMatch, match);
  }

  Future<void> approveMatch(String matchId) async {
    final match = _ref.read(matchListProvider).firstWhere((m) => m.id == matchId);
    await _saveAndSync(match.copyWith(status: 'approved'));
  }

  Future<void> finishMatch(String matchId) async {
    final match = _ref.read(matchListProvider).firstWhere((m) => m.id == matchId);
    final updated = match.copyWith(status: 'finished', isDirty: true, lastUpdatedAt: DateTime.now());
    await _saveAndSync(updated);
    await _finalizeIfNeeded(updated, match);
  }

  Future<void> _saveAndSync(MatchModel match) async {
    await _ref.read(matchCommandProvider).saveMatch(match);
  }

  Future<void> _finalizeIfNeeded(MatchModel updatedMatch, MatchModel oldMatch) async {
    if (updatedMatch.status == 'finished' && oldMatch.status != 'finished') {
      await _propagateNameToNextMatch(updatedMatch);
      _autoActivateNextMatch(updatedMatch);
    }
  }

  Future<void> _propagateNameToNextMatch(MatchModel finishedMatch) async {
    final matches = _ref.read(matchListProvider);
    final isRedWin = finishedMatch.redScore > finishedMatch.whiteScore;
    final winnerName = isRedWin ? finishedMatch.redName : finishedMatch.whiteName;
    final loserName = isRedWin ? finishedMatch.whiteName : finishedMatch.redName;
    final winnerTag = 'winner(${finishedMatch.id})';
    final loserTag = 'loser(${finishedMatch.id})';

    for (var m in matches) {
      if (m.status != 'finished') {
        bool updated = false;
        String nextRed = m.redName;
        String nextWhite = m.whiteName;
        if (nextRed.contains(winnerTag)) { nextRed = nextRed.replaceFirst(winnerTag, winnerName); updated = true; }
        if (nextRed.contains(loserTag)) { nextRed = nextRed.replaceFirst(loserTag, loserName); updated = true; }
        if (nextWhite.contains(winnerTag)) { nextWhite = nextWhite.replaceFirst(winnerTag, winnerName); updated = true; }
        if (nextWhite.contains(loserTag)) { nextWhite = nextWhite.replaceFirst(loserTag, loserName); updated = true; }
        if (updated) await _saveAndSync(m.copyWith(redName: nextRed, whiteName: nextWhite));
      }
    }
  }

  void _autoActivateNextMatch(MatchModel finishedMatch) async {
    if (finishedMatch.groupName == null || finishedMatch.groupName!.isEmpty) return;
    final matches = _ref.read(matchListProvider);
    final groupMatches = matches.where((m) => m.groupName == finishedMatch.groupName).toList();
    groupMatches.sort((a, b) => a.order.compareTo(b.order));
    final currentIndex = groupMatches.indexWhere((m) => m.id == finishedMatch.id);
    if (currentIndex != -1 && currentIndex < groupMatches.length - 1) {
      final nextMatch = groupMatches[currentIndex + 1];
      if (nextMatch.status == 'waiting') await _saveAndSync(nextMatch.copyWith(status: 'in_progress'));
    }
  }
}

final matchApplicationServiceProvider = Provider<MatchApplicationService>((ref) {
  return MatchApplicationService(ref, ref.watch(addScoreUseCaseProvider), ref.watch(undoScoreUseCaseProvider), ref.watch(timeUpUseCaseProvider));
});