import 'package:uuid/uuid.dart';
import '../../domain/entities/score_event.dart';

class ScoreEventLegacyAdapter {
  static ScoreEvent fromLegacy({
    required PointType type, 
    required Side side, 
    String? id, 
    DateTime? timestamp, 
    String? userId, 
    int sequence = 0, 
    bool isCanceled = false
  }) {
    final eventId = id ?? const Uuid().v4();
    final time = timestamp ?? DateTime.now();

    switch (type) {
      case PointType.men: return ScoreEvent(id: eventId, side: side, strikeType: StrikeType.men, isIppon: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled);
      case PointType.kote: return ScoreEvent(id: eventId, side: side, strikeType: StrikeType.kote, isIppon: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled);
      case PointType.doIdo: return ScoreEvent(id: eventId, side: side, strikeType: StrikeType.dou, isIppon: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled);
      case PointType.tsuki: return ScoreEvent(id: eventId, side: side, strikeType: StrikeType.tsuki, isIppon: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled);
      case PointType.hansoku: return ScoreEvent(id: eventId, side: side, isHansoku: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled);
      case PointType.fusen: return ScoreEvent(id: eventId, side: side, isFusen: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled);
      case PointType.hantei: return ScoreEvent(id: eventId, side: side, isHantei: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled);
      case PointType.undo: return ScoreEvent(id: eventId, side: side, isUndo: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled);
      case PointType.restore: return ScoreEvent(id: eventId, side: side, isRestore: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled);
    }
  }
}