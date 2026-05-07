import 'package:kendo_os/domain/entities/match_aggregate.dart';
import 'package:kendo_os/domain/repositories/snapshot_store.dart';

// ==========================================
// ★ Phase 2-Step 2: InMemory版 SnapshotStoreの実装
// ==========================================
class InMemorySnapshotStore implements SnapshotStore {
  // matchId をキーとして、最新のSnapshotのみを保持する（履歴は持たない）
  final _store = <String, MatchSnapshot>{};

  @override
  Future<void> save(MatchSnapshot snapshot) async {
    // 常に最新のSnapshotで上書きする（古いスナップショットは破棄して容量を節約）
    _store[snapshot.matchId] = snapshot;
  }

  @override
  Future<MatchSnapshot?> loadLatest(String matchId) async {
    return _store[matchId];
  }
}