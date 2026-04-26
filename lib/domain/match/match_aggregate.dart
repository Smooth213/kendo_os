import 'package:freezed_annotation/freezed_annotation.dart';
import 'score_event.dart';
import 'match_rule.dart';
import '../../models/json_converters.dart';

part 'match_aggregate.freezed.dart';
part 'match_aggregate.g.dart';

// ==========================================
// ★ 責務の移動: Snapshotはドメイン（Aggregate）の履歴情報
// ==========================================
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

// ==========================================
// ★ ① Aggregate中心設計：純粋な「試合の本体」
// ==========================================
@freezed
abstract class MatchAggregate with _$MatchAggregate {
  const MatchAggregate._();

  const factory MatchAggregate({
    required String id,
    required MatchRule rule,
    @Default([]) List<ScoreEvent> events,
    @Default([]) List<MatchSnapshot> snapshots,
    
    // 試合の進行状態（永続化が必要なドメインの状態）
    @Default('waiting') String status,
    @Default(0) int redScore,
    @Default(0) int whiteScore,
    @Default(180) int remainingSeconds,
    @Default(false) bool timerIsRunning,
  }) = _MatchAggregate;

  factory MatchAggregate.fromJson(Map<String, dynamic> json) => _$MatchAggregateFromJson(json);
}