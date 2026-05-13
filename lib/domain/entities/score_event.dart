import 'package:freezed_annotation/freezed_annotation.dart';
import '../../infrastructure/persistence/converters/json_converters.dart';

part 'score_event.freezed.dart';
part 'score_event.g.dart';

enum Side { red, white, none }
enum StrikeType { men, kote, dou, tsuki, none }

// ★ 救済措置：UIやテストの改修が終わるまで「旧型」を延命させる
enum PointType { men, kote, doIdo, tsuki, hansoku, undo, fusen, hantei, restore }

// ★ Phase 1-Step 2: バージョン定数の定義
const int currentEventVersion = 2;

@freezed
abstract class ScoreEvent with _$ScoreEvent {
  const ScoreEvent._();

  const factory ScoreEvent({
    @Default('') String id, 
    
    // ★ 修正: JSONにschemaVersionが無い昔のデータは「1」として読み込み、
    // 新しくDart内で生成されるイベントは最新の「2(currentEventVersion)」にする魔法の記述
    @JsonKey(defaultValue: 1) @Default(currentEventVersion) int schemaVersion,
    
    required Side side, 
    
    // --- 新しいDDDの意味ベース構造 ---
    @Default(StrikeType.none) StrikeType strikeType,
    @Default(false) bool isIppon,
    @Default(false) bool isHansoku,
    @Default(false) bool isFusen,
    @Default(false) bool isHantei,
    @Default(false) bool isUndo,
    @Default(false) bool isRestore,

    @TimestampConverter() required DateTime timestamp, 
    String? userId, 
    @Default(0) int sequence, 
    @Default(false) bool isCanceled,

    // ==========================================
    // ★ Phase 3-2: Append-only Event Sourcing (相殺イベント用)
    // 過去のイベントを直接 isCanceled=true に書き換えるのをやめ、
    // 「この targetId のイベントを取り消す」という新しいイベントを追記する方式へ移行。
    // ==========================================
    @Default('') String targetId,

    // ==========================================
    // ★ Phase 10: Historical Replay 保証
    // このイベントが発火した「当時のルールバージョン」を固定記録する
    // これにより将来ルールが変わっても過去の試合は当時のルールで安全にリプレイ可能になる
    // ==========================================
    @Default(1) int ruleVersion,

    // ==========================================
    // ★ Phase 3-Step 1: 分散同期のためのメタデータを追加
    // ==========================================
    @Default('local_device') String deviceId, // どの端末から発火したか
    @Default(0) int logicalClock,             // ランポート論理時計（順序解決用）

    // ==========================================
    // ★ Phase 1-Step 3: ゼロトラスト（改ざん防止）のための署名
    // ==========================================
    @Default('') String signature,            // 発行者と内容を証明する暗号署名
  }) = _ScoreEvent;

  // ★ 修正: freezedが正しく自動生成できるように標準の1行アロー関数に戻す
  factory ScoreEvent.fromJson(Map<String, dynamic> json) =>
      _$ScoreEventFromJson(json);

  // --- 完全な後方互換性ブリッジ（旧コードからのアクセスを新構造へ変換） ---
  PointType get type {
    if (isUndo) return PointType.undo;
    if (isRestore) return PointType.restore;
    if (isHansoku) return PointType.hansoku;
    if (isFusen) return PointType.fusen;
    if (isHantei) return PointType.hantei;
    switch (strikeType) {
      case StrikeType.men: return PointType.men;
      case StrikeType.kote: return PointType.kote;
      case StrikeType.dou: return PointType.doIdo;
      case StrikeType.tsuki: return PointType.tsuki;
      default: return PointType.undo;
    }
  }

  bool get isMen => strikeType == StrikeType.men;
  bool get isKote => strikeType == StrikeType.kote;
  bool get isDou => strikeType == StrikeType.dou;
  bool get isTsuki => strikeType == StrikeType.tsuki;
}