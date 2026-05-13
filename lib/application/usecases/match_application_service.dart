import 'package:flutter/foundation.dart'; // ★ 追加: debugPrintを使うためのインポート
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User; // ★ Firebase側のUserを隠し、自作のUserとの衝突を防ぐ
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/audit_log.dart';
import 'package:kendo_os/domain/entities/score_event.dart'; 
import 'package:kendo_os/domain/entities/match_context.dart'; 
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/entities/role_permission.dart'; // ★ Userモデル用に追加
import 'package:kendo_os/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/infrastructure/repository/in_memory_projection_store.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart'; 
import 'package:kendo_os/domain/entities/match_aggregate.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart'; 
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/presentation/operate/providers/match_rule_provider.dart';
import 'package:kendo_os/presentation/operate/providers/settings_provider.dart';
// ★ match_command_provider.dart のインポートを削除 (相互依存エラー解消のため)
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/presentation/operate/providers/audit_provider.dart';
import 'package:kendo_os/presentation/operate/providers/ui_message_provider.dart'; // ★ 追加: 通知司令塔
import 'package:kendo_os/application/services/sound_service.dart';
import 'package:kendo_os/domain/services/match_domain_service.dart'; // ★ 追加
import 'package:kendo_os/presentation/operate/providers/sync_provider.dart'; // ★ 追加: 同期エンジン
import 'package:kendo_os/presentation/operate/providers/metrics_provider.dart'; // ★ 追加: メトリクス基盤

// ==========================================
// ★ ApplicationService設計：フローの完全集約と安全網
// アプリケーション層はオーケストレーションに専念し、ドメインロジックはMatchDomainServiceに委譲する
// ==========================================

class MatchApplicationService {
  final Ref _ref;
  final AddScoreUseCase _addScore;
  final TimeUpUseCase _timeUp;
  final MatchDomainService _domainService;

  MatchApplicationService(this._ref, this._addScore, this._timeUp, this._domainService);

  // ==========================================
  // ★ Phase 1-Step 1: 実行主体(User)の取得ヘルパー
  // 現在は仮取得。後でRoleProvider等と完全に結線します。
  // ==========================================
  User _getCurrentUser() {
    String uid = 'unknown_user';
    try {
      // 本番環境用
      uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
    } catch (_) {
      // ★ テスト環境などでFirebaseが未初期化の場合はクラッシュを防ぐ
      uid = 'test_user';
    }
    
    return User(
      id: uid,
      role: Role.admin, // 暫定で管理者権限
      organizationId: 'default_org',
    );
  }

