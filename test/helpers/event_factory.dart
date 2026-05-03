import 'package:kendo_os/domain/entities/score_event.dart';

ScoreEvent men(Side side) => ScoreEvent(
  id: 'e-${DateTime.now().microsecondsSinceEpoch}',
  side: side,
  strikeType: StrikeType.men,
  isIppon: true,
  timestamp: DateTime.now(),
);

ScoreEvent hansoku(Side side) => ScoreEvent(
  id: 'e-${DateTime.now().microsecondsSinceEpoch}',
  side: side,
  strikeType: StrikeType.none,
  isHansoku: true,
  timestamp: DateTime.now(),
);

ScoreEvent cancel(Side side) => ScoreEvent(
  id: 'e-${DateTime.now().microsecondsSinceEpoch}',
  side: side,
  strikeType: StrikeType.none,
  isCanceled: true,
  timestamp: DateTime.now(),
);

ScoreEvent kote(Side side) => ScoreEvent(
  id: 'e-${DateTime.now().microsecondsSinceEpoch}',
  side: side,
  strikeType: StrikeType.kote,
  isIppon: true,
  timestamp: DateTime.now(),
);

ScoreEvent dou(Side side) => ScoreEvent(
  id: 'e-${DateTime.now().microsecondsSinceEpoch}',
  side: side,
  strikeType: StrikeType.dou,
  isIppon: true,
  timestamp: DateTime.now(),
);