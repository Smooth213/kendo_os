import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/match_model.dart';
import '../models/score_event.dart';
import '../usecase/match_usecases.dart'; 
import '../providers/match_list_provider.dart';
import '../providers/match_rule_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/match_command_provider.dart'; // ★ 変更: CommandQueue(Queue)へ直接流し込む
import '../providers/audit_provider.dart';
import 'sound_service.dart';

// ==========================================
// ★ ① ApplicationService設計：フローの完全集約
// ==========================================

class MatchApplicationService {
  final Ref _ref;
  final AddScoreUseCase _addScore;
  final UndoScoreUseCase _undoScore;
  final TimeUpUseCase _timeUp;

  MatchApplicationService(this._ref, this._addScore, this._undoScore, this._timeUp);

  // --------------------------------------------------
  // 1. 一本入力フロー
  // --------------------------------------------------
  Future<void> addIppon(String matchId, Side side, PointType type) async {
    final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
    if (match == null) return;
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

    // ★ ④ finalize統一: 試合が終わったかチェックして終了処理を実行
    await _finalizeIfNeeded(updatedMatch, match);
  }

  // --------------------------------------------------
  // 2. Undoフロー
  // --------------------------------------------------
  Future<void> undo(String matchId) async {
    final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
    if (match == null) return;
    final rule = _ref.read(matchRuleProvider);

    final updatedMatch = _undoScore.execute(match, rule);
    
    if (_ref.read(settingsProvider).sound) {
      _ref.read(soundServiceProvider).playUndoSound();
    }

    await _saveAndSync(updatedMatch);
    await _ref.read(auditProvider).logAction(matchId: match.id, action: 'undo', details: '取消');
  }

  // --------------------------------------------------
  // 3. 時間切れ（TimeUp）フロー
  // --------------------------------------------------
  Future<void> handleTimeUp(String matchId) async {
    final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
    if (match == null) return;
    final rule = _ref.read(matchRuleProvider);

    final canExtend = rule.isEnchoUnlimited || rule.enchoCount > 0;
    final updatedMatch = _timeUp.execute(match, canExtend, rule);
    
    if (_ref.read(settingsProvider).sound && updatedMatch.status == 'finished') {
      _ref.read(soundServiceProvider).playFinishFanfare(); 
    }

    await _saveAndSync(updatedMatch);
    await _ref.read(auditProvider).logAction(matchId: match.id, action: 'time_up', details: '時間切れ');

    // ★ ④ finalize統一: 試合が終わったかチェックして終了処理を実行
    await _finalizeIfNeeded(updatedMatch, match);
  }

  // --------------------------------------------------
  // 4. 共通保存ロジック（CommandQueueへの委譲）
  // --------------------------------------------------
  Future<void> _saveAndSync(MatchModel match) async {
    // Repositoryを直接叩くのではなく、必ずQueueシステムを通すことで競合を防ぐ
    await _ref.read(matchCommandProvider).saveMatch(match);
  }

  // --------------------------------------------------
  // 5. ★ ④ 試合終了時の統一処理 (Finalize)
  // --------------------------------------------------
  Future<void> _finalizeIfNeeded(MatchModel updatedMatch, MatchModel oldMatch) async {
    // 進行中から「終了」に変わった瞬間のみ発火
    if (updatedMatch.status == 'finished' && oldMatch.status != 'finished') {
      await _propagateNameToNextMatch(updatedMatch);
      _autoActivateNextMatch(updatedMatch);
    }
  }

  // --------------------------------------------------
  // 6. 手動ステータス変更（UIからの直接操作用）
  // --------------------------------------------------
  Future<void> approveMatch(String matchId) async {
    final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
    if (match == null) return;
    await _saveAndSync(match.copyWith(status: 'approved'));
  }

  Future<void> finishMatch(String matchId) async {
    final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
    if (match == null) return;
    final updated = match.copyWith(status: 'finished', isDirty: true, lastUpdatedAt: DateTime.now());
    await _saveAndSync(updated);
    await _finalizeIfNeeded(updated, match);
  }

  // --------------------------------------------------
  // 内部メソッド
  // --------------------------------------------------
  Future<void> _propagateNameToNextMatch(MatchModel finishedMatch) async {
    final isRedWin = finishedMatch.redScore > finishedMatch.whiteScore;
    final isWhiteWin = finishedMatch.whiteScore > finishedMatch.redScore;
    
    // 引き分けの場合は勝敗による名前の伝播は行わない
    if (!isRedWin && !isWhiteWin) return;

    final winnerName = isRedWin ? finishedMatch.redName : finishedMatch.whiteName;
    final loserName = isRedWin ? finishedMatch.whiteName : finishedMatch.redName;

    final matches = _ref.read(matchListProvider);

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

        if (updated) {
          await _saveAndSync(m.copyWith(redName: nextRed, whiteName: nextWhite));
        }
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
      if (nextMatch.status == 'waiting') {
        await _saveAndSync(nextMatch.copyWith(status: 'in_progress'));
      }
    }
  }
}

// UIからこの Service を呼ぶための Provider
final matchApplicationServiceProvider = Provider<MatchApplicationService>((ref) {
  return MatchApplicationService(
    ref,
    ref.watch(addScoreUseCaseProvider),
    ref.watch(undoScoreUseCaseProvider),
    ref.watch(timeUpUseCaseProvider),
  );
});