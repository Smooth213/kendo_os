import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../repositories/local_match_repository.dart';
import 'match_list_provider.dart'; 

// ★ Phase 2: 自動バックアップ用のパッケージを追加
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// ★ Step 4-1: ネットワーク接続状態をリアルタイムで監視するProvider
// ★ 修正: async* と yield を使った、取りこぼしのない最もシンプルで堅牢な監視ロジック
final connectivityProvider = StreamProvider<bool>((ref) async* {
  // 1. アプリ起動時の状態をチェックして即座に返す
  final initialResults = await Connectivity().checkConnectivity();
  yield initialResults.any((result) => 
    result == ConnectivityResult.mobile || 
    result == ConnectivityResult.wifi || 
    result == ConnectivityResult.ethernet
  );

  // 2. 以降は、スマホの通信状態が変わるたびに自動で新しい状態を流し続ける
  await for (final results in Connectivity().onConnectivityChanged) {
    yield results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.ethernet
    );
  }
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? false;
});

// ★ Phase 8-1: 「現在リアルタイムに同期処理が動いているか」をUIへ通知するプロバイダ
final isSyncingStateProvider = StateProvider<bool>((ref) => false);

// ★ Step 4-2: バックグラウンド同期エンジン
// オフラインからオンラインに復帰した瞬間を検知し、溜まったデータを一気に送信する心臓部
class SyncEngine {
  final Ref ref;
  bool _isSyncing = false;
  bool _needsSyncAgain = false; // ★ 追加：同期中に書き込みがあった場合の「おかわり」フラグ

  SyncEngine(this.ref) {
    // ネットワーク状態を監視し、オンラインになったら自動で同期を開始する
    ref.listen<bool>(isOnlineProvider, (previous, isOnline) {
      if (isOnline && (previous == false || previous == null)) {
        syncNow();
      }
    });

    // ★ Phase 2: 自動バックアップ（アプリがバックグラウンドに回った時に作動）
    final lifecycleListener = AppLifecycleListener(
      onStateChange: (AppLifecycleState state) {
        // ユーザーがアプリを閉じた、または別のアプリに切り替えた瞬間に実行
        if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
          _autoBackupToJson();
        }
      },
    );
    ref.onDispose(() => lifecycleListener.dispose());
  }

  // ★ Phase 2: 裏でひっそりとJSONを書き出すメソッド
  Future<void> _autoBackupToJson() async {
    try {
      final matches = ref.read(matchListProvider);
      if (matches.isEmpty) return;

      final jsonStr = jsonEncode(
        matches.map((m) => m.toJson()).toList(),
        toEncodable: (dynamic item) {
          if (item is DateTime) return item.toIso8601String();
          if (item.runtimeType.toString() == 'Timestamp') {
            try { return (item as dynamic).toDate().toIso8601String(); } catch (_) { return item.toString(); }
          }
          return item.toString();
        }
      );

      final dir = await getApplicationDocumentsDirectory();
      // ストレージを圧迫しないよう、1つのファイルを上書きし続ける
      final file = File('${dir.path}/kendo_autobackup.json');
      await file.writeAsString(jsonStr);
      debugPrint('💾 [Auto Backup] 自動バックアップ完了: ${file.path}');
    } catch (e) {
      debugPrint('🔥 [Auto Backup] 自動バックアップ失敗: $e');
    }
  }

  // ★ Phase 6: ユーザーの手動操作（引っ張って更新など）で強制的に同期を走らせるメソッド
  Future<void> forceSync() async {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      debugPrint('🚫 [Sync Engine] オフラインのため手動同期をスキップします');
      return;
    }
    debugPrint('🔄 [Sync Engine] 手動同期(forceSync)を開始します...');
    await syncNow();
  }

  Future<void> syncNow() async {
    if (_isSyncing) {
      _needsSyncAgain = true; // 今やってるから、終わったらもう一度やってね、とメモする
      return;
    }
    _isProcessing();

    try {
      final localRepo = ref.read(localMatchRepositoryProvider);
      final firestore = ref.read(firestoreProvider);

      // 1. 未送信データを取得
      final pendingMatches = await localRepo.getPendingMatches();
      if (pendingMatches.isEmpty) return;

      debugPrint('🔄 [Sync Engine] ${pendingMatches.length}件を同期開始...');

      // 2. 1件ずつ慎重に、かつ高速に同期
      for (final match in pendingMatches) {
        final docRef = firestore.collection('matches').doc(match.id);
        
        // サーバー側の最新状態を確認（楽観的ロック）
        final snapshot = await docRef.get();
        int targetVersion = match.version;

        if (snapshot.exists) {
          final remoteVersion = (snapshot.data()!['version'] as num?)?.toInt() ?? 1;
          // 競合チェック：自分の持っているデータが古ければスキップ（後のPhaseで解決UIを出す）
          if (match.version < remoteVersion) {
            debugPrint('⚠️ [Sync Engine] 競合検知 ID:${match.id}');
            continue; 
          }
          targetVersion = remoteVersion + 1; // サーバーの続きから
        } else {
          targetVersion = 1; // 新規
        }

        final uploadData = match.copyWith(isDirty: false, version: targetVersion).toJson();
        await docRef.set(uploadData);
        
        // ★ 重要：ローカル側も「同期済み」かつ「最新バージョン」に更新する
        await localRepo.markAsSynced(match.id);
      }
    } catch (e) {
      debugPrint('🔥 [Sync Engine] 同期失敗: $e');
    } finally {
      _isDone();
      
      // ★ 改善：同期中に新たなデータ入力があった場合、即座に「おかわり」同期を開始
      if (_needsSyncAgain) {
        _needsSyncAgain = false;
        syncNow();
      }
    }
  }

  void _isProcessing() {
    _isSyncing = true;
    ref.read(isSyncingStateProvider.notifier).state = true;
  }

  void _isDone() {
    _isSyncing = false;
    ref.read(isSyncingStateProvider.notifier).state = false;
  }

  // ★ Phase 8-1.5: 競合の強制解決（サーバーデータを優先し、未送信状態をクリア）
  Future<void> resolveConflictByKeepingServer() async {
    try {
      // ★ 追加：localRepo の定義を補完
      final localRepo = ref.read(localMatchRepositoryProvider);
      // syncNow() と同じ方法で未送信データを取得
      final pendingMatches = await localRepo.getPendingMatches();
      for (final match in pendingMatches) {
         // ローカルの未送信フラグ（isDirty）を下ろす
         await localRepo.markAsSynced(match.id);
      }
      debugPrint('✅ [Sync Engine] 競合状態をクリアしました（サーバー優先）');
    } catch (e) {
      debugPrint('🔥 [Sync Engine] 競合クリアエラー: $e');
    }
  }
}

// アプリ起動時から常に常駐させるためのProvider
final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(ref);
});

// ★ Phase 6: UIのステータスバーに表示するための「未送信データ件数」Provider
final pendingMatchesCountProvider = StreamProvider<int>((ref) {
  return ref.watch(localMatchRepositoryProvider).watchPendingMatchesCount();
});

// ============================================================================
// ★ Phase 4: 同期ステータス表示用のロジック
// ============================================================================

enum SyncStatus { synced, syncing, pending }

final syncStatusProvider = Provider<SyncStatus>((ref) {
  final isSyncing = ref.watch(isSyncingStateProvider);
  // ローカルDBに1つでも isDirty (未送信) があるか監視
  final hasDirty = ref.watch(matchListProvider).any((m) => m.isDirty);

  if (isSyncing) return SyncStatus.syncing;
  if (hasDirty) return SyncStatus.pending;
  return SyncStatus.synced;
});