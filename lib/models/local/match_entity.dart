
import 'package:isar_community/isar.dart'; // ★ パッケージ名は isar_community ですが、ファイル名は isar.dart です
import '../score_event.dart';

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
  bool isCanceled = false; // ★ Phase 4: 非破壊Undo用のフラグを追加
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
  // Isar が内部で使う高速検索用の自動採番ID
  Id id = Isar.autoIncrement;

  // Firestore で使っていた文字列の ID (検索キーにするため Index を貼る)
  @Index(unique: true, replace: true)
  late String firestoreId;

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

  // ★ オフライン同期用のフラグ
  bool isDirty = false;
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

  int matchTimeMinutes = 3;
  bool isRunningTime = false;
  bool hasExtension = false;
  int? extensionTimeMinutes;
  int? extensionCount;
  bool hasHantei = false;

  int remainingSeconds = 180;
  bool timerIsRunning = false;
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
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id; // UUID

  late String type; // CommandType.name
  late String payloadJson; // MapをJSON化
  late DateTime createdAt;
  late String status; // CommandStatus.name
}