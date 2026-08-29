import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/domain/match_aggregate.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

/// 試合スナップショット生成・履歴管理ヘルパー
class MatchSnapshotHelper {
  const MatchSnapshotHelper();

  /// 試合にスナップショットを追加（最大20件まで保持）
  MatchModel addSnapshotToMatch(MatchModel match, String reason) {
    final snapshot = MatchSnapshot(
      id: const Uuid().v4(),
      matchId: match.id,
      version: match.events.length,
      state: match.copyWith(snapshots: const []),
      createdAt: DateTime.now(),
      reason: reason,
      events: List.from(match.events),
    );
    final newSnapshots = [...match.snapshots, snapshot];
    if (newSnapshots.length > 20) {
      newSnapshots.removeRange(0, newSnapshots.length - 20);
    }
    return match.copyWith(snapshots: newSnapshots);
  }
}
