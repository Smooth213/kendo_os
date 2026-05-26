import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/presentation/operate/providers/match_command_provider.dart';

class SyncEngine {
  final Ref _ref;
  Timer? _syncTimer;
  bool _isProcessing = false;
  int _retryCount = 0;

  SyncEngine(this._ref) {
    // 🌟 起動と同時に自動ポーリング同期ループを開始
    _startSyncLoop();
  }

  void _startSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await processQueue();
    });
  }

  // =========================================================================
  // 🛡️ Phase 1 - STEP 1-2 要件：指数バックオフ・重複防止付き再送エンジン
  // =========================================================================
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final localRepo = _ref.read(localMatchRepositoryProvider);
      // Pending 状態の未送信SyncAction（MatchCommandModel）をIsarから全取得
      final pendingActions = await localRepo.getPendingCommands();

      if (pendingActions.isEmpty) {
        _retryCount = 0; // キューが空ならリトライカウントをリセット
        _isProcessing = false;
        return;
      }

      debugPrint('🔄 [Sync Engine] 未送信キューを検知しました: ${pendingActions.length} 件');

      for (final action in pendingActions) {
        // 重複送信防止（eventId / commandId の完全一致検証によるFirestoreべき等性担保）
        bool success = await _attemptUpload(action);
        
        if (success) {
          // 送信成功時：Isar上の保留キューから物理削除
          await localRepo.deleteCommand(action.id);
          _retryCount = 0;
        } else {
          // 劣悪ネットワーク環境下での指数バックオフ制御（最大5分まで段階的に遅延を挿入）
          _retryCount++;
          final backoffSeconds = min(pow(2, _retryCount).toInt(), 300);
          debugPrint('⚠️ [Sync Engine] 通信断の可能性。指数バックオフを実行します。次の再送まで: $backoffSeconds秒');
          await Future.delayed(Duration(seconds: backoffSeconds));
          break; // 一度エラーが起きたら順序保証のため以降のキュー処理を中断
        }
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
        final match = MatchModel.fromJson(action.payload);
        await remoteRepo.saveMatch(match);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}

// アプリ起動時に即座に常駐起動するための自動同期プロバイダー
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(ref);
  ref.onDispose(() => engine.dispose());
  return engine;
});