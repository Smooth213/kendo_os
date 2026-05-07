import 'package:kendo_os/domain/entities/match_aggregate.dart';

// ==========================================
// ★ Phase 2-Step 2: SnapshotStoreの定義
// イベント履歴の再構築を高速化するための「セーブデータ」置き場
// ==========================================
abstract class SnapshotStore {
  /// スナップショットを保存する
  Future<void> save(MatchSnapshot snapshot);
  
  /// 指定した試合の「最新の」スナップショットを読み込む
  Future<MatchSnapshot?> loadLatest(String matchId);
}