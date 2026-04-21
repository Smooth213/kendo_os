import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../repositories/local_match_repository.dart';
import 'match_list_provider.dart'; 
import '../main.dart'; 

// ★ Phase 2: 自動バックアップ用のパッケージを追加
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// ★ Step 4-1: ネットワーク接続状態をリアルタイムで監視するProvider
final connectivityProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();
  
  final subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
    final isOnline = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.ethernet
    );
    controller.add(isOnline);
  });

  Connectivity().checkConnectivity().then((results) {
    final isOnline = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.ethernet
    );
    controller.add(isOnline);
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
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
    if (_isSyncing) return; // 既に同期中なら重複実行を防ぐ
    _isSyncing = true;
    
    // ★ Phase 8-1: UIに「同期中」状態を通知
    ref.read(isSyncingStateProvider.notifier).state = true;

    try {
      final localRepo = ref.read(localMatchRepositoryProvider);
      final firestore = ref.read(firestoreProvider);

      // 1. 同期キュー（未送信データ）を取得
      final pendingMatches = await localRepo.getPendingMatches();

      if (pendingMatches.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('🔄 [Sync Engine] ネットワーク復帰を検知。${pendingMatches.length}件のデータをFirestoreへ送信します...');

      // 2. 楽観的ロックによる競合チェックと一括送信
      final batch = firestore.batch();
      List<String> failedMatchIds = []; // 競合で弾かれた試合IDのリスト

      for (final match in pendingMatches) {
        final docRef = firestore.collection('matches').doc(match.id);
        
        // ★ 楽観的ロック：Firestore側の現在のバージョンを確認
        final snapshot = await docRef.get();
        if (snapshot.exists) {
          final remoteVersion = (snapshot.data()!['version'] as num?)?.toInt() ?? 1;
          
          // 自分が持っているバージョンが、クラウドより古ければ競合発生！
          if (match.version < remoteVersion) {
            debugPrint('⚠️ [Sync Engine] 競合検知！試合ID: ${match.id} (Local: ${match.version}, Remote: $remoteVersion)');
            failedMatchIds.add(match.id);
            continue; // この試合は送信せずスキップ
          }
        }

        // 競合がなければ、バージョンを+1して送信準備
        final uploadData = match.copyWith(
          isDirty: false,
          version: snapshot.exists ? (snapshot.data()!['version'] as num?)?.toInt() ?? 1 : match.version + 1, // ★ バージョン更新
        ).toJson();
        batch.set(docRef, uploadData);
      }
      
      // 競合しなかったものだけをFirestoreに一括送信
      await batch.commit();

      // 3. 送信が成功した試合だけ、ローカルDBのフラグを下ろす
      for (final match in pendingMatches) {
        if (!failedMatchIds.contains(match.id)) {
           await localRepo.markAsSynced(match.id);
        }
      }

      // ★ Step 5-2: UIへのフィードバック（通知）
      if (failedMatchIds.isNotEmpty) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('⚠️ 他の端末で更新されたデータがあります。最新の状態を確認してください。'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (pendingMatches.isNotEmpty) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('✅ オフライン中のデータをクラウドに同期しました'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      debugPrint('✅ [Sync Engine] 同期完了: すべてのデータがクラウドに保存されました。');
    } catch (e) {
      debugPrint('🔥 [Sync Engine] 同期エラー: $e');
    } finally {
      _isSyncing = false;
      // ★ Phase 8-1: 同期終了（またはスキップ）をUIに通知
      ref.read(isSyncingStateProvider.notifier).state = false;
    }
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