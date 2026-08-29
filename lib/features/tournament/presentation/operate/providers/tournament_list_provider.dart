import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';

// ★ 画面側で「ref.watch(tournamentListProvider)」と書くだけで
// 最新の大会一覧が取得できるようになる魔法のプロバイダー！
final tournamentListProvider = StreamProvider<List<TournamentModel>>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.watchTournaments();
});

// ★ 過去の大会一覧（アーカイブ）プロバイダー
// メモリ上にキャッシュし、画面遷移・再描画時に一瞬（0ms）で復元する
final archivedTournamentListProvider = FutureProvider<List<TournamentModel>>((
  ref,
) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getArchivedTournaments();
});
