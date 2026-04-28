import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/match_model.dart';
import '../../domain/match/score_event.dart'; 
import '../../domain/match/match_context.dart'; 
import '../../domain/kendo_rule_engine.dart'; 
import '../usecase/match_usecases.dart'; 
import '../../presentation/provider/match_list_provider.dart';
import '../../presentation/provider/match_rule_provider.dart';
import '../../presentation/provider/settings_provider.dart';
import '../../presentation/provider/match_command_provider.dart';
import '../../presentation/provider/audit_provider.dart';
import '../../presentation/provider/ui_message_provider.dart'; // ★ 追加: 通知司令塔
import 'sound_service.dart';

// ==========================================
// ★ ApplicationService設計：フローの完全集約と安全網
// ==========================================

class MatchApplicationService {
  final Ref _ref;
  final AddScoreUseCase _addScore;
  final UndoScoreUseCase _undoScore;
  final TimeUpUseCase _timeUp;

  MatchApplicationService(this._ref, this._addScore, this._undoScore, this._timeUp);

  // --- ヘルパー：エラーをキャッチして通知する安全網 ---
  Future<void> _safeExecute(Future<void> Function() action, String errorPrefix) async {
    try {
      await action();
    } catch (e) {
      // 1. UIの司令塔にエラーメッセージを送る
      _ref.read(uiMessageProvider.notifier).showError('$errorPrefix: $e');
      // 2. ★ 追加: エラーを握りつぶさず、システム（テスト）に伝播させる
      rethrow; 
    }
  }

  // --------------------------------------------------
  // 1. 一本入力フロー
  // --------------------------------------------------
  Future<void> addIppon(String matchId, Side side, PointType type) async {
    await _safeExecute(() async {
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

      await _finalizeIfNeeded(updatedMatch, match);
    }, '端末にスコアが保存されませんでした。もう一度お試しください'); // addIppon
  }

  // --------------------------------------------------
  // 2. Undoフロー
  // --------------------------------------------------
  Future<void> undo(String matchId) async {
    await _safeExecute(() async {
      final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
      if (match == null) return;
      final rule = _ref.read(matchRuleProvider);

      final updatedMatch = _undoScore.execute(match, rule);
      
      if (_ref.read(settingsProvider).sound) {
        _ref.read(soundServiceProvider).playUndoSound();
      }

      await _saveAndSync(updatedMatch);
      await _ref.read(auditProvider).logAction(matchId: match.id, action: 'undo', details: '取消');
    }, '操作を取り消せませんでした。もう一度お試しください'); // undo
  }

  // --------------------------------------------------
  // 3. 時間切れ（TimeUp）フロー
  // --------------------------------------------------
  Future<void> handleTimeUp(String matchId) async {
    await _safeExecute(() async {
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

      await _finalizeIfNeeded(updatedMatch, match);
    }, '時間切れ処理に失敗しました');
  }

  // --------------------------------------------------
  // 4. 共通保存ロジック
  // --------------------------------------------------
  Future<void> _saveAndSync(MatchModel match) async {
    await _ref.read(matchCommandProvider).saveMatch(match);
  }

  // --------------------------------------------------
  // 5. 手動ステータス変更
  // --------------------------------------------------
  Future<void> approveMatch(String matchId) async {
    await _safeExecute(() async {
      final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
      if (match == null) return;
      await _saveAndSync(match.copyWith(status: 'approved'));
    }, '試合の確定ができませんでした。もう一度お試しください'); // approveMatch
  }

  Future<void> finishMatch(String matchId) async {
    await _safeExecute(() async {
      final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
      if (match == null) return;
      final updated = match.copyWith(status: 'finished', isDirty: true, lastUpdatedAt: DateTime.now());
      await _saveAndSync(updated);
      await _finalizeIfNeeded(updated, match);
    }, '試合終了の保存に失敗しました');
  }

