import 'package:isar_community/isar.dart';

part 'match_projection_entity.g.dart';

// =========================================================================
// 🛡️ Phase 0 - STEP 0-2 要件：Isar Projection Cache 構造体
// UI描画を高速化し、オフライン起動時にも一瞬で前回画面を復元するための専用不変Entity
// =========================================================================
@collection
class MatchProjectionEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String matchId;

  late String tournamentId;
  String? category;
  String? groupName;
  late int matchOrder;

  late String redName;
  late String whiteName;
  late int redScore;
  late int whiteScore;
  
  late String status; // 'waiting', 'in_progress', 'finished', 'approved'
  
  String? winnerName;
  late DateTime lastUpdatedAt;
  
  // 拡張表示用のメタデータ
  String? matchType;
  String? refereeNames;
  String? note;
}