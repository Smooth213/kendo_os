import 'package:kendo_os/models/match_model.dart';
import 'package:kendo_os/domain/match/match_rule.dart';
import 'package:kendo_os/domain/match/score_event.dart';
import 'package:uuid/uuid.dart';

/// ★ Step 0-3: テスト用の MatchModel や ScoreEvent を爆速で生成する工場
class TestMatchFactory {
  /// 基本的な個人戦の試合を作成
  static MatchModel createIndividualMatch({
    String id = 'test-match-1',
    String redName = '赤選手',
    String whiteName = '白選手',
    List<ScoreEvent> events = const [],
  }) {
    return MatchModel(
      id: id,
      matchType: '個人戦',
      redName: redName,
      whiteName: whiteName,
      events: events,
      status: 'in_progress',
    );
  }

  /// スコアイベントを作成
  static ScoreEvent createEvent({
    required Side side,
    required PointType type,
    int sequence = 1,
  }) {
    return ScoreEvent(
      id: const Uuid().v4(),
      side: side,
      type: type,
      timestamp: DateTime.now(),
      sequence: sequence,
    );
  }

  /// 基本的なルールセットを作成
  static MatchRule createDefaultRule() {
    return MatchRule(
      matchTimeMinutes: 3,
      isKachinuki: false,
    );
  }
}