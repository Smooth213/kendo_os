import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';

// =========================================================================
// 🛡️ 補正：プロジェクト全域でUndefinedエラーを吐いている firestoreProvider をここで安全に定義
// =========================================================================
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// =========================================================================
// 🛡️ Webアプリ表示不具合修正パッチ（ロードマップメソッド完全維持）
// Flutter Web環境（Isarが非活性）のときはストリームを沈黙させず、
// 即座に安全な空配列（またはFirestoreの読み込み側）をUIへ射出してフリーズを完全回避します。
// =========================================================================
final matchStreamProvider = StreamProvider<List<MatchModel>>((ref) {
  // Webブラウザ環境（kIsWeb == true）のとき、Isarディスク監視を安全にバイパス
  if (kIsWeb) {
    debugPrint('🌐 [Web Environment Detected] Isarの代わりにメモリ/クラウド監視ラインを確立します');
    // 必要に応じて、Firestore側のコレクションスナップショットを安全にバインドするか、
    // 起動時の白画面フリーズを防ぐために、即座にクリーンな初期状態を供給します。
    final firestore = ref.watch(firestoreProvider);
    return firestore
        .collection('matches')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // 🍏 ネイティブ環境（シミュレータ・iPad実機アプリ）はこれまでの強力なIsar最優先監視を100%継続
  final localRepository = ref.watch(localMatchRepositoryProvider);
  return localRepository.watchAllLocalMatches().map((matches) {
    if (matches.isEmpty) {
      debugPrint('⏳ [Startup Restore] Isar内にローカルキャッシュがありません。クラウド同期をバックグラウンドで待機します。');
    } else {
      debugPrint('⚡ [Startup Restore] Isarローカルディスクから ${matches.length} 件の試合状態を一瞬で完全復元しました（電波ゼロOK）');
    }
    return matches;
  });
});

// =========================================================================
// 🛡️ Phase 0 - STEP 0-1 要件：既存の全UI・ロジック・テストを完全無傷で救済するコア
// 呼び出し側には同期的で扱いやすい List<MatchModel> を返しつつ、
// その実態は Isar のリアルタイムストリーム（matchStreamProvider）を凝視する、完璧なブリッジ構造です。
// =========================================================================
final matchListProvider = Provider<List<MatchModel>>((ref) {
  return ref.watch(matchStreamProvider).value ?? const [];
});

// 💡 特定の大会IDで厳密に絞り込みたい画面のための family 版も別名で安全に維持
final matchListByTournamentProvider = StreamProvider.family<List<MatchModel>, String>((ref, tournamentId) {
  final localRepository = ref.watch(localMatchRepositoryProvider);
  return localRepository.watchLocalMatches(tournamentId);
});