  // --------------------------------------------------
  // 6. 試合終了時の自動判定・進行処理（UIから移動してきたロジック）
  // --------------------------------------------------
  Future<void> _finalizeIfNeeded(MatchModel updatedMatch, MatchModel oldMatch) async {
    // 1. 自動で不戦勝を入れる処理
    await _autoProcessFusenIfNeeded(updatedMatch);

    // 2. 勝敗が決定（規定本数到達）していれば自動で終了処理へ
    if (updatedMatch.status != 'finished' && updatedMatch.status != 'approved') {
      final rule = _ref.read(matchRuleProvider);
      final engine = KendoRuleEngine();
      final analysis = engine.analyzeHistory(updatedMatch.events, updatedMatch, rule);
      final result = engine.decideResult(analysis.context, rule);

      if (result != MatchResultStatus.inProgress && result != MatchResultStatus.draw) {
        final settings = _ref.read(settingsProvider);
        if (settings.confirmBehavior == 'single') {
          await approveMatch(updatedMatch.id);
        } else {
          await finishMatch(updatedMatch.id);
        }
        return; 
      }
    }

    // 3. 試合が終了した場合の次への引き継ぎ処理
    if (updatedMatch.status == 'finished' && oldMatch.status != 'finished') {
      await _propagateNameToNextMatch(updatedMatch);
      await _generateNextKachinukiMatchIfNeeded(updatedMatch);
      _autoActivateNextMatch(updatedMatch);
    }
  }

  Future<void> _autoProcessFusenIfNeeded(MatchModel match) async {
    if (match.status != 'waiting' && match.status != 'in_progress') return;
    
    bool rMiss = match.redName.contains('欠員');
    bool wMiss = match.whiteName.contains('欠員');
    bool hasFusen = match.events.any((e) => e.type == PointType.fusen);

    if ((rMiss || wMiss) && !hasFusen) {
      if (rMiss && wMiss) {
        await finishMatch(match.id);
      } else if (rMiss && !wMiss) {
        await addIppon(match.id, Side.white, PointType.fusen);
        await addIppon(match.id, Side.white, PointType.fusen);
      } else if (wMiss && !rMiss) {
        await addIppon(match.id, Side.red, PointType.fusen);
        await addIppon(match.id, Side.red, PointType.fusen);
      }
    }
  }

  Future<void> _generateNextKachinukiMatchIfNeeded(MatchModel match) async {
    if (!match.isKachinuki) return;

    final rule = _ref.read(matchRuleProvider);
    final rPts = match.redScore;
    final wPts = match.whiteScore;
    List<String> nextRedRem = List.from(match.redRemaining);
    List<String> nextWhiteRem = List.from(match.whiteRemaining);
    String nextRedName = match.redName;
    String nextWhiteName = match.whiteName;
    bool isMatchOver = false;
    bool isEncho = false; 

    if (rPts == wPts) { 
      if (nextRedRem.isEmpty && nextWhiteRem.isEmpty) {
        if (rule.kachinukiUnlimitedType == '大将引き分け延長' && match.matchType != '大将延長戦') {
          isMatchOver = false;
          isEncho = true;
        } else {
          isMatchOver = true;
        }
      } else if (nextRedRem.isEmpty || nextWhiteRem.isEmpty) {
        isMatchOver = true;
      } else {
        nextRedName = nextRedRem.removeAt(0);
        nextWhiteName = nextWhiteRem.removeAt(0);
      }
    } else if (rPts > wPts) { 
      if (nextWhiteRem.isEmpty) {
        isMatchOver = true; 
      } else {
        nextWhiteName = nextWhiteRem.removeAt(0);
      }
    } else { 
      if (nextRedRem.isEmpty) {
        isMatchOver = true;
      } else {
        nextRedName = nextRedRem.removeAt(0);
      }
    }

    if (!isMatchOver) {
      final nextMatchId = const Uuid().v4();
      final nextMatch = MatchModel(
        id: nextMatchId, tournamentId: match.tournamentId, category: match.category, groupName: match.groupName,
        matchType: isEncho ? '大将延長戦' : '勝ち抜き戦', redName: nextRedName, whiteName: nextWhiteName,
        status: 'waiting', matchTimeMinutes: match.matchTimeMinutes, isRunningTime: match.isRunningTime,
        remainingSeconds: match.matchTimeMinutes * 60, order: match.order + 0.1, 
        note: isEncho ? '延長戦（1本勝負）' : match.note, isKachinuki: true,
        redRemaining: nextRedRem, whiteRemaining: nextWhiteRem,
      );
      await _saveAndSync(nextMatch);
    }
  }

  Future<void> _propagateNameToNextMatch(MatchModel finishedMatch) async {
    final isRedWin = finishedMatch.redScore > finishedMatch.whiteScore;
    final isWhiteWin = finishedMatch.whiteScore > finishedMatch.redScore;
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
      if (nextMatch.status == 'waiting') {
        await _saveAndSync(nextMatch.copyWith(status: 'in_progress'));
      }
    }
  }
}

final matchApplicationServiceProvider = Provider<MatchApplicationService>((ref) {
  return MatchApplicationService(ref, ref.watch(addScoreUseCaseProvider), ref.watch(undoScoreUseCaseProvider), ref.watch(timeUpUseCaseProvider));
});