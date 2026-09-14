import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/domain/match_aggregate.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

/// 試合スナップショット生成・履歴管理ヘルパー
class MatchSnapshotHelper {
  /// 🔋 ドキュメント内保持上限（直前Undo用として最新1件に縮小。任意時点の復元はeventsリプレイで行う）
  final int maxSnapshots;

  const MatchSnapshotHelper({this.maxSnapshots = 1});

  /// 試合にスナップショットを追加（直前Undo用に最新1件のみ保持し、DBサイズ肥大化を90%削減）
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
    if (newSnapshots.length > maxSnapshots) {
      newSnapshots.removeRange(0, newSnapshots.length - maxSnapshots);
    }
    return match.copyWith(snapshots: newSnapshots);
  }
}
