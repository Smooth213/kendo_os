import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'match_list_provider.dart';
import 'match_provider.dart'; // ★ MatchActionProviderを参照するために必要
import 'package:kendo_os/domain/services/kendo_rule_engine.dart'; // ★ DomainExceptionを参照するために必要
import 'match_rule_provider.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart'; // ★ Firestore版からIsar版に差し替え
import 'sync_provider.dart'; // ★ 追加: クラウド同期ワーカー
import 'package:kendo_os/domain/entities/match_aggregate.dart'; // ★ 追加
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart'; // ★ 追加: UseCaseの参照
import 'package:kendo_os/application/usecases/match_application_service.dart'; // ★ CQRSルーター用

// ★ 修正: キューシステム導入に伴い、役割を明確にするため MatchCommandService にリネーム
final matchCommandServiceProvider = Provider<MatchCommandService>((ref) {
  return MatchCommandService(ref);
});

// ★ エラー一掃の鍵：既存の画面やテストが「MatchCommand」という型名を探しているため、
// 別名（エイリアス）を定義して、新しい Service クラスに橋渡しをします。
final matchCommandProvider = matchCommandServiceProvider;
typedef MatchCommand = MatchCommandService;

// ★ Step 3-6: 現在「書き込み処理中」かどうかを管理するProvider
// 連打による多重送信やデータ競合をUIレベルでブロックします
final isMatchCommandProcessingProvider = StateProvider<bool>((ref) => false);

// ★ Step 4-3: エラーメッセージをUIに伝えるためのProvider
final matchCommandErrorProvider = StateProvider<String?>((ref) => null);

class MatchCommandService {
  final Ref ref;
  MatchCommandService(this.ref);

  // ★ Step 7-3: 誤操作防止（デバウンス）用の管理変数
  DateTime? _lastScoreTime;
  String? _lastScoreKey;
  
  bool _isUndoing = false; // ★ 追加: Undo連打防止用フラグ

  // 1. 試合の保存（純粋なDB書き込み。二重送信防止はQueueが担当するためガードを撤廃）
  Future<void> saveMatch(MatchModel match) async {
    // 以前の if (ref.read(isMatchCommandProcessingProvider)) return; は削除しました
    ref.read(matchCommandErrorProvider.notifier).state = null;

    try {
      final matchToSave = match.copyWith(
        isDirty: true,
        lastUpdatedAt: DateTime.now(),
      );
      await ref.read(localMatchRepositoryProvider).saveMatch(matchToSave);
      
      // ★ Phase 3: ローカル保存後、即座にクラウドへ同期（UI反映のトリガー）
      Future.microtask(() => ref.read(syncEngineProvider).syncNow());
    } catch (e) {
      debugPrint('🔥 [Command Error]: $e');
      String msg = '保存に失敗しました';
      if (e is DomainException) msg = e.message;
      ref.read(matchCommandErrorProvider.notifier).state = msg;
    }
  }

