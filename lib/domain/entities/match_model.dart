import 'package:freezed_annotation/freezed_annotation.dart';
import '../../infrastructure/persistence/converters/json_converters.dart'; 
import 'score_event.dart';
import '../rules/match_rule.dart';
import 'match_aggregate.dart'; // ★ 新しい構造のインポート
import 'match_meta.dart';      // ★ 新しい構造のインポート
import 'match_state.dart';     // ★ 追加: 真のFSM定義を読み込む
import 'package:flutter/foundation.dart'; // ★ 追加: debugPrint用

part 'match_model.freezed.dart';
part 'match_model.g.dart';

// ★ 修正: json_converters.dart 内の TimestampConverter が null を DateTime.now() に
// 誤変換してしまうバグを完全に遮断するための安全なラッパーコンバーターです。
class SafeTimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const SafeTimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null; // 確実に null として扱う
    return const TimestampConverter().fromJson(json);
  }

  @override
  dynamic toJson(DateTime? object) {
    if (object == null) return null;
    return const TimestampConverter().toJson(object);
  }
}

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
    
    @SafeTimestampConverter() DateTime? lastUpdatedAt, 
    @Default([]) List<String> refereeNames,
    @Default(true) bool countForStandings,
    String? scorerId,
    @SafeTimestampConverter() DateTime? lockExpiresAt, 
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
    // ★ Phase 2: Absolute Time化により、remainingSeconds と timerIsRunning はプロパティから削除
    @SafeTimestampConverter() DateTime? timerStartedAt,
    @SafeTimestampConverter() DateTime? timerPausedAt,
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
    timerStartedAt: timerStartedAt,
    accumulatedPauseDurationMs: accumulatedPauseDurationMs,
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

  // ★ Phase 1 移行用: String status から enum への安全な橋渡し
  MatchLifecycleState get lifecycle {
    switch (status) {
      case 'in_progress': return MatchLifecycleState.inProgress;
      case 'finished': return MatchLifecycleState.completed;
      case 'approved': return MatchLifecycleState.completed; // approvedも完了状態として扱う
      case 'waiting':
      default:
        return MatchLifecycleState.ready;
    }
  }

  // ★ Phase 1: 状態遷移関数 (これ以外によるstatus変更を将来的に禁止していく)
  MatchModel transition(MatchLifecycleState nextState) {
    String nextStatus;
    switch (nextState) {
      case MatchLifecycleState.notStarted:
      case MatchLifecycleState.waitingForPlayers:
      case MatchLifecycleState.ready:
        nextStatus = 'waiting';
        break;
      case MatchLifecycleState.inProgress:
      case MatchLifecycleState.paused:
      case MatchLifecycleState.encho:
      case MatchLifecycleState.hanteiPending:
        nextStatus = 'in_progress';
        break;
      case MatchLifecycleState.completed:
      case MatchLifecycleState.canceled:
      case MatchLifecycleState.fusen:
        nextStatus = 'finished';
        break;
    }
    return copyWith(status: nextStatus);
  }

  // ★ Phase 4 移行用: 既存の isDirty 参照エラーを防ぐ Strangler Fig パターンの魔法
  bool get isDirty => syncState != SyncState.synced;

  // ★ Phase 2: Absolute Time 化によるStrangler Figパターン（参照エラー回避用の魔法）
  bool get timerIsRunning => timerStartedAt != null;

  int get remainingSeconds {
    final baseSeconds = matchTimeMinutes * 60;
    int elapsedMs = accumulatedPauseDurationMs;
    if (timerStartedAt != null) {
      elapsedMs += DateTime.now().difference(timerStartedAt!).inMilliseconds;
    }
    
    bool isUnlimited = matchType == '代表戦' || (matchType == '延長戦' && baseSeconds == 0);
    if (isUnlimited) {
      return baseSeconds + (elapsedMs / 1000).floor(); 
    }
    
    final remainingMs = (baseSeconds * 1000) - elapsedMs;
    return remainingMs > 0 ? (remainingMs / 1000).ceil() : 0;
  }

  // ★ 修正: タイマーを手動修正した際に、絶対時間を逆算して再設定するヘルパー
  // 重要: タイマーが停止状態でも timerIsRunning が true のままだと
  // 計算時に timerStartedAt から現在時刻までの差分を再度加算してしまう問題があります。
  // したがって、このメソッド呼び出し時点で既にタイマーが停止しているなら
  // timerStartedAt は null にすべき。
  MatchModel updateRemainingSeconds(int newSeconds, {bool isTimerStopping = false}) {
    final baseSeconds = matchTimeMinutes * 60;
    bool isUnlimited = matchType == '代表戦' || (matchType == '延長戦' && baseSeconds == 0);
    int newElapsedMs;
    if (isUnlimited) {
       newElapsedMs = (newSeconds - baseSeconds) * 1000;
    } else {
       newElapsedMs = (baseSeconds - newSeconds) * 1000;
    }
    
    int accMs = newElapsedMs > 0 ? newElapsedMs : 0;

    // ★ 修正: 停止時(isTimerStopping=true)に稼働中フラグ(timerStartedAt)を確実に下ろすため、
    // JSON経由の再生成をやめて素直に copyWith を使用します。
    // （TimestampConverterがnullを現在時刻に変換してしまう副作用を完全に回避します）
    if (isTimerStopping) {
      final updated = copyWith(
        accumulatedPauseDurationMs: accMs,
        timerStartedAt: null,
      );
      debugPrint('🕒 [MatchModel] updateRemainingSeconds (isTimerStopping=true) => accMs: $accMs, new timerStartedAt: ${updated.timerStartedAt}');
      return updated;
    }

    return copyWith(
      accumulatedPauseDurationMs: accMs,
      timerStartedAt: timerIsRunning ? DateTime.now() : null,
    );
  }
}