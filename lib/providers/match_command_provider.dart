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
      // ★ Phase 2: すべてのローカル操作を「未送信（isDirty = true）」として確実に同期キューへ入れる
      // タイムスタンプも更新し、クラウド側での競合解決（バージョン管理）に備える
      final matchToSave = match.copyWith(
        isDirty: true,
        lastUpdatedAt: DateTime.now(),
      );
      await ref.read(localMatchRepositoryProvider).saveMatch(matchToSave);
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
      debugPrint('🚚 [2. 保存センサー] DBに渡す直前のRuleがnullか?: ${newMatches.first.rule == null}'); // ★ デバッグ用センサー
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

  // 4. ★ Phase 3: スコアラー権限（有効期限付きロック機構）
  Future<bool> claimScorer(String matchId, String userId) async {
    final match = _getMatch(matchId);
    if (match == null) return false;
    
    final now = DateTime.now();
    final isLockExpired = match.lockExpiresAt != null && match.lockExpiresAt!.isBefore(now);
    
    // ロックが空、自分のロック、または「他人のロックだが有効期限切れ（放置状態）」の場合
    if (match.scorerId == null || match.scorerId == userId || isLockExpired) {
      // 30分の有効期限でロックを取得・更新（剣道の試合には十分すぎる猶予時間）
      final expiresAt = now.add(const Duration(minutes: 30));
      await saveMatch(match.copyWith(scorerId: userId, lockExpiresAt: expiresAt));
      return true;
    }
    return false;
  }

  Future<void> releaseScorer(String matchId, String userId) async {
    final match = _getMatch(matchId);
    if (match != null && match.scorerId == userId) {
      await saveMatch(match.copyWith(scorerId: null, lockExpiresAt: null));
    }
  }

  // ★ Phase 3: スコアラー権限の強制奪取 (テイクオーバー)
  Future<void> forceClaimScorer(String matchId, String userId) async {
    final match = _getMatch(matchId);
    if (match == null) return;
    
    final expiresAt = DateTime.now().add(const Duration(minutes: 30));
    await saveMatch(match.copyWith(scorerId: userId, lockExpiresAt: expiresAt));
    debugPrint('⚡ Scorer Overwritten by: $userId (Lock Extended)');
  }

  // 5. 試合削除
  Future<void> deleteMatch(String matchId) async {
    await ref.read(localMatchRepositoryProvider).deleteMatch(matchId);
  }

  // --- ★ フェーズ4：チーム名の一括置換（合流）ロジック ---
  /// 特定の大会内で、古いチーム名を新しいチーム名へ全試合一括で書き換える
  Future<void> renameTeamBulk({
    required String tournamentId,
    required String oldTeamName,
    required String newTeamName,
  }) async {
    final allMatches = ref.read(matchListProvider);
    // 対象の大会の試合に絞り込む
    final targetMatches = allMatches.where((m) => m.tournamentId == tournamentId).toList();
    
    List<MatchModel> updatedMatches = [];

    for (var m in targetMatches) {
      bool isChanged = false;
      String rName = m.redName;
      String wName = m.whiteName;

      // 赤チームの判定と置換
      if (rName.contains(':')) {
        final parts = rName.split(':');
        if (parts[0].trim() == oldTeamName) {
          rName = '$newTeamName : ${parts[1].trim()}';
          isChanged = true;
        }
      } else if (rName.trim() == oldTeamName) {
        rName = newTeamName;
        isChanged = true;
      }

      // 白チームの判定と置換
      if (wName.contains(':')) {
        final parts = wName.split(':');
        if (parts[0].trim() == oldTeamName) {
          wName = '$newTeamName : ${parts[1].trim()}';
          isChanged = true;
        }
      } else if (wName.trim() == oldTeamName) {
        wName = newTeamName;
        isChanged = true;
      }

      if (isChanged) {
        updatedMatches.add(m.copyWith(
          redName: rName,
          whiteName: wName,
          isDirty: true,
          lastUpdatedAt: DateTime.now(),
        ));
      }
    }

    if (updatedMatches.isNotEmpty) {
      await saveMatchesBulk(updatedMatches);
      debugPrint('⚡ Team Renamed Bulk: $oldTeamName -> $newTeamName (${updatedMatches.length} matches)');
    }
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
    
    // ★ 修正: バトンタッチ。スナップショットが追加された「最新の状態」を受け取る
    // type.name から type.label (日本語) に変更
    final updatedMatch = await takeSnapshot(matchId, '【${side == Side.red ? "赤" : "白"}】${type.label} 入力前');
    if (updatedMatch == null) return;

    final event = ScoreEvent(
      id: const Uuid().v4(),
      side: side,
      type: type,
      timestamp: now,
      userId: updatedMatch.scorerId,
      sequence: updatedMatch.events.isEmpty ? 1 : updatedMatch.events.last.sequence + 1,
    );

    // 古い match ではなく、updatedMatch を渡すことで上書き消滅を防ぐ
    await ref.read(matchActionProvider).processScoreEvent(updatedMatch, event);
  }

  Future<void> undoLastEvent(String matchId) async {
    final match = _getMatch(matchId);
    if (match == null || match.events.isEmpty) return;
    
    // ★ 修正: Undo直前のスナップショットを撮り、最新の状態を受け取る
    final updatedMatch = await takeSnapshot(matchId, '取り消し 実行前');
    if (updatedMatch == null) return;
    
    ref.read(matchActionProvider).undoEvent(updatedMatch);
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

  // ==========================================
  // ★ Phase 1: スナップショット（エラー復旧）機能
  // ==========================================

  // スナップショットの作成（特定時点のバックアップ）
  // ★ 修正: 保存後の最新データを return で返すように変更
  Future<MatchModel?> takeSnapshot(String matchId, String reason) async {
    final match = _getMatch(matchId);
    if (match == null) return null;
    
    final snapshot = MatchSnapshot(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      reason: reason,
      events: List.from(match.events), // その時点のイベント履歴を完全コピー
    );

    // ★ プロの工夫: ストレージ圧迫を防ぐため、最新20件のみを保持する（古いものを捨てる）
    final newSnapshots = [...match.snapshots, snapshot];
    if (newSnapshots.length > 20) {
      newSnapshots.removeRange(0, newSnapshots.length - 20);
    }

    final updatedMatch = match.copyWith(snapshots: newSnapshots);
    await saveMatch(updatedMatch);
    return updatedMatch; // 最新の状態を返す
  }

  // スナップショットからの復元
  Future<void> restoreFromSnapshot(String matchId, MatchSnapshot snapshot) async {
    final match = _getMatch(matchId);
    if (match == null) return;

    // 復元したという事実も「1つのイベント」として歴史に刻む（非破壊原則）
    final restoreEvent = ScoreEvent(
      id: const Uuid().v4(),
      side: Side.none,
      type: PointType.restore,
      timestamp: DateTime.now(),
      userId: match.scorerId,
      sequence: match.events.isEmpty ? 1 : match.events.last.sequence + 1,
    );

    // 新しい歴史 ＝ スナップショット時点の歴史 ＋ 復元イベント
    final newEvents = [...snapshot.events, restoreEvent];

    // 状態を上書きし、rebuildMatchSnapshot を呼んでスコアなどを再計算させる
    await saveMatch(match.copyWith(events: newEvents));
    await rebuildMatchSnapshot(matchId);
    
    // 復元後、現在の状態を「復元直後」として再度スナップショットを取っておくとさらに安全
    await takeSnapshot(matchId, '【復元】${snapshot.reason} の時点');
  }

  // 内部ヘルパー
  MatchModel? _getMatch(String id) {
    return ref.read(matchListProvider).where((m) => m.id == id).firstOrNull;
  }
}