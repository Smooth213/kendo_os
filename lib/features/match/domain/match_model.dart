import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ★ 追加: Timestamp型を明示的に使用するため
import 'package:kendo_os/shared/infrastructure/persistence/converters/json_converters.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'match_aggregate.dart'; // ★ 新しい構造のインポート
import 'match_meta.dart'; // ★ 新しい構造のインポート
import 'match_state.dart'; // ★ 追加: 真のFSM定義を読み込む
import 'package:flutter/foundation.dart'; // ★ 追加: debugPrint用
import 'package:kendo_os/shared/domain/entities/timeline_item.dart'; // ★ 追加: タイムライン統合インターフェース

part 'match_model.freezed.dart';
part 'match_model.g.dart';

// ★ 修正: json_converters.dart 内の TimestampConverter が null を DateTime.now() に
// 誤変換してしまうバグを完全に遮断するための安全なラッパーコンバーターです。
class SafeTimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const SafeTimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null; // 確実に null として扱う
    // 過去データや様々な型からの復元を安全に吸収する防波堤
    try {
      if (json is Timestamp) return json.toDate();
      if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
      if (json is String) return DateTime.tryParse(json) ?? DateTime.now();
      return const TimestampConverter().fromJson(json);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  dynamic toJson(DateTime? object) {
    if (object == null) return null;
    // ★ 修正: Web(JS interop)環境での converted Future クラッシュを【完全に】根絶するため、
    // Dart側で Timestamp インスタンスを生成して渡すのをやめ、
    // JS 側が 100% 安全に解釈できる絶対的なプリミティブ型（ミリ秒 int）として渡します。
    return object.millisecondsSinceEpoch;
  }
}

// ★ 追加: Web環境における配列のシリアライズ漏れを「物理的」に防ぐ絶対防壁コンバーター
// build.yaml のキャッシュなどで explicit_to_json が効かなかった場合でも、
// 確実に ScoreEvent を Map に変換してから Firestore の JS レイヤーに渡します。
class ScoreEventListConverter
    implements JsonConverter<List<ScoreEvent>, List<dynamic>> {
  const ScoreEventListConverter();

  @override
  List<ScoreEvent> fromJson(List<dynamic> json) =>
      json.map((e) => ScoreEvent.fromJson(e as Map<String, dynamic>)).toList();

  @override
  List<dynamic> toJson(List<ScoreEvent> object) =>
      object.map((e) => e.toJson()).toList();
}

// ★ 追加: スナップショット履歴も確実に純粋なMapに変換
class MatchSnapshotListConverter
    implements JsonConverter<List<MatchSnapshot>, List<dynamic>> {
  const MatchSnapshotListConverter();

  @override
  List<MatchSnapshot> fromJson(List<dynamic> json) => json
      .map((e) => MatchSnapshot.fromJson(e as Map<String, dynamic>))
      .toList();

  @override
  List<dynamic> toJson(List<MatchSnapshot> object) =>
      object.map((e) => e.toJson()).toList();
}

// ★ 追加: 複雑なルールオブジェクトも確実に純粋なMapに変換
class MatchRuleConverter
    implements JsonConverter<MatchRule?, Map<String, dynamic>?> {
  const MatchRuleConverter();
  @override
  MatchRule? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : MatchRule.fromJson(json);
  @override
  Map<String, dynamic>? toJson(MatchRule? object) => object?.toJson();
}

// ★ Phase 4-2: 同期ステータスの厳密化 (partディレクティブの下に配置)
enum SyncState { localOnly, syncing, synced, conflict }

@freezed
abstract class MatchModel with _$MatchModel implements TimelineItem {
  const MatchModel._();

