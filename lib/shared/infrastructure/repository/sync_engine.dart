import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/auth_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_session.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_downstream_helper.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';

bool _isTestEnvironment() {
  if (const bool.fromEnvironment('FLUTTER_TEST')) return true;
  if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return true;
  try {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  } catch (_) {
    return true;
  }
}

class SyncEngine {
  final Ref _ref;
  Timer? _syncTimer;
  Timer? _debounceSyncTimer;
  QuerySnapshot<Map<String, dynamic>>? _pendingMatchesSnapshot;
  bool _isProcessing = false;
  int _retryCount = 0;
  DateTime? _nextAttemptAt;

  // ダウンストリーム監視用のサブスクリプション
  StreamSubscription? _matchesSubscription;
  StreamSubscription? _bunaiksenSubscription;

  SyncEngine(this._ref) {
    // 🌟 Firestoreダウンストリーム監視の初期設定
    _setupFirestoreDownstream();
  }

  void _startSyncLoop() {
    if (_syncTimer != null && _syncTimer!.isActive) return;
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await processQueue();
    });
  }

  void _stopSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _setupFirestoreDownstream() {
    // DojoId または TournamentId が変わったときに再バインドする
    _ref.listen<String>(
      currentDojoIdProvider,
      (prev, next) => _bindListeners(),
    );
    _ref.listen<String>(
      currentTournamentIdProvider,
      (prev, next) => _bindListeners(),
    );
    _ref.listen<String?>(
      webCurrentTournamentIdProvider,
      (prev, next) => _bindListeners(),
    );
    // 🔑 認証セッション状態が変化した（ログイン成功など）際にも再バインドして再接続する
    _ref.listen<UserSession?>(authSessionProvider, (prev, next) {
      debugPrint(
        '🔑 [Sync Engine] 認証セッション状態の変更を検知しました: ${prev?.role} -> ${next?.role}',
      );
      _bindListeners();
    });
    // 🔑 Firebase認証状態が確立した際にも自動再バインド
    if (!_isTestEnvironment()) {
      _ref.listen(authStateProvider, (prev, next) {
        debugPrint('🔑 [Sync Engine] Firebase認証状態の変化を検知しました');
        _bindListeners();
      });
    }

    // 初回バインド
    _bindListeners();
  }

  void _bindListeners() {
    _matchesSubscription?.cancel();
    _bunaiksenSubscription?.cancel();
    _debounceSyncTimer?.cancel();
    _matchesSubscription = null;
    _bunaiksenSubscription = null;
    _pendingMatchesSnapshot = null;
    _nextAttemptAt = null;
    _retryCount = 0;

    final dojoId = _ref.read(currentDojoIdProvider);
    final tournamentId = _ref.read(currentTournamentIdProvider);
    final webTournamentId = _ref.read(webCurrentTournamentIdProvider);

    final activeTournamentId = (tournamentId.isNotEmpty)
        ? tournamentId
        : (webTournamentId ?? '');

    if (dojoId.isEmpty || activeTournamentId.isEmpty) {
      debugPrint(
        '📢 [Sync Engine] dojoId または tournamentId が未確定のため、Firestore監視を保留します。',
      );
      return;
    }

    // 🛡️ テスト環境以外かつFirebase初期化済みの場合、未認証時のFirestoreストリーム接続を抑止
    if (!_isTestEnvironment()) {
      try {
        if (Firebase.apps.isNotEmpty &&
            FirebaseAuth.instance.currentUser == null) {
          debugPrint('⏳ [Sync Engine] Firebase認証が未確立のため、Firestore監視を保留します。');
          return;
        }
      } catch (_) {}
    }

    debugPrint(
      '🚀 [Sync Engine] Firestoreダウンストリーム監視を開始します (dojoId: $dojoId, tournamentId: $activeTournamentId)',
    );

    // 1. 通常のトーナメント戦の試合データ監視（16msバッチド・デバウンスでUIリビルドをフレーム同期）
    final matchesCollection = _ref
        .read(firestoreProvider)
        .collection('organizations')
        .doc(dojoId)
        .collection('tournaments')
        .doc(activeTournamentId)
        .collection('matches');

    _matchesSubscription = matchesCollection.snapshots().listen(
      (snapshot) {
        _pendingMatchesSnapshot = snapshot;
        _debounceSyncTimer?.cancel();
        // ★ 最適化 (Web/Native共通): 連続するFirestoreイベントを50ms以内でバッチ集約
        // - Native: 50ms(約3フレーム)で複数コートの更新をまとめてIsarへ1回書き込み
        // - Web: IsarはnullのためsaveMatchesBulkは空処理（LocalMatchRepositoryのnullガード済み）
        //   Firestore→matchListProviderへの通知は別経路なので、Webでも正しく動作する
        _debounceSyncTimer = Timer(const Duration(milliseconds: 50), () async {
          final pending = _pendingMatchesSnapshot;
          if (pending != null) {
            _pendingMatchesSnapshot = null;
            await SyncDownstreamHelper.syncFirestoreToIsar(
              snapshot: pending,
              localRepo: _ref.read(localMatchRepositoryProvider),
              tournamentId: _ref.read(currentTournamentIdProvider),
            );
          }
        });
      },
      onError: (e) {
        debugPrint('⚠️ [Sync Engine Downstream] トーナメント試合監視エラー: $e');
      },
    );

    // 2. 特設コレクション (bunaiksen) の包括サブリスナー（ドキュメント監視）
    if (activeTournamentId.startsWith('bunaiksen_') ||
        activeTournamentId == 'bunaiksen') {
      final bunaiksenDoc = _ref
          .read(firestoreProvider)
          .collection('organizations')
          .doc(dojoId)
          .collection('tournaments')
          .doc(activeTournamentId);

      _bunaiksenSubscription = bunaiksenDoc.snapshots().listen(
        (snapshot) async {
          if (snapshot.exists && snapshot.data() != null) {
            debugPrint(
              '⚡ [Sync Engine Downstream] 特設部内大会ドキュメントの更新を受信しました: ${snapshot.id}',
            );
            await SyncDownstreamHelper.syncBunaiksenDocToIsar(
              snapshot: snapshot,
              localRepo: _ref.read(localMatchRepositoryProvider),
              tournamentId: _ref.read(currentTournamentIdProvider),
            );
          }
        },
        onError: (e) {
          debugPrint(
            '⚠️ [Sync Engine Downstream] 特設(bunaiksen)ドキュメント監視エラー: $e',
          );
        },
      );
    }
  }

  // =========================================================================
  // 🛡️ Phase 1 - STEP 1-2 要件：指数バックオフ・重複防止付き再送エンジン
  // =========================================================================
  /// 指数バックオフをリセットし、即座にキューの再送信を試行します（電波復帰時や手動同期時）
  void resetBackoffAndProcess() {
    _nextAttemptAt = null;
    _retryCount = 0;
    processQueue();
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;

    // ⚡ バックオフ期間中の場合はスレッドをロックせず即時リターン（非同期バックオフ）
    if (_nextAttemptAt != null && DateTime.now().isBefore(_nextAttemptAt!)) {
      return;
    }

    _isProcessing = true;

    try {
      final localRepo = _ref.read(localMatchRepositoryProvider);
      // Pending 状態の未送信SyncAction（MatchCommandModel）をIsarから全取得
      final pendingActions = await localRepo.getPendingCommands();

      if (pendingActions.isEmpty) {
        _retryCount = 0; // キューが空ならリトライカウントをリセット
        _nextAttemptAt = null;
        _isProcessing = false;
        _stopSyncLoop(); // 🔋 アイドル時は10秒タイマーを停止してCPUをディープスリープへ
        return;
      }

      // 未送信データが存在する場合はタイマーループが確実に回っていることを保証
      _startSyncLoop();

      debugPrint('🔄 [Sync Engine] 未送信キューを検知しました: ${pendingActions.length} 件');

      for (final action in pendingActions) {
        // 重複送信防止（eventId / commandId の完全一致検証によるFirestoreべき等性担保）
        bool success = await _attemptUpload(action);

        if (success) {
          // 送信成功時：Isar上の保留キューから物理削除
          await localRepo.deleteCommand(action.id);
          _retryCount = 0;
          _nextAttemptAt = null;
        } else {
          // 劣悪ネットワーク環境下での指数バックオフ制御（最大5分まで段階的に遅延を算出）
          _retryCount++;
          if (_retryCount >= 10) {
            // 🛡️ 【Poison Pill防御】リトライ上限（10回）を超過した異常コマンドは自律パージし、後続キューの永久ブロックを防止
            debugPrint(
              '🛡️ [Sync Engine] コマンド ${action.id} のリトライが上限（10回）を超過しました。毒薬キュー化防止のため自律パージします。',
            );
            await localRepo.deleteCommand(action.id);
            _retryCount = 0;
            _nextAttemptAt = null;
            continue;
          }
          final backoffSeconds = min(pow(2, _retryCount).toInt(), 300);
          _nextAttemptAt = DateTime.now().add(
            Duration(seconds: backoffSeconds),
          );
          debugPrint(
            '⚠️ [Sync Engine] 通信断の可能性。非同期バックオフを設定しました。次回試行時刻: $_nextAttemptAt (+$backoffSeconds秒)',
          );
          // ⚡ 重要: スレッドをブロックせず即座にループを脱出（UIや他処理をフリーズさせない）
          break;
        }
      }

      // 処理完了後にキューが空になった場合はタイマーを停止
      final remaining = await localRepo.getPendingCommands();
      if (remaining.isEmpty) {
        _stopSyncLoop();
      }
    } catch (e) {
      debugPrint('🔥 [Sync Engine Critical] キュー処理中に例外が発生しました: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _attemptUpload(SyncAction action) async {
    try {
      final remoteRepo = _ref.read(matchRepositoryProvider);

      // ペイロード（Map形式）からドメインモデルへ完全復元
      // (※既存リポジトリが要求する型に合わせて安全にアップロードを試みます)
      if (action.payload.containsKey('id')) {
        final MatchModel match;
        try {
          match = MatchModel.fromJson(action.payload);
        } catch (e) {
          debugPrint(
            '🛡️ [Sync Engine] ペイロードの復元に失敗しました（破損データ）。毒薬キュー化防止のため自律パージします: $e',
          );
          return true;
        }
        try {
          await remoteRepo.saveMatch(match);
          return true;
        } catch (e) {
          if (e.toString().contains('ConflictException')) {
            // クラウド上のドキュメントが既に存在し、remoteVersion >= localActionVersion であれば
            // 「クラウドは既に更新済みであり、本コマンドは陳腐化（Stale）している」と判定。
            // 安全に true（消化完了）を返し、Isarキューから削除（Self-Pruning）してバックオフ地獄（Poison Pill）を回避。
            debugPrint(
              '🛡️ [Sync Engine] ConflictException検知: クラウドのバージョンを確認します (matchId: ${match.id})',
            );
            final remoteMatch = await remoteRepo.getMatch(
              match.id,
              organizationId: match.organizationId,
              tournamentId: match.tournamentId,
            );
            if (remoteMatch != null && remoteMatch.version >= match.version) {
              debugPrint(
                '🛡️ [Sync Engine] クラウド側が既に新しいため (remote: ${remoteMatch.version} >= local: ${match.version})、Staleコマンドを自律パージします。',
              );
              return true;
            }
          }
          return false;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _debounceSyncTimer?.cancel();
    _syncTimer?.cancel();
    _matchesSubscription?.cancel();
    _bunaiksenSubscription?.cancel();
  }
}

// アプリ起動時に即座に常駐起動するための自動同期プロバイダー
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(ref);
  ref.onDispose(() => engine.dispose());
  return engine;
});
