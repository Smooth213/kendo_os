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

      // 2. Firestoreのバッチ処理で一括送信（途中で失敗してもデータが壊れないようにする）
      final batch = firestore.batch();
      for (final match in pendingMatches) {
        final docRef = firestore.collection('matches').doc(match.id);
        // クラウド上では「最新の同期済みデータ」となるため、isDirtyをfalseにして送信
        final uploadData = match.copyWith(isDirty: false).toJson();
        batch.set(docRef, uploadData);
      }
      await batch.commit();

      // 3. 送信が完了したら、ローカルDBのフラグを下ろす（キューから削除）
      for (final match in pendingMatches) {
        await localRepo.markAsSynced(match.id);
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