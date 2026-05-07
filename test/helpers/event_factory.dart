import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';

// ★ 古いテスト用に、sequence を 0 (フリーパス) で生成する近代化工場
ScoreEvent men(Side side) => ScoreEventLegacyAdapter.fromLegacy(
  side: side, type: PointType.men, sequence: 0, userId: 'test_user'
);

ScoreEvent hansoku(Side side) => ScoreEventLegacyAdapter.fromLegacy(
  side: side, type: PointType.hansoku, sequence: 0, userId: 'test_user'
);

ScoreEvent cancel(Side side) => ScoreEventLegacyAdapter.fromLegacy(
  side: side, type: PointType.undo, sequence: 0, userId: 'test_user'
).copyWith(isCanceled: true);

ScoreEvent kote(Side side) => ScoreEventLegacyAdapter.fromLegacy(
  side: side, type: PointType.kote, sequence: 0, userId: 'test_user'
);

ScoreEvent dou(Side side) => ScoreEventLegacyAdapter.fromLegacy(
  side: side, type: PointType.doIdo, sequence: 0, userId: 'test_user'
);