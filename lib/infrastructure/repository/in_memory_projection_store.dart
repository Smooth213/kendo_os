import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/domain/repositories/projection_store.dart';

final projectionStoreProvider = Provider<ProjectionStore>((ref) {
  return InMemoryProjectionStore(); 
});

/// B-2: ProjectionStoreのローカル実装（Isar移行前のインメモリ版）
class InMemoryProjectionStore implements ProjectionStore {
  final _store = <String, MatchProjection>{};
  final _singleControllers = <String, StreamController<MatchProjection>>{};
  final _listController = StreamController<List<MatchProjection>>.broadcast();

  @override
  Future<void> save(MatchProjection projection) async {
    _store[projection.id] = projection;
    
    _singleControllers.putIfAbsent(projection.id, () => StreamController<MatchProjection>.broadcast())
        .add(projection);
    
    _listController.add(_store.values.toList());
  }

  @override
  Future<MatchProjection?> get(String matchId) async {
    return _store[matchId];
  }

  @override
  Stream<MatchProjection> watch(String matchId) async* {
    // ★ 修正: 購読された瞬間に現在の状態(または空)を必ずyieldする。これでローディング無限ループを防ぐ。
    if (_store.containsKey(matchId)) {
      yield _store[matchId]!;
    }
    final controller = _singleControllers.putIfAbsent(matchId, () => StreamController<MatchProjection>.broadcast());
    await for (final projection in controller.stream) {
      yield projection;
    }
  }

  @override
  Stream<List<MatchProjection>> watchByTournament(String tournamentId) async* {
    // ★ 修正: async*を使って最初に現在のリストを必ずyieldする。これでテストのタイムアウトを防ぐ。
    yield _store.values.where((p) => p.tournamentId == tournamentId).toList();
    await for (final list in _listController.stream) {
      yield list.where((p) => p.tournamentId == tournamentId).toList();
    }
  }
}