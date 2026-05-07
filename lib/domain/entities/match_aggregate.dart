import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/entities/match_model.dart';

part 'match_aggregate.freezed.dart';
part 'match_aggregate.g.dart';

// ==========================================
// ★ Phase 2-Step 1: Snapshotモデルの最適化
// 以前は「単なる履歴のリスト」だったものを、
// 「その時点の最新のバージョン」と「その時点の状態(State)」を記憶する形に進化させる
// ==========================================
@freezed
abstract class MatchSnapshot with _$MatchSnapshot {
  const factory MatchSnapshot({
    required String id,
    @Default('') String matchId, // ★ どの試合のスナップショットか
    @Default(0) int version,     // ★ このスナップショットは何番目のイベントまでを適用した結果か
    required MatchModel state,   // ★ この時点の計算済みの試合状態（重い計算をスキップするため）
    required DateTime createdAt,
    required String reason,
    
    // 下方互換のために残すが、今後はStateを使うので基本的には空になる
    @Default([]) List<ScoreEvent> events, 
  }) = _MatchSnapshot;

  factory MatchSnapshot.fromJson(Map<String, dynamic> json) =>
      _$MatchSnapshotFromJson(json);
}

// ==========================================
// CQRSの中核：EventStore由来の「真実の歴史」を保持する集約
// ==========================================
@freezed
abstract class MatchAggregate with _$MatchAggregate {
  const MatchAggregate._();

  const factory MatchAggregate({
    required String id,
    
    // イベントソーシング：すべての変更履歴
    @Default([]) List<ScoreEvent> events,
    
    // 楽観的ロック用：現在のイベント数（バージョン）
    @Default(0) int version,

    // 試合の基本情報や状態（投影元となるベースデータ）
    required String status,
    required int remainingSeconds,
    required bool timerIsRunning,
  }) = _MatchAggregate;

  factory MatchAggregate.fromJson(Map<String, dynamic> json) =>
      _$MatchAggregateFromJson(json);

  // ==========================================
  // ★ Phase 2-Step 3: 復元ロジック (Rehydrate)
  // Snapshot と残りの Events から、最新のAggregateを高速に復元する
  // ==========================================
  static MatchAggregate rehydrate(
    String matchId,
    MatchSnapshot? snapshot, 
    List<ScoreEvent> allEvents, 
    MatchModel baseModel // 初期状態のベースモデル
  ) {
    MatchModel currentState;
    int currentVersion;

    if (snapshot != null) {
      // 1. スナップショットがあれば、そこから状態とバージョンを復元（高速ワープ）
      currentState = snapshot.state;
      currentVersion = snapshot.version;
    } else {
      // 2. スナップショットがなければ、初期状態からスタート
      currentState = baseModel.copyWith(events: []);
      currentVersion = 0;
    }

    // 3. スナップショットのバージョン以降の「残りのイベント」だけを抽出
    final remainingEvents = allEvents.skip(currentVersion).toList();

    // 4. 残りのイベントを順次適用（リプレイ）して最新状態を構築
    // ※ ここではKendoRuleEngineを使って再計算を行うのが理想だが、
    // 現在のアーキテクチャでは ProjectionMapper 側で計算しているため、
    // Aggregateとしては単にイベントリストを結合するだけに留める。
    // ★ 完璧なCQRSを目指すなら、このAggregate内で状態(State)を完全に持たせるべきだが、
    // Phase 2の段階ではまず「イベントの結合」と「バージョンのカウント」を担保する。
    
    final updatedEvents = List<ScoreEvent>.from(currentState.events)..addAll(remainingEvents);

    return MatchAggregate(
      id: matchId,
      events: updatedEvents,
      version: allEvents.length, // 最新のバージョンは、全イベントの数
      status: currentState.status,
      remainingSeconds: currentState.remainingSeconds,
      timerIsRunning: currentState.timerIsRunning,
    );
  }
}