  // ★ リカバリー: 既存のコードが壊れないように、コンストラクタは一旦元の状態を維持します。
  @Assert('redScore >= 0', 'Red score cannot be negative')
  @Assert('whiteScore >= 0', 'White score cannot be negative')
  @Assert(
    'accumulatedPauseDurationMs >= 0',
    'Accumulated pause duration cannot be negative',
  )
  const factory MatchModel({
    required String id,

    /// ★ 新・同期空間統治キー：この試合データがどの道場/所属の空間に帰属するかを固定
    @Default('default_org') String organizationId,
    required String matchType,
    required String redName,
    required String whiteName,
    @Default(0) int redScore,
    @Default(0) int whiteScore,
    @Default('waiting') String status,
    @ScoreEventListConverter() @Default([]) List<ScoreEvent> events,
    @MatchSnapshotListConverter() @Default([]) List<MatchSnapshot> snapshots,

    // ★ Phase 4: isDirtyを廃止し、厳密なSyncStateと差分キュー(pendingEvents)を導入
    @Default(SyncState.synced) SyncState syncState,
    @ScoreEventListConverter() @Default([]) List<ScoreEvent> pendingEvents,

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
    @Default('honsen')
    String matchScene, // 'renseikai', 'honsen', 'moushiawase'

    @Default(3.0) double matchTimeMinutes,
    @Default(false) bool isRunningTime,
    @Default(false) bool hasExtension,
    double? extensionTimeMinutes,
    int? extensionCount,
    @Default(false) bool hasHantei,
    // ★ Phase 2: Absolute Time化により、remainingSeconds と timerIsRunning はプロパティから削除
    @SafeTimestampConverter() DateTime? timerStartedAt,
    @SafeTimestampConverter() DateTime? timerPausedAt,
    @Default(0) int accumulatedPauseDurationMs,
    @Default('') String note,
    @Default(false) bool isKachinuki,
    @MatchRuleConverter() MatchRule? rule,
    @Default([]) List<String> redRemaining,
    @Default([]) List<String> whiteRemaining,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);

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

  // ==========================================
  // ★ Phase 1: タイムラインインターフェースの実装
  // ==========================================
  @override
  String get timelineId => id;

  @override
  double get timelineOrder => order;

  @override
  TimelineItemType get itemType => TimelineItemType.match;

  @override
  String get rebuildHash => '$id|$status|$redScore|$whiteScore|$order';

  // ★ Phase 1 移行用: String status から enum への安全な橋渡し
  MatchLifecycleState get lifecycle {
    switch (status) {
      case 'in_progress':
        return MatchLifecycleState.inProgress;
      case 'finished':
        return MatchLifecycleState.completed;
      case 'approved':
        return MatchLifecycleState.completed; // approvedも完了状態として扱う
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
      case MatchLifecycleState.corrupted:
        nextStatus = 'corrupted';
        break;
    }
    return copyWith(status: nextStatus);
  }

  // ★ Phase 4 移行用: 既存の isDirty 参照エラーを防ぐ Strangler Fig パターンの魔法
  bool get isDirty => syncState != SyncState.synced;

  // ★ Phase 2: Absolute Time 化によるStrangler Figパターン（参照エラー回避用の魔法）
  bool get timerIsRunning => timerStartedAt != null;

  // ★ CQRS/EventSourcing の不変性を保つため、外部から DateTime now を注入する形に変更
  // これにより、過去の任意時点でのリプレイ再生においてタイマー秒数が狂う Replay Drift を防止します。
  int calculateRemainingSeconds(DateTime now) {
    // ★ 修正: Unsupported operation: Infinity or NaN toInt を完全に根絶する防壁
    if (matchTimeMinutes.isInfinite || matchTimeMinutes.isNaN) {
      return 0; // 異常値時は安全に0秒（タイムアップ状態）として扱い、システムクラッシュを防止
    }

    final baseSeconds = (matchTimeMinutes * 60).toInt();
    int elapsedMs = accumulatedPauseDurationMs;
    if (timerStartedAt != null) {
      elapsedMs += now.difference(timerStartedAt!).inMilliseconds;
    }

    bool isUnlimited =
        (matchType == '代表戦' && baseSeconds == 0) ||
        (matchType == '延長戦' && baseSeconds == 0);
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
  MatchModel updateRemainingSeconds(
    int newSeconds,
    DateTime now, {
    bool isTimerStopping = false,
  }) {
    // ★ 修正: こちらも同様に異常値を検知した場合はシステムクラッシュを防止して安全に処理を抜ける
    if (matchTimeMinutes.isInfinite || matchTimeMinutes.isNaN) {
      return this;
    }

    final baseSeconds = (matchTimeMinutes * 60).toInt();
    bool isUnlimited =
        (matchType == '代表戦' && baseSeconds == 0) ||
        (matchType == '延長戦' && baseSeconds == 0);
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
      debugPrint(
        '🕒 [MatchModel] updateRemainingSeconds (isTimerStopping=true) => accMs: $accMs, new timerStartedAt: ${updated.timerStartedAt}',
      );
      return updated;
    }

    return copyWith(
      accumulatedPauseDurationMs: accMs,
      timerStartedAt: timerIsRunning ? now : null,
    );
  }

  /// 【Phase 2: 現場救済】選手名は維持したまま、取得部位・スコア・打突/反則イベントの陣営のみを左右入れ替え
  MatchModel swapRedAndWhite() {
    List<ScoreEvent> swapEventList(List<ScoreEvent> src) {
      return src.map((e) {
        if (e.side == Side.red) {
          return e.copyWith(side: Side.white);
        } else if (e.side == Side.white) {
          return e.copyWith(side: Side.red);
        }
        return e;
      }).toList();
    }

    return copyWith(
      redScore: whiteScore,
      whiteScore: redScore,
      events: swapEventList(events),
      pendingEvents: swapEventList(pendingEvents),
    );
  }
}
