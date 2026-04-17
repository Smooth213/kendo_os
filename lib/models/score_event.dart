import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_converters.dart';

part 'score_event.freezed.dart';
part 'score_event.g.dart';

// ★ Phase 4: 陣営を型として定義 (Value Object)
enum Side { red, white, none }

enum PointType { men, kote, doIdo, tsuki, hansoku, undo, fusen, hantei }

@freezed
abstract class ScoreEvent with _$ScoreEvent {
  const factory ScoreEvent({
    @Default('') String id, 
    required Side side, // ★ String から Side(Enum) へ変更
    required PointType type,
    @TimestampConverter() required DateTime timestamp, 
    String? userId, 
    @Default(0) int sequence, 
  }) = _ScoreEvent;

  factory ScoreEvent.fromJson(Map<String, dynamic> json) =>
      _$ScoreEventFromJson(json);
}