  // --- ヘルパー：エラーをキャッチして通知する安全網 ---
  Future<void> _safeExecute(Future<void> Function() action, String errorPrefix, {String? metricName, String? traceId}) async {
    final stopwatch = Stopwatch()..start(); // ★ Phase 2: メトリクス計測開始
    try {
      await action();
      stopwatch.stop();
      if (metricName != null) {
        // ★ メトリクス：成功時にレイテンシとカウントを記録
        _ref.read(metricsProvider).recordLatency(metricName, stopwatch.elapsedMilliseconds, traceId: traceId);
      }
    } catch (e) {
      stopwatch.stop();
      // ★ メトリクス：競合エラーを検知してカウント
      if (e.toString().contains('Concurrency') || e.toString().contains('競合') || e.toString().contains('他の端末')) {
        _ref.read(metricsProvider).recordConcurrencyConflict(traceId: traceId);
      } else {
        // ★ 追加: 一般的なエラーもカウントし、エラー率を上昇させる
        _ref.read(metricsProvider).recordError(traceId: traceId);
      }
      
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
    final traceId = const Uuid().v4(); // ★ Phase 2-3: トレースID発行
    await _safeExecute(() async {
      // DBから直接最新状態を取得し、上書きによる競合を防ぐ
      final localRepo = _ref.read(localMatchRepositoryProvider);
      final initialMatch = await localRepo.getMatch(matchId) ?? _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
      if (initialMatch == null) return;
      
      // ★ 修正: 試合自体が専用のルールを持っている場合はそれを優先する
      final MatchRule rule = initialMatch.rule ?? _ref.read(matchRuleProvider);
      final settings = _ref.read(settingsProvider);
      final currentUser = _getCurrentUser(); // ★ 主体を取得

      // DB保存回数を減らして点滅を防ぐため、スナップショットはメモリ上でのみ追加する
      final typeLabel = {PointType.men: 'メン', PointType.kote: 'コテ', PointType.doIdo: 'ドウ', PointType.tsuki: 'ツキ', PointType.hansoku: '反則', PointType.fusen: '不戦勝', PointType.hantei: '判定'}[type] ?? type.name;
      var match = _addSnapshotToMatch(initialMatch, '【${side == Side.red ? "赤" : "白"}】$typeLabel 入力前');

      int maxClock = match.events.isEmpty ? 0 : match.events.map((e) => e.logicalClock).reduce((a, b) => a > b ? a : b);

      final event = ScoreEventLegacyAdapter.fromLegacy(
        id: const Uuid().v4(),
        side: side,
        type: type,
        timestamp: DateTime.now(),
        userId: currentUser.id, // ★ イベントにも主体を記録
        sequence: match.events.isEmpty ? 1 : match.events.last.sequence + 1,
        logicalClock: maxClock + 1, // ★ 追加: CRDT同期時にイベント順序が過去にワープするのを防ぐ
      );

      // ★ UseCaseに主体を渡す
      final updatedMatch = _addScore.execute(currentUser, match, event, rule);

      final soundService = _ref.read(soundServiceProvider);
      final mode = settings.audioFeedbackMode;
      final sideLabel = side == Side.red ? '赤' : '白';
      // typeLabel は既に上で定義済みのため再宣言不要

      if (mode == 'voice') {
        soundService.speak('$sideLabel、$typeLabel！');
        if (updatedMatch.status == 'finished' && match.status != 'finished') {
          Future.delayed(const Duration(milliseconds: 1000), () => soundService.speak('試合終了です'));
        }
      } else if (mode == 'effect') {
        if (type == PointType.hansoku) {
          soundService.playHansokuSound();
        } else {
          soundService.playScoreSound(side == Side.red);
        }
        if (updatedMatch.status == 'finished' && match.status != 'finished') {
          soundService.playFinishFanfare();
        }
      }

      // ここで1回だけDB書き込みが走り、UIが1度だけ更新される（点滅の完全解消）
      await _saveAndSync(updatedMatch);
      await _ref.read(auditProvider).logAction(matchId: match.id, action: AuditAction.addScore, details: '${side.name} ${type.name}', traceId: traceId);

      await _finalizeIfNeeded(updatedMatch, match);
    }, '端末にスコアが保存されませんでした。もう一度お試しください', metricName: 'event_append', traceId: traceId);
  }

  // --------------------------------------------------
  // 2. Undoフロー
  // --------------------------------------------------
  Future<void> undo(String matchId) async {
    final traceId = const Uuid().v4(); // ★ Phase 2-3: トレースID発行
    await _safeExecute(() async {
      final localRepo = _ref.read(localMatchRepositoryProvider);
      final initialMatch = await localRepo.getMatch(matchId) ?? _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
      if (initialMatch == null) return;

      // ★ 修正: もう消すイベントがない（0件）の場合は、エラーを吐かずに静かに終了する
      if (initialMatch.events.isEmpty) {
        debugPrint('取り消すイベントがありません（スキップ）');
        return; 
      }
      
      var match = _addSnapshotToMatch(initialMatch, '取り消し 実行前');
      
      // ★ 修正
      final MatchRule rule = match.rule ?? _ref.read(matchRuleProvider);
      final currentUser = _getCurrentUser(); // ★ 主体を取得

      int maxClock = match.events.isEmpty ? 0 : match.events.map((e) => e.logicalClock).reduce((a, b) => a > b ? a : b);

      // ★ 修正: 旧式の _undoScore UseCase はセキュリティ署名更新から漏れていたため廃止。
      // 正規のセキュリティチェックを完璧に通過する _addScore.execute に「Undoイベント」として流し込む形に統一します。
      final undoEvent = ScoreEventLegacyAdapter.fromLegacy(
        id: 'undo-${DateTime.now().microsecondsSinceEpoch}',
        side: Side.none,
        type: PointType.undo,
        timestamp: DateTime.now(),
        userId: currentUser.id,
        sequence: match.events.last.sequence + 1,
        logicalClock: maxClock + 1, // ★ 追加: CRDT同期時にUndoイベントが過去にワープして無視されるのを防ぐ
      );

      MatchModel updatedMatch = _addScore.execute(currentUser, match, undoEvent, rule);
      
      // ★【CQRS化】ドメイン層（KendoRuleEngine）にスコアの完全再計算を委譲し、Undoを完璧に機能させる
      final engine = KendoRuleEngine();
      final analysis = engine.analyzeHistory(updatedMatch.events, updatedMatch, rule);

      updatedMatch = updatedMatch.copyWith(
        status: 'in_progress',
        redScore: analysis.context.redIppon,
        whiteScore: analysis.context.whiteIppon,
      );
      
      final mode = _ref.read(settingsProvider).audioFeedbackMode;
      if (mode == 'voice') {
        _ref.read(soundServiceProvider).speak('取り消し');
      } else if (mode == 'effect') {
        _ref.read(soundServiceProvider).playUndoSound();
      }


      await _saveAndSync(updatedMatch);
      await _ref.read(auditProvider).logAction(matchId: match.id, action: AuditAction.undo, details: '取消', traceId: traceId);
    }, '操作を取り消せませんでした。もう一度お試しください', metricName: 'event_undo', traceId: traceId);
  }

  // --------------------------------------------------
  // ★ Phase 5-Step 2: タイムトラベル（指定バージョンへの巻き戻し）
  // 1件ずつのUndoではなく、歴史を指定した時点(V)まで一気に切り詰める
  // --------------------------------------------------
  Future<void> rewindTo(String matchId, int targetVersion) async {
    final traceId = const Uuid().v4(); // ★ Phase 2-3: トレースID発行
    await _safeExecute(() async {
      final localRepo = _ref.read(localMatchRepositoryProvider);
      final initialMatch = await localRepo.getMatch(matchId) ?? _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
      
      if (initialMatch == null) return;

      final engine = KendoRuleEngine();
      final validEvents = engine.filterActiveEvents(initialMatch.events);

      // 指定したバージョンが現在の有効なイベント数以上の場合は何もしない
      if (validEvents.length <= targetVersion) return;

      // 1. スナップショット作成（巻き戻す前の「今の状態」を念のため保存）
      var match = _addSnapshotToMatch(initialMatch, '巻き戻し実行 (Version: $targetVersion へ)');

      // ★ 最終解決策: 物理削除(truncate)はCRDT同期時に競合しやすいため、
      // 確定済みの試合であっても強制的に「Undoイベントの追記」で歴史を巻き戻します。
      
      // 1. まず、勝敗が確定していても操作を受け付けるようにステータスを強制解除
      // ★ 修正: 存在しない「winner」プロパティの指定を削除し、サイレントな実行時エラーを完全に防ぐ
      MatchModel processMatch = match.copyWith(status: 'in_progress');
      
      int undoCount = validEvents.length - targetVersion;
      final currentUser = _getCurrentUser();
      final MatchRule rule = match.rule ?? _ref.read(matchRuleProvider);
      
      // 超高速ループでも絶対に被らないタイムスタンプID
      final String syncSeed = DateTime.now().microsecondsSinceEpoch.toString();

      int maxClock = processMatch.events.isEmpty ? 0 : processMatch.events.map((e) => e.logicalClock).reduce((a, b) => a > b ? a : b);

      for (int i = 0; i < undoCount; i++) {
        maxClock++;
        final undoEvent = ScoreEventLegacyAdapter.fromLegacy(
          id: 'rewind-$matchId-$syncSeed-$i', // ★ IDの完全ユニーク化
          side: Side.none,
          type: PointType.undo,
          timestamp: DateTime.now().add(Duration(milliseconds: i)),
          userId: currentUser.id,
          sequence: processMatch.events.isEmpty ? 1 : processMatch.events.last.sequence + 1,
          logicalClock: maxClock, // ★ 追加: タイムトラベル復元時のイベント順序保証
        );
        // 一つずつイベントを適用して状態を更新
        processMatch = _addScore.execute(currentUser, processMatch, undoEvent, rule);
      }
      
      // 3. ルールエンジンで最終的なスコアと表示を確定
      final analysis = engine.analyzeHistory(processMatch.events, processMatch, rule);

      final updatedMatch = processMatch.copyWith(
        status: 'in_progress', 
        redScore: analysis.context.redIppon,
        whiteScore: analysis.context.whiteIppon,
        syncState: SyncState.localOnly, 
        lastUpdatedAt: DateTime.now(),
      );

      await _saveAndSync(updatedMatch);
      await _ref.read(auditProvider).logAction(
        matchId: match.id, 
        action: AuditAction.undo, 
        details: 'タイムトラベル実行: $targetVersion件目のイベントまで復元',
        traceId: traceId,
      );
    }, 'データの巻き戻しに失敗しました', traceId: traceId);
  }

  // --------------------------------------------------
  // ヘルパー：スナップショットの追加（メモリ上のみ）
  // --------------------------------------------------
  MatchModel _addSnapshotToMatch(MatchModel match, String reason) {
    final snapshot = MatchSnapshot(
      id: const Uuid().v4(),
      matchId: match.id,
      version: match.events.length,
      state: match,
      createdAt: DateTime.now(),
      reason: reason,
      events: List.from(match.events),
    );
    final newSnapshots = [...match.snapshots, snapshot];
    if (newSnapshots.length > 20) {
      newSnapshots.removeRange(0, newSnapshots.length - 20);
    }
    return match.copyWith(snapshots: newSnapshots);
  }

  // --------------------------------------------------
  // 3. 時間切れ（TimeUp）フロー
  // --------------------------------------------------
  Future<void> handleTimeUp(String matchId) async {
    final traceId = const Uuid().v4(); // ★ Phase 2-3: トレースID発行
    await _safeExecute(() async {
      final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
      if (match == null) return;
      // ★ 修正
      final MatchRule rule = match.rule ?? _ref.read(matchRuleProvider);
      final currentUser = _getCurrentUser(); // ★ 主体を取得

      final canExtend = rule.isEnchoUnlimited || rule.enchoCount > 0;
      
      // ★ UseCaseに主体を渡す
      final updatedMatch = _timeUp.execute(currentUser, match, canExtend, rule);
      
      final mode = _ref.read(settingsProvider).audioFeedbackMode;
      if (updatedMatch.status == 'finished') {
        if (mode == 'voice') {
          _ref.read(soundServiceProvider).speak('時間切れ、試合終了です');
        } else if (mode == 'effect') {
          _ref.read(soundServiceProvider).playFinishFanfare(); 
        }
      }

      await _saveAndSync(updatedMatch);
      await _ref.read(auditProvider).logAction(matchId: match.id, action: AuditAction.timeUp, details: '時間切れ', traceId: traceId);

      await _finalizeIfNeeded(updatedMatch, match);
    }, '時間切れ処理に失敗しました', traceId: traceId);
  }

  // --------------------------------------------------
  // 4. 共通保存ロジック（★ 修正: 外部からも呼べるようにパブリック化し、ローカルリポジトリへ直接つなぐ）
  // UIからの保存要求も、必ずここ（ApplicationService）を経由させる
  // --------------------------------------------------
  Future<void> saveMatch(MatchModel match) async {
    await _safeExecute(() async {
      // 保存時に未送信キュー（Queue）を通す場合は matchCommandQueueProvider 経由でも良いですが、
      // ここは直接リポジトリを叩く「真の保存処理」として定義します。
      final matchToSave = match.copyWith(
        syncState: SyncState.localOnly, // ★ isDirty: true を SyncState に修正
        lastUpdatedAt: DateTime.now(),
      );
      await _ref.read(localMatchRepositoryProvider).saveMatch(matchToSave);
      
      // 同期キック
      Future.microtask(() => _ref.read(syncEngineProvider).syncNow());
    }, '保存に失敗しました');
  }

  // 複数の試合を一括保存
  Future<void> saveMatchesBulk(List<MatchModel> newMatches) async {
    await _safeExecute(() async {
      if (newMatches.isEmpty) return;
      await _ref.read(localMatchRepositoryProvider).saveMatchesBulk(newMatches);
      Future.microtask(() => _ref.read(syncEngineProvider).syncNow());
    }, '一括保存に失敗しました');
  }

  Future<void> _saveAndSync(MatchModel match) async {
    await saveMatch(match);
    
    // ★ 追加: ProjectionStoreも更新してViewerモードをサポート
    final rule = match.rule ?? _ref.read(matchRuleProvider);
    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(match.events, match, rule);
    final projection = MatchProjectionMapper.toMatchProjection(match, analysis);
    await _ref.read(projectionStoreProvider).save(projection);
  }

  // --------------------------------------------------
  // ★ Phase 3: スコアラー権限（有効期限付きロック機構）
  // --------------------------------------------------
  Future<bool> claimScorer(String matchId, String userId) async {
    final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
    if (match == null) return false;
    
    final now = DateTime.now();
    final isLockExpired = match.lockExpiresAt != null && match.lockExpiresAt!.isBefore(now);
    
    if (match.scorerId == null || match.scorerId == userId || isLockExpired) {
      final expiresAt = now.add(const Duration(minutes: 30));
      await saveMatch(match.copyWith(scorerId: userId, lockExpiresAt: expiresAt));
      return true;
    }
    return false;
  }

  Future<void> releaseScorer(String matchId, String userId) async {
    final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
    if (match != null && match.scorerId == userId) {
      await saveMatch(match.copyWith(scorerId: null, lockExpiresAt: null));
    }
  }

  Future<void> forceClaimScorer(String matchId, String userId) async {
    final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
    if (match == null) return;
    
    final expiresAt = DateTime.now().add(const Duration(minutes: 30));
    await saveMatch(match.copyWith(scorerId: userId, lockExpiresAt: expiresAt));
  }

  // --------------------------------------------------
  // 5. 手動ステータス変更
  // --------------------------------------------------
  Future<void> approveMatch(String matchId) async {
    final traceId = const Uuid().v4(); // ★ Phase 2-3: トレースID発行
    await _safeExecute(() async {
      final match = _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
      if (match == null) return;
      await _saveAndSync(match.copyWith(status: 'approved'));
    }, '試合の確定ができませんでした。もう一度お試しください', traceId: traceId); // approveMatch
  }

  Future<void> finishMatch(String matchId) async {
    final traceId = const Uuid().v4(); // ★ Phase 2-3: トレースID発行
    await _safeExecute(() async {
      final localRepo = _ref.read(localMatchRepositoryProvider);
      final match = await localRepo.getMatch(matchId) ?? _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
      if (match == null) return;
      
      // ★ 修正: タイマー停止やロック解除もここで行う
      final updated = match.copyWith(
        status: 'finished', 
        timerStartedAt: null,
        hasExtension: false,
        scorerId: null,
        syncState: SyncState.localOnly, // ★ isDirty: true を SyncState に修正
        lastUpdatedAt: DateTime.now()
      );
      await _saveAndSync(updated);
      await _finalizeIfNeeded(updated, match);
    }, '試合終了の保存に失敗しました', traceId: traceId);
  }

  // ★ 追加: 手動終了用（マーカーの追加と終了を1回のDB書き込みで行い、同期競合を防ぐ）
  Future<void> finishMatchManually(String matchId, {Side? hanteiWinner}) async {
    final traceId = const Uuid().v4(); // ★ Phase 2-3: トレースID発行
    await _safeExecute(() async {
      final localRepo = _ref.read(localMatchRepositoryProvider);
      final match = await localRepo.getMatch(matchId) ?? _ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
      if (match == null) return;
      
      // ★ 修正
      final MatchRule rule = match.rule ?? _ref.read(matchRuleProvider);
      final currentUser = _getCurrentUser(); // ★ 主体を取得
      
      int maxClock = match.events.isEmpty ? 0 : match.events.map((e) => e.logicalClock).reduce((a, b) => a > b ? a : b);

      // 1. マーカーまたは判定イベントの作成
      final side = hanteiWinner ?? Side.none;
      final event = ScoreEventLegacyAdapter.fromLegacy(
        id: const Uuid().v4(),
        side: side,
        type: PointType.hantei,
        timestamp: DateTime.now(),
        userId: currentUser.id, // ★ イベントにも主体を記録
        sequence: match.events.isEmpty ? 1 : match.events.last.sequence + 1,
        logicalClock: maxClock + 1, // ★ 追加: 判定イベント順序保証
      );

      // 2. スコアの追加計算（判定勝ちなら得点が入る）
      // ★ UseCaseに主体を渡す
      MatchModel updated = _addScore.execute(currentUser, match, event, rule);

      // 3. 強制的に終了ステータスで上書きし、ロックなどを解除
      updated = updated.copyWith(
        status: 'finished', 
        timerStartedAt: null,
        hasExtension: false,
        scorerId: null,
        syncState: SyncState.localOnly, // ★ isDirty: true を SyncState に修正
        lastUpdatedAt: DateTime.now()
      );

      // 4. 1回の保存で済ませる（同期競合を完全に防ぐ）
      await _saveAndSync(updated);
      
      final settings = _ref.read(settingsProvider);
      final mode = settings.audioFeedbackMode;
      if (updated.status == 'finished' && match.status != 'finished') {
        if (mode == 'voice') {
          _ref.read(soundServiceProvider).speak('試合終了です');
        } else if (mode == 'effect') {
          _ref.read(soundServiceProvider).playFinishFanfare();
        }
      }

      await _finalizeIfNeeded(updated, match);
    }, '試合の終了保存に失敗しました', traceId: traceId);
  }

  // --------------------------------------------------
  // 6. 試合終了時の自動判定・進行処理（UIから移動してきたロジック）
  // --------------------------------------------------
  Future<void> _finalizeIfNeeded(MatchModel updatedMatch, MatchModel oldMatch) async {
    // 1. 自動で不戦勝を入れる処理
    await _autoProcessFusenIfNeeded(updatedMatch);

    // 2. 勝敗が決定（規定本数到達）していれば自動で終了処理へ
    if (updatedMatch.status != 'finished' && updatedMatch.status != 'approved') {
      // ★ 修正
      final MatchRule rule = updatedMatch.rule ?? _ref.read(matchRuleProvider);
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
    final fusenEvents = _domainService.generateAutoFusenEvents(match);
    for (var event in fusenEvents) {
      await addIppon(match.id, event.side, event.type);
    }
    if (match.redName.contains('欠員') && match.whiteName.contains('欠員') && match.status != 'finished') {
      await finishMatch(match.id);
    }
  }

  Future<void> _generateNextKachinukiMatchIfNeeded(MatchModel match) async {
    // ★ 修正
    final MatchRule rule = match.rule ?? _ref.read(matchRuleProvider);
    final nextMatch = _domainService.generateNextKachinukiMatch(match, rule);
    if (nextMatch != null) {
      await _saveAndSync(nextMatch);
    }
  }

  Future<void> _propagateNameToNextMatch(MatchModel finishedMatch) async {
    final matches = _ref.read(matchListProvider);
    final updatedMatches = _domainService.propagateNameToNextMatches(finishedMatch, matches);
    for (var m in updatedMatches) {
      await _saveAndSync(m);
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
  return MatchApplicationService(ref, ref.watch(addScoreUseCaseProvider), ref.watch(timeUpUseCaseProvider), MatchDomainService());
});