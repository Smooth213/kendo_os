import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_converters.dart'; 
import '../domain/match/score_event.dart';
import '../domain/match/match_rule.dart';
import '../domain/match/match_aggregate.dart'; // ★ 新しい構造のインポート
import '../domain/match/match_meta.dart';      // ★ 新しい構造のインポート

part 'match_model.freezed.dart';
part 'match_model.g.dart';

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
    rule: rule ?? const MatchRule(), 
    events: events,
    snapshots: snapshots,
    status: status,
    redScore: redScore,
    whiteScore: whiteScore,
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
}