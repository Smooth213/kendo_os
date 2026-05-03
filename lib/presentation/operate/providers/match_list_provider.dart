import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart'; 
import 'package:kendo_os/infrastructure/repository/match_repository.dart'; // ★ 追記：リモートリポジトリの参照
import 'package:flutter/foundation.dart';

// ★ Phase 3: Firestore自体を提供するProvider
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// ★ 読み込み元を localMatchRepositoryProvider (Isar) に変更！
// 🌟 修正: さらに、最適化されたFirestore通信（進行中のみ監視＋過去データは1回取得）を組み込み、
// 取得したリモートデータを自動的にIsarへ流し込む（ダウンリンク同期）仕組みを追加。
final matchStreamProvider = StreamProvider<List<MatchModel>>((ref) async* {
  final localRepo = ref.watch(localMatchRepositoryProvider);
  final remoteRepo = ref.watch(matchRepositoryProvider);

  // 1. 静的データ（待機中・終了済み）を1回だけ取得し、Isarに保存（キャッシュ化）
  remoteRepo.getStaticMatches().then((staticMatches) {
    if (staticMatches.isNotEmpty) {
      localRepo.saveMatchesBulk(staticMatches);
    }
  }).catchError((e) {
    debugPrint('静的データ取得エラー: $e');
  });

  // 2. 進行中の試合だけをリアルタイム監視し、更新があればIsarに保存（通信量の劇的削減）
  final sub = remoteRepo.watchInProgressMatches().listen((activeMatches) {
    if (activeMatches.isNotEmpty) {
      localRepo.saveMatchesBulk(activeMatches);
    }
  });
  ref.onDispose(() => sub.cancel());

  // 3. UIには常にローカル（Isar）のストリームを流し続ける（爆速描画の維持）
  yield* localRepo.watchMatches();
});

final matchListProvider = Provider<List<MatchModel>>((ref) {
  return ref.watch(matchStreamProvider).value ?? [];
});

// 競合発生時の専用例外
class ConflictException implements Exception {
  final String message;
  ConflictException([this.message = '他の端末でデータが更新されました。']);
  @override
  String toString() => message;
}