import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tournament_model.dart';
import '../../repositories/tournament_repository.dart';

// ★ 画面側で「ref.watch(tournamentListProvider)」と書くだけで
// 最新の大会一覧が取得できるようになる魔法のプロバイダー！
final tournamentListProvider = StreamProvider<List<TournamentModel>>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.watchTournaments();
});