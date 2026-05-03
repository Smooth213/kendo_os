import 'package:freezed_annotation/freezed_annotation.dart';
import '../../infrastructure/persistence/converters/json_converters.dart';

part 'score_event.freezed.dart';
part 'score_event.g.dart';

enum Side { red, white, none }
enum StrikeType { men, kote, dou, tsuki, none }

// ★ 救済措置：UIやテストの改修が終わるまで「旧型」を延命させる
enum PointType { men, kote, doIdo, tsuki, hansoku, undo, fusen, hantei, restore }

@freezed
abstract class ScoreEvent with _$ScoreEvent {
  const ScoreEvent._();

  const factory ScoreEvent({
    @Default('') String id, 
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
  }) = _ScoreEvent;

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