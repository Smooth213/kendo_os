import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/json_converters.dart';

part 'score_event.freezed.dart';
part 'score_event.g.dart';

// ★ Phase 4: 陣営を型として定義 (Value Object)
enum Side { red, white, none }

// ★ ④ Event意味の明確化：打突の種類を分離
enum StrikeType { men, kote, dou, tsuki, none }

// ★ 互換性のための既存の型定義（後で徐々に消していきます）
enum PointType { men, kote, doIdo, tsuki, hansoku, undo, fusen, hantei, restore }

@freezed
abstract class ScoreEvent with _$ScoreEvent {
  const ScoreEvent._();

  const factory ScoreEvent({
    @Default('') String id, 
    required Side side, 
    
    // ★ 新しい責務分割
    @Default(StrikeType.none) StrikeType strikeType,
    @Default(false) bool isIppon,
    @Default(false) bool isHansoku,
    @Default(false) bool isFusen,
    @Default(false) bool isHantei,

    // ★ 旧コードとの互換性維持のためのフィールド（既存のDBデータ読み込み用）
    required PointType type,

    @TimestampConverter() required DateTime timestamp, 
    String? userId, 
    @Default(0) int sequence, 
    @Default(false) bool isCanceled,
  }) = _ScoreEvent;

  factory ScoreEvent.fromJson(Map<String, dynamic> json) =>
      _$ScoreEventFromJson(json);

  // --------------------------------------------------
  // ★ 既存のロジックを壊さないためのブリッジ
  // --------------------------------------------------
  bool get isMen => strikeType == StrikeType.men || type == PointType.men;
  bool get isKote => strikeType == StrikeType.kote || type == PointType.kote;
  bool get isDou => strikeType == StrikeType.dou || type == PointType.doIdo;
  bool get isTsuki => strikeType == StrikeType.tsuki || type == PointType.tsuki;
}