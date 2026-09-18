import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';

export 'package:kendo_os/shared/infrastructure/repository/team_repository.dart'
    show registeredTeamsProvider;

/// 選手一覧取得プロバイダー
final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

/// 登録した「よく使う自チーム名」をマスタから取得するプロバイダー
final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
});