  // 2. 複数の試合を一括保存（バッチ処理）
  Future<void> saveMatchesBulk(List<MatchModel> newMatches) async {
    if (newMatches.isEmpty) return;
    try {
      debugPrint('🚚 [2. 保存センサー] DBに渡す直前のRuleがnullか?: ${newMatches.first.rule == null}'); // ★ デバッグ用センサー
      await ref.read(localMatchRepositoryProvider).saveMatchesBulk(newMatches);
      
      // ★ Phase 3: 一括保存後も同期ワーカーをキック
      Future.microtask(() => ref.read(syncEngineProvider).syncNow());
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
        final newEvent = ScoreEventLegacyAdapter.fromLegacy(
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
    final typeLabel = {
      PointType.men: 'メン',
      PointType.kote: 'コテ',
      PointType.doIdo: 'ドウ',
      PointType.tsuki: 'ツキ',
      PointType.hansoku: '反則',
      PointType.fusen: '不戦勝',
      PointType.hantei: '判定',
    }[type] ?? type.name;

    final updatedMatch = await takeSnapshot(matchId, '【${side == Side.red ? "赤" : "白"}】$typeLabel 入力前');
    if (updatedMatch == null) return;

    final event = ScoreEventLegacyAdapter.fromLegacy(
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
    debugPrint('🔙 [Undo Start] matchId=$matchId');
    if (_isUndoing) return;
    _isUndoing = true;
    
    try {
      final match = await ref.read(localMatchRepositoryProvider).getMatch(matchId) ?? _getMatch(matchId);
      if (match == null || match.events.isEmpty) return;

      final updatedMatch = await takeSnapshot(matchId, '取り消し 実行前');
      if (updatedMatch == null) return;

      // 古い actionProvider ではなく、UseCase を用いて履歴から直近のイベントを消去
      final rule = ref.read(matchRuleProvider);
      MatchModel undoneMatch = ref.read(undoScoreUseCaseProvider).execute(updatedMatch, rule);

      // ★【CQRS化】ドメイン層（KendoRuleEngine）にスコアの完全再計算を委譲
      final engine = KendoRuleEngine();
      final analysis = engine.analyzeHistory(undoneMatch.events, undoneMatch, rule);

      // ★ ステータスの強制降格と、エンジンが算出した正確なスコアの上書き
      undoneMatch = undoneMatch.copyWith(
        status: 'in_progress',
        redScore: analysis.context.redIppon,
        whiteScore: analysis.context.whiteIppon,
      );

      await saveMatch(undoneMatch);
      debugPrint('🔙 [Undo Success] Re-calculated score: Red ${undoneMatch.redScore} - White ${undoneMatch.whiteScore}');
      
    } finally {
      _isUndoing = false;
    }
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
    final rebuiltMatch = ref.read(rebuildMatchFromEventsUseCaseProvider).execute(match, rule);
    
    // 計算結果をFirestoreへ強制同期
    await saveMatch(rebuiltMatch);
  }

  // ==========================================
  // ★ Phase 1: スナップショット（エラー復旧）機能
  // ==========================================

  // スナップショットの作成（特定時点のバックアップ）
  // ★ 修正: 保存後の最新データを return で返すように変更
  Future<MatchModel?> takeSnapshot(String matchId, String reason) async {
    // Riverpodのキャッシュラグを回避するため、DBから直接最新データを取得
    final match = await ref.read(localMatchRepositoryProvider).getMatch(matchId) ?? _getMatch(matchId);
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
    final restoreEvent = ScoreEventLegacyAdapter.fromLegacy(
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

// ============================================================================
// ★【Phase 1: 堅牢化】オフラインファースト・キューシステムの基盤
// ============================================================================

enum CommandType { addScore, undoLastEvent, approveMatch }
enum CommandStatus { pending, done, failed }

// 1. 操作の意図をパッキングするデータクラス (名前の競合を避けるため Model を付与)
class MatchCommandModel {
  final String id;
  final CommandType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  CommandStatus status;

  MatchCommandModel({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.status = CommandStatus.pending,
  });
}

// 2. キュー（FIFO）を管理し、順番に処理を実行するプロバイダ
final matchCommandQueueProvider = Provider<MatchCommandQueue>((ref) {
  final queue = MatchCommandQueue(ref);
  queue.init(); // 起動時にDBから未処理コマンドを拾い上げる
  return queue;
});

// ============================================================================
// ★ Phase 2: デッドレターキュー（送信エラーデータ）の可視化と操作プロバイダ
// ============================================================================

class DeadLetterQueueNotifier extends Notifier<List<MatchCommandModel>> {
  @override
  List<MatchCommandModel> build() => [];

  // キューにエラーデータを追加（MatchCommandQueueから呼ばれる）
  void addErrorCommand(MatchCommandModel cmd) {
    state = [...state, cmd];
  }

  // エラーデータを再送キューに戻す
  Future<void> retryCommand(MatchCommandModel cmd) async {
    final queue = ref.read(matchCommandQueueProvider);
    state = state.where((c) => c.id != cmd.id).toList(); // リストから消す
    
    // エラーカウントをリセットして再度キューに突っ込む
    final newCmd = MatchCommandModel(
      id: cmd.id,
      type: cmd.type,
      payload: cmd.payload,
      createdAt: cmd.createdAt,
      status: CommandStatus.pending,
    );
    await queue.enqueue(newCmd);
  }

  // エラーデータを完全に破棄する
  void discardCommand(MatchCommandModel cmd) {
    state = state.where((c) => c.id != cmd.id).toList();
  }
}

final deadLetterQueueProvider = NotifierProvider<DeadLetterQueueNotifier, List<MatchCommandModel>>(() {
  return DeadLetterQueueNotifier();
});

class MatchCommandQueue {
  final Ref ref;
  final List<MatchCommandModel> _queue = [];
  // ★ 修正: 内部リストではなく、Notifierを通してUIと連動させるように変更
  // final List<MatchCommandModel> _deadLetterQueue = [];
  final Map<String, int> _errorCounts = {};
  bool _isProcessing = false;

  MatchCommandQueue(this.ref);

  Future<void> init() async {
    final localRepo = ref.read(localMatchRepositoryProvider);
    final pendingCommands = await localRepo.getPendingCommands();
    if (pendingCommands.isNotEmpty) {
      _queue.addAll(pendingCommands);
      _process();
    }
  }

  Future<void> enqueue(MatchCommandModel cmd) async {
    _queue.add(cmd);
    _process();
  }

  Future<void> _process() async {
    if (_isProcessing) return;
    _isProcessing = true;
    ref.read(isMatchCommandProcessingProvider.notifier).state = true;

    final localRepo = ref.read(localMatchRepositoryProvider);

    try {
      while (_queue.isNotEmpty) {
        final cmd = _queue.first;
        await localRepo.savePendingCommand(cmd);

        try {
          await _executeCommand(cmd);
          await localRepo.deleteCommand(cmd.id);
          _queue.removeAt(0); 
          _errorCounts.remove(cmd.id);
        } catch (e) {
          _errorCounts[cmd.id] = (_errorCounts[cmd.id] ?? 0) + 1;
          debugPrint('🔥 [CommandQueue] 処理失敗 (${_errorCounts[cmd.id]}回目): $e');
          
          if (_errorCounts[cmd.id]! >= 3) {
            debugPrint('🚨 [CommandQueue] 失敗上限到達。デッドレターキューへ退避: ${cmd.id}');
            // ★ 修正: 内部リストではなくプロバイダに送ってUIと連動させる
            ref.read(deadLetterQueueProvider.notifier).addErrorCommand(cmd); 
            _queue.removeAt(0);
            await localRepo.deleteCommand(cmd.id);
            ref.read(matchCommandErrorProvider.notifier).state = '一部のデータが保存できず退避されました。電波状況を確認してください。';
          } else {
            break; // リトライのため一旦ループを抜ける
          }
        }
      }
    } finally {
      _isProcessing = false;
      ref.read(isMatchCommandProcessingProvider.notifier).state = false;

      // ★ Phase 3: 全てのコマンドがローカルDBに確定した直後、クラウド同期を開始
      ref.read(syncEngineProvider).syncNow();
    }
  }

  Future<void> _executeCommand(MatchCommandModel cmd) async {
    // キュー処理からApplicationServiceの正式フローへルーティングする
    final appService = ref.read(matchApplicationServiceProvider);
    final matchId = cmd.payload['matchId'] as String;

    switch (cmd.type) {
      case CommandType.addScore:
        final sideStr = cmd.payload['side'] as String;
        final typeStr = cmd.payload['type'] as String;
        final side = Side.values.firstWhere((e) => e.name == sideStr, orElse: () => Side.none);
        final type = PointType.values.firstWhere((e) => e.name == typeStr, orElse: () => PointType.men);
        
        // ★ UI側が古い形式(PointType.undo)で取り消しコマンドを送ってきた場合のガードルーティング
        if (type == PointType.undo) {
          await appService.undo(matchId);
        } else {
          await appService.addIppon(matchId, side, type);
        }
        break;
      case CommandType.undoLastEvent:
        await appService.undo(matchId);
        break;
      case CommandType.approveMatch:
        await appService.approveMatch(matchId);
        break;
    }
  }
}