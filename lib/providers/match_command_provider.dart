import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/match_model.dart';
import '../models/score_event.dart';
import 'match_list_provider.dart';
import 'match_provider.dart'; // ★ MatchActionProviderを参照するために必要
import '../domain/kendo_rule_engine.dart'; // ★ DomainExceptionを参照するために必要
import 'match_rule_provider.dart';
import '../repositories/local_match_repository.dart'; // ★ Firestore版からIsar版に差し替え

// ★ Phase 3: 書き込み（保存・更新）専用のプロバイダ
final matchCommandProvider = Provider<MatchCommand>((ref) {
  return MatchCommand(ref);
});

// ★ Step 3-6: 現在「書き込み処理中」かどうかを管理するProvider
// 連打による多重送信やデータ競合をUIレベルでブロックします
final isMatchCommandProcessingProvider = StateProvider<bool>((ref) => false);

// ★ Step 4-3: エラーメッセージをUIに伝えるためのProvider
final matchCommandErrorProvider = StateProvider<String?>((ref) => null);

class MatchCommand {
  final Ref ref;
  MatchCommand(this.ref);

  // ★ Step 7-3: 誤操作防止（デバウンス）用の管理変数
  DateTime? _lastScoreTime;
  String? _lastScoreKey;

  // 1. 試合の保存（UI/Providerレベルの制御のみを行う）
  Future<void> saveMatch(MatchModel match) async {
    if (ref.read(isMatchCommandProcessingProvider)) return;
    
    ref.read(isMatchCommandProcessingProvider.notifier).state = true;
    ref.read(matchCommandErrorProvider.notifier).state = null;

    try {
      // ★ Step 1-3 完了: Isarのローカルリポジトリに保存を委譲！これで完全オフライン対応に。
      await ref.read(localMatchRepositoryProvider).saveMatch(match);
    } catch (e) {
      debugPrint('🔥 [Command Error]: $e');
      String msg = '保存に失敗しました';
      if (e is DomainException) msg = e.message;
      if (e is ConflictException) msg = '他の端末で更新されたため、最新の状態でやり直してください';
      ref.read(matchCommandErrorProvider.notifier).state = msg;
    } finally {
      ref.read(isMatchCommandProcessingProvider.notifier).state = false;
    }
  }

  // 2. 複数の試合を一括保存（バッチ処理）
  Future<void> saveMatchesBulk(List<MatchModel> newMatches) async {
    if (newMatches.isEmpty) return;
    try {
      await ref.read(localMatchRepositoryProvider).saveMatchesBulk(newMatches);
    } catch (e) {
      debugPrint('🔥 [Command Error] saveMatchesBulk: $e');
      throw Exception('一括保存に失敗しました');
    }
  }

  // 3. 判定による試合終了処理（Firestoreトランザクションを撤廃）
  Future<void> completeMatchWithHantei(MatchModel currentMatch, String hanteiResult, String? userId) async {
    try {
      MatchModel updatedMatch = currentMatch;
      if (hanteiResult == 'red' || hanteiResult == 'white') {
        final newEvent = ScoreEvent(
          id: const Uuid().v4(),
          side: hanteiResult == 'red' ? Side.red : Side.white,
          type: PointType.hantei,
          timestamp: DateTime.now(),
          userId: userId,
          sequence: currentMatch.events.isEmpty ? 1 : currentMatch.events.last.sequence + 1,
        );
        updatedMatch = updatedMatch.copyWith(
          events: [...currentMatch.events, newEvent],
          redScore: (currentMatch.redScore as num).toInt() + (hanteiResult == 'red' ? 1 : 0),
          whiteScore: (currentMatch.whiteScore as num).toInt() + (hanteiResult == 'white' ? 1 : 0),
        );
      }
      updatedMatch = updatedMatch.copyWith(
        status: 'finished',
        remainingSeconds: 0,
        timerIsRunning: false,
      );
      // 単一のsaveMatch（ローカルへの書き込み）に委譲
      await saveMatch(updatedMatch);
    } catch (e) {
      debugPrint('🔥 [Command Error] completeMatchWithHantei: $e');
      rethrow;
    }
  }

  // 4. スコアラー権限
  Future<bool> claimScorer(String matchId, String userId) async {
    final match = _getMatch(matchId);
    if (match == null) return false;
    if (match.scorerId == null || match.scorerId == userId) {
      await saveMatch(match.copyWith(scorerId: userId));
      return true;
    }
    return false;
  }

  Future<void> releaseScorer(String matchId, String userId) async {
    final match = _getMatch(matchId);
    if (match != null && match.scorerId == userId) {
      await saveMatch(match.copyWith(scorerId: null));
    }
  }

  // ★ Step 5-2: スコアラー権限の強制奪取 (テイクオーバー)
  // 前の担当者が操作不能になった場合などに、新しいユーザーが権限を上書きする
  Future<void> forceClaimScorer(String matchId, String userId) async {
    final match = _getMatch(matchId);
    if (match == null) return;
    
    // 現在の scorerId を無視して自分をセット
    await saveMatch(match.copyWith(scorerId: userId));
    debugPrint('⚡ Scorer Overwritten by: $userId');
  }

  // 5. 試合削除
  Future<void> deleteMatch(String matchId) async {
    await ref.read(localMatchRepositoryProvider).deleteMatch(matchId);
  }

  // 6. ★ Step 7-3: 誤操作防止ガード（テスト用：SnackBar表示版）
  Future<void> addScoreEvent(String matchId, Side side, PointType type) async {
    final now = DateTime.now();
    final currentKey = '$matchId-$side-$type';

    if (_lastScoreTime != null && 
        now.difference(_lastScoreTime!) < const Duration(milliseconds: 500) &&
        _lastScoreKey == currentKey) {
      
      // ★ テスト用：コンソールではなくUIに直接通知を出す
      ref.read(matchCommandErrorProvider.notifier).state = '🛡️ 連打防止：${type.name}をブロックしました';
      return;
    }

    _lastScoreTime = now;
    _lastScoreKey = currentKey;

    final match = _getMatch(matchId);
    if (match == null) return;
    
    final event = ScoreEvent(
      id: const Uuid().v4(),
      side: side,
      type: type,
      timestamp: now,
      userId: match.scorerId,
      sequence: match.events.isEmpty ? 1 : match.events.last.sequence + 1,
    );

    await ref.read(matchActionProvider).processScoreEvent(match, event);
  }

  Future<void> undoLastEvent(String matchId) async {
    final match = _getMatch(matchId);
    if (match == null || match.events.isEmpty) return;
    ref.read(matchActionProvider).undoEvent(match);
  }

  // 7. 新規試合の追加
  Future<void> addMatch(MatchModel newMatch) async {
    await saveMatch(newMatch);
  }

  // 8. ★ Step 4-4: 歴史(Events)からSnapshotを再構築（データ修復）
  Future<void> rebuildMatchSnapshot(String matchId) async {
    final match = _getMatch(matchId);
    if (match == null) return;
    
    final rule = ref.read(matchRuleProvider);
    // UseCaseの計算ロジックを使用して、歴史から真実を復元
    final rebuiltMatch = ref.read(matchUseCaseProvider).rebuildFromEvents(match, rule);
    
    // 計算結果をFirestoreへ強制同期
    await saveMatch(rebuiltMatch);
  }

  // 内部ヘルパー
  MatchModel? _getMatch(String id) {
    return ref.read(matchListProvider).where((m) => m.id == id).firstOrNull;
  }
}