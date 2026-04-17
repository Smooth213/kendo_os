import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/local_match_repository.dart';
import 'match_list_provider.dart'; // firestoreProviderを参照するため

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
  }

  Future<void> syncNow() async {
    if (_isSyncing) return; // 既に同期中なら重複実行を防ぐ
    _isSyncing = true;

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

      debugPrint('✅ [Sync Engine] 同期完了: すべてのデータがクラウドに保存されました。');
    } catch (e) {
      debugPrint('🔥 [Sync Engine] 同期エラー: $e');
    } finally {
      _isSyncing = false;
    }
  }
}

// アプリ起動時から常に常駐させるためのProvider
final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(ref);
});