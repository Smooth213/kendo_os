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
// 🛡️ Phase 4 - STEP 4-1 & 4-2 要件：全ProjectionのIsar最優先・起動時復元ストリーム
// ネットが繋がっていなくても、Safariが再読込されても、iPadがスリープ復帰しても、
// Firestoreの応答を1ミリ秒も待たずに、Isarから前回状態を即座に復元してUIを表示させます。
// =========================================================================
final matchStreamProvider = StreamProvider<List<MatchModel>>((ref) {
  final localRepository = ref.watch(localMatchRepositoryProvider);
  
  // 1. Isarの全ローカル試合（Projectionの実体）の変更を完全凝視（fireImmediately: true で瞬時に画面復元）
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