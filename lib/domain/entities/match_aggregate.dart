import 'package:freezed_annotation/freezed_annotation.dart';
import 'score_event.dart';
import '../rules/match_rule.dart';
import '../../infrastructure/persistence/converters/json_converters.dart';
import 'match_state.dart';

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

  // --- ドメインロジック（振る舞い） ---
  
  // 現在のイベント履歴から現在の状態（スコア等）を計算して導出する
  MatchState get state {
    int rScore = 0;
    int wScore = 0;
    
    // キャンセルされていない、かつUndo・Restoreでない有効なポイントだけをカウントする簡易導出
    // ※本格的な計算はKendoRuleEngineが行うが、Aggregate自身も基本状態を知っているべき
    for (var e in events) {
      if (e.isCanceled || e.isUndo || e.isRestore) continue;
      if (e.isIppon) {
        if (e.side == Side.red) rScore++;
        if (e.side == Side.white) wScore++;
      }
    }

    MatchStatus currentStatus;
    switch (status) {
      case 'waiting': currentStatus = MatchStatus.waiting; break;
      case 'in_progress': currentStatus = MatchStatus.inProgress; break;
      case 'finished': currentStatus = MatchStatus.finished; break;
      case 'approved': currentStatus = MatchStatus.approved; break;
      default: currentStatus = MatchStatus.inProgress;
    }

    return MatchState(
      leftScore: rScore,
      rightScore: wScore,
      status: currentStatus,
    );
  }

  // イベントを追加して新しい状態（Aggregate）を返す純粋関数
  MatchAggregate addEvent(ScoreEvent event) {
    return copyWith(
      events: [...events, event],
      status: 'in_progress', // イベントが追加されたら進行中とする
    );
  }
}