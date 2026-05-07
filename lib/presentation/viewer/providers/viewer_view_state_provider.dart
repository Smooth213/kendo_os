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

// --- 大会全体を監視するための内部Provider ---
final _tournamentModelStreamProvider = StreamProvider.family<TournamentModel?, String>((ref, id) {
  return ref.watch(tournamentRepositoryProvider).getTournamentStream(id);
});

final _tournamentProjectionsStreamProvider = StreamProvider.family<List<MatchProjection>, String>((ref, id) {
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
