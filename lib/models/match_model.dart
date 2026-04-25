import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_converters.dart'; 
import 'score_event.dart';
import 'match_rule.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

// ★ 修正: 余計な @JsonSerializable を削除（Freezedが自動で完璧に処理します）
@freezed
abstract class MatchSnapshot with _$MatchSnapshot {
  const factory MatchSnapshot({
    required String id,
    @TimestampConverter() required DateTime createdAt,
    required String reason,
    @Default([]) List<ScoreEvent> events,
  }) = _MatchSnapshot;

  factory MatchSnapshot.fromJson(Map<String, dynamic> json) => _$MatchSnapshotFromJson(json);
}

// ★ 修正: 余計な @JsonSerializable を削除
@freezed
abstract class MatchModel with _$MatchModel {
  const MatchModel._(); 

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
    @Default(false) bool isDirty, 
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
    @Default('') String note,
    @Default(false) bool isKachinuki,
    
    // ★ ルールの保管箱
    MatchRule? rule, 
    
    // ★ エラーの元凶だった箇所の修正（必須の @Default を付与）
    @Default([]) List<String> redRemaining,
    @Default([]) List<String> whiteRemaining,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) => _$MatchModelFromJson(json);
}