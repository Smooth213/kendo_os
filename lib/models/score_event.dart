import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_converters.dart';

part 'score_event.freezed.dart';
part 'score_event.g.dart';

// ★ Phase 4: 陣営を型として定義 (Value Object)
enum Side { red, white, none }

enum PointType { men, kote, doIdo, tsuki, hansoku, undo, fusen, hantei, restore } // ★ Phase 1: 復元イベント(restore)を追加

// ★ Phase 1: 画面表示用の日本語ラベルを定義
extension PointTypeExt on PointType {
  String get label {
    switch (this) {
      case PointType.men: return 'メン';
      case PointType.kote: return 'コテ';
      case PointType.doIdo: return 'ドウ';
      case PointType.tsuki: return 'ツキ';
      case PointType.hansoku: return '反則';
      case PointType.undo: return '取り消し';
      case PointType.fusen: return '不戦勝';
      case PointType.hantei: return '判定';
      case PointType.restore: return '復元';
    }
  }
}

@freezed
abstract class ScoreEvent with _$ScoreEvent {
  const factory ScoreEvent({
    @Default('') String id, 
    required Side side, 
    required PointType type,
    @TimestampConverter() required DateTime timestamp, 
    String? userId, 
    @Default(0) int sequence, 
    @Default(false) bool isCanceled, // ★ Phase 4: 非破壊Undoのための論理削除フラグ
  }) = _ScoreEvent;

  factory ScoreEvent.fromJson(Map<String, dynamic> json) =>
      _$ScoreEventFromJson(json);
}