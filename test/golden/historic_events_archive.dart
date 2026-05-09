import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';

class HistoricEventsArchive {
  // Step 6-1: Golden Replay Archive
  // 過去の大会で記録された「真実」のイベントストリーム（絶対に書き換えてはならない）
  static final v1MatchEvents = [
    ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.men, sequence: 1, userId: 'ref_1'),
    ScoreEventLegacyAdapter.fromLegacy(side: Side.white, type: PointType.kote, sequence: 2, userId: 'ref_1'),
    ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.men, sequence: 3, userId: 'ref_1'),
  ];

  // 歴史的な事実としての最終状態（期待値）
  static const int expectedRedScore = 2;
  static const int expectedWhiteScore = 1;
}