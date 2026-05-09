import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/domain/repositories/projection_store.dart';

final projectionStoreProvider = Provider<ProjectionStore>((ref) {
  return InMemoryProjectionStore(); 
});

/// B-2: ProjectionStoreのローカル実装（Isar移行前のインメモリ版）
/// ★ Phase 5-2: 用途別にキャッシュを分離し、メモリ効率と配信速度を向上
class InMemoryProjectionStore implements ProjectionStore {
  // 詳細データ用（重い）
  final _store = <String, MatchProjection>{};
  // リスト表示用（軽い）★ 追加
  final _listStore = <String, MatchListProjection>{};

  final _singleControllers = <String, StreamController<MatchProjection>>{};
  final _listController = StreamController<List<MatchListProjection>>.broadcast();

  @override
  Future<void> save(MatchProjection projection) async {
    _store[projection.id] = projection;
    
    _singleControllers.putIfAbsent(projection.id, () => StreamController<MatchProjection>.broadcast())
        .add(projection);
    
    // 保存時にリスト用の軽量版も自動生成してキャッシュ（メモリ節約の要）
    _listStore[projection.id] = MatchListProjection(
      id: projection.id,
      tournamentId: projection.tournamentId,
      matchOrder: projection.matchOrder,
      matchType: projection.matchType,
      status: projection.status,
      redName: projection.redName,
      whiteName: projection.whiteName,
      redScore: projection.redScore,
      whiteScore: projection.whiteScore,
      groupName: projection.groupName,
      isKachinuki: projection.isKachinuki,
      note: projection.note,
      firstPointSide: projection.firstPointSide,
      redPointMarks: projection.redPointMarks,
      whitePointMarks: projection.whitePointMarks,
    );
    
    _listController.add(_listStore.values.toList());
  }

  @override
  Future<MatchProjection?> get(String matchId) async {
    return _store[matchId];
  }

  @override
  Stream<MatchProjection> watch(String matchId) async* {
    if (_store.containsKey(matchId)) {
      yield _store[matchId]!;
    }
    final controller = _singleControllers.putIfAbsent(matchId, () => StreamController<MatchProjection>.broadcast());
    await for (final projection in controller.stream) {
      yield projection;
    }
  }

  // ★ リスト画面では MatchProjection ではなく MatchListProjection を流すように変更
  @override
  Stream<List<MatchListProjection>> watchByTournament(String tournamentId) async* {
    yield _listStore.values.where((p) => p.tournamentId == tournamentId).toList();
    await for (final list in _listController.stream) {
      yield list.where((p) => p.tournamentId == tournamentId).toList();
    }
  }
}