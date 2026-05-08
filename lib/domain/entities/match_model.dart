import 'package:freezed_annotation/freezed_annotation.dart';
import '../../infrastructure/persistence/converters/json_converters.dart'; 
import 'score_event.dart';
import '../rules/match_rule.dart';
import 'match_aggregate.dart'; // ★ 新しい構造のインポート
import 'match_meta.dart';      // ★ 新しい構造のインポート

part 'match_model.freezed.dart';
part 'match_model.g.dart';

// ★ Phase 4-2: 同期ステータスの厳密化 (partディレクティブの下に配置)
enum SyncState { localOnly, syncing, synced, conflict }

@freezed
abstract class MatchModel with _$MatchModel {
  const MatchModel._(); 

  // ★ リカバリー: 既存のコードが壊れないように、コンストラクタは一旦元の状態を維持します。
  const factory MatchModel({
    required String id,
    required String matchType,
    required String redName,
    required String whiteName,
    @Default(0) int redScore,
    @Default(0) int whiteScore,
    @Default('waiting') String status,
    @Default([]) List<ScoreEvent> events, 
    @Default([]) List<MatchSnapshot> snapshots, 
    
    // ★ Phase 4: isDirtyを廃止し、厳密なSyncStateと差分キュー(pendingEvents)を導入
    @Default(SyncState.synced) SyncState syncState,
    @Default([]) List<ScoreEvent> pendingEvents,
    
    @TimestampConverter() DateTime? lastUpdatedAt, 
    @Default([]) List<String> refereeNames,
    @Default(true) bool countForStandings,
    String? scorerId,
    @TimestampConverter() DateTime? lockExpiresAt, 
    @Default(1) int version,
    @Default(false) bool isAutoAssigned,
    @DoubleConverter() @Default(0.0) double order,
    @Default('manual') String source,
    String? tournamentId,
    String? category,
    String? groupName,
    int? matchOrder,
    
    @Default(3) int matchTimeMinutes,
    @Default(false) bool isRunningTime,
    @Default(false) bool hasExtension,
    int? extensionTimeMinutes,
    int? extensionCount,
    @Default(false) bool hasHantei,
    @Default(180) int remainingSeconds,
    @Default(false) bool timerIsRunning,
    // ★ Phase 3-1: Absolute Time (絶対時刻) 化のためのフィールド
    @TimestampConverter() DateTime? timerStartedAt,
    @TimestampConverter() DateTime? timerPausedAt,
    @Default(0) int accumulatedPauseDurationMs,
    @Default('') String note,
    @Default(false) bool isKachinuki,
    MatchRule? rule, 
    @Default([]) List<String> redRemaining,
    @Default([]) List<String> whiteRemaining,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) => _$MatchModelFromJson(json);

  // ==========================================
  // ★ 真の安全な移行（Strangler Figパターン）
  // 既存のプロパティを壊さず、ここから新しい Aggregate と Meta を「生成」して
  // UseCase などのロジック層へ渡せるようにします。
  // ==========================================
  
  MatchAggregate get toAggregate => MatchAggregate(
    id: id,
    events: events,
    status: status,
    remainingSeconds: remainingSeconds,
    timerIsRunning: timerIsRunning,
  );

  MatchMeta get toMeta => MatchMeta(
    matchType: matchType,
    redName: redName,
    whiteName: whiteName,
    note: note,
    tournamentId: tournamentId,
    category: category,
    groupName: groupName,
    matchOrder: matchOrder,
    refereeNames: refereeNames,
    countForStandings: countForStandings,
    isAutoAssigned: isAutoAssigned,
  );

  // ★ Phase 4 移行用: 既存の isDirty 参照エラーを防ぐ Strangler Fig パターンの魔法
  bool get isDirty => syncState != SyncState.synced;
}