import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/application/projections/tournament_projection.dart';
import 'package:kendo_os/application/projections/tournament_projection_mapper.dart';
import 'package:kendo_os/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/infrastructure/repository/in_memory_projection_store.dart'; 
import 'package:kendo_os/domain/entities/tournament_model.dart'; // ★ 追加

// =========================================================================
// ★ B-4: 真のCQRS - Viewerは ProjectionStore のみを監視する
// =========================================================================

// 1. 試合のプロジェクション（1試合単位）のリアルタイム監視
final viewerMatchProjectionProvider = StreamProvider.family<MatchProjection?, String>((ref, matchId) {
  return ref.watch(projectionStoreProvider).watch(matchId);
});

// =========================================================================
// ★ Phase 5-3: Rebuild最適化 (Selectors)
// 画面全体ではなく、変更があった「部分」だけを Widget に通知するためのフィルタ
// =========================================================================

/// 試合の基本ステータス（進行中・終了など）だけを監視する
final viewerMatchStatusProvider = Provider.family<AsyncValue<String>, String>((ref, matchId) {
  return ref.watch(viewerMatchProjectionProvider(matchId).select(
    (async) => async.whenData((p) => p?.status ?? 'waiting')
  ));
});

/// モメンタム（勢い）だけを監視する（高頻度更新用）
final viewerMatchMomentumProvider = Provider.family<AsyncValue<double>, String>((ref, matchId) {
  return ref.watch(viewerMatchProjectionProvider(matchId).select(
    (async) => async.whenData((p) => p?.momentum ?? 0.0)
  ));
});

/// タイムラインだけを監視する
final viewerMatchTimelineProvider = Provider.family<AsyncValue<List<TimelineEvent>>, String>((ref, matchId) {
  return ref.watch(viewerMatchProjectionProvider(matchId).select(
    (async) => async.whenData((p) => p?.timeline ?? [])
  ));
});

// --- 大会全体を監視するための内部Provider ---
final _tournamentModelStreamProvider = StreamProvider.family<TournamentModel?, String>((ref, id) {
  return ref.watch(tournamentRepositoryProvider).getTournamentStream(id);
});

// ★ Phase 5: watchByTournament が返す MatchListProjection 型に合わせる
final _tournamentProjectionsStreamProvider = StreamProvider.family<List<MatchListProjection>, String>((ref, id) {
  return ref.watch(projectionStoreProvider).watchByTournament(id);
});

// 2. 大会全体のプロジェクション（リスト・一覧用）のリアルタイム監視
// ★ 修正: Riverpodの AsyncValue を使って2つのStreamを安全かつ完全にリアクティブに結合する
final viewerTournamentProjectionProvider = Provider.family<AsyncValue<TournamentProjection?>, String>((ref, tournamentId) {
  final tournamentAsync = ref.watch(_tournamentModelStreamProvider(tournamentId));
  final projectionsAsync = ref.watch(_tournamentProjectionsStreamProvider(tournamentId));

  // どちらかがロード中ならローディング状態を返す
  if (tournamentAsync.isLoading || projectionsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  // エラーハンドリング
  if (tournamentAsync.hasError) {
    return AsyncValue.error(tournamentAsync.error!, tournamentAsync.stackTrace!);
  }
  if (projectionsAsync.hasError) {
    return AsyncValue.error(projectionsAsync.error!, projectionsAsync.stackTrace!);
  }

  final tournament = tournamentAsync.value;
  final projections = projectionsAsync.value ?? [];

  if (tournament == null) return const AsyncValue.data(null);

  // 双方の最新データを使ってProjectionを生成
  final projection = TournamentProjectionMapper.fromProjections(tournament, projections);
  return AsyncValue.data(projection);
});
