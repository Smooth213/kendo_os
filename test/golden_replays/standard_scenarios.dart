import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';

// Step 3-1: Golden Replay Dataset
// 複雑な試合展開（延長、反則、団体戦等）を網羅した「真実」のデータセット。
class StandardScenarios {
  static final teamMatchWithExtension = [
    // 先鋒: 引き分け
    // 次鋒: 赤一本勝ち
    ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.men, sequence: 1, userId: 'admin'),
    // 中堅: 白二本勝ち
    ScoreEventLegacyAdapter.fromLegacy(side: Side.white, type: PointType.kote, sequence: 2, userId: 'admin'),
    ScoreEventLegacyAdapter.fromLegacy(side: Side.white, type: PointType.men, sequence: 3, userId: 'admin'),
    // 代表戦: 赤一本勝ち (歴史的真実)
  ];

  static const String expectedWinner = 'red'; // 代表戦の結果を含む最終勝者
}