import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';

export 'package:kendo_os/shared/infrastructure/repository/team_repository.dart'
    show registeredTeamsProvider;

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});
