import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/match_model.dart'; // ★ SyncStateを使うため追加

part 'match_entity.g.dart';

// ★ Step 1-2: イベント履歴の保存用（ネストされたオブジェクト）
@embedded
class ScoreEventEntity {
  String? id;

  @enumerated
  Side side = Side.none;

  @enumerated
  PointType type = PointType.men;

  DateTime? timestamp;
  String? userId;
  int sequence = 0;
  bool isCanceled = false;

  // ★ Phase 10: Event/Replayer整合
  int ruleVersion = 1;

  // ★ Phase 4: EventSourcing & Sync 用のメタデータを永続化
  bool isUndo = false;
  bool isRestore = false;
  String deviceId = 'local_device';
  int logicalClock = 0;
  String signature = '';
}

// ★ Phase 1: 復元用のスナップショット（特定の時点のイベント履歴を丸ごと保存）
@embedded
class MatchSnapshotEntity {
  String? id;
  DateTime? createdAt;
  String? reason; // 例: "試合開始", "赤 メ 取得後"
  List<ScoreEventEntity> events = [];
}

// ★ Step 1-2: 試合データの保存用テーブル（Collection）
@collection
class MatchEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String firestoreId; // ここに元の大きなIDを保持

  late String matchType;
  late String redName;
  late String whiteName;
  int redScore = 0;
  int whiteScore = 0;
  String status = 'waiting';

  // 履歴（SSOTの要）
  List<ScoreEventEntity> events = [];

  // ★ Phase 1: 保存されたスナップショットの履歴
  List<MatchSnapshotEntity> snapshots = [];

  // ★ Phase 4: オフライン同期基盤 (isDirty廃止)
  @enumerated
  SyncState syncState = SyncState.synced;
  List<ScoreEventEntity> pendingEvents = []; // 送信待ちの差分キュー

  DateTime? lastUpdatedAt;

  List<String> refereeNames = [];
  bool countForStandings = true;
  String? scorerId;
  int version = 1;
  bool isAutoAssigned = false;
  double order = 0.0;
  String source = 'manual';

  String? tournamentId;
  String? category;
  String? groupName;
  int? matchOrder;

  double matchTimeMinutes = 3.0;
  bool isRunningTime = false;
  bool hasExtension = false;
  double? extensionTimeMinutes;
  int? extensionCount;
  bool hasHantei = false;

  DateTime? timerStartedAt;
  DateTime? timerPausedAt;
  int accumulatedPauseDurationMs = 0;
  String note = '';

  bool isKachinuki = false;
  String? ruleJson; // ★ 追加：圧縮したMatchRuleを保存しておくための新しい引き出し
  List<String> redRemaining = [];
  List<String> whiteRemaining = [];
}

// ★ Phase 2: コマンド永続化用テーブル
// アプリがクラッシュしても、キューに残っていた「未処理の操作」をここから復元します
@collection
class MatchCommandEntity {
  Id id = Isar.autoIncrement; // Isar内部管理用

  @Index(unique: true)
  late String commandId; // ここに元のIDを保持

  late String type; // CommandType.name
  late String payloadJson; // MapをJSON化
  late DateTime createdAt;
  late String status; // CommandStatus.name
}
