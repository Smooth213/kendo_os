import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';

/// 🥋 途中棄権オーケストレーションヘルパー
class MatchRetirementHelper {
  final AddScoreUseCase _addScore;

  const MatchRetirementHelper(this._addScore);

  /// 途中棄権イベントを適用し、更新後の MatchModel を生成
  MatchModel processRetirement({
    required User user,
    required MatchModel match,
    required Side retiredSide,
    required MatchRule rule,
  }) {
    final winnerSide = retiredSide == Side.red ? Side.white : Side.red;
    final ruleEngine = KendoRuleEngine();
    final analysis = ruleEngine.analyzeHistory(match.events, match, rule);

    final currentWinnerIppon = winnerSide == Side.red
        ? analysis.context.redIppon
        : analysis.context.whiteIppon;
    final targetIppon = analysis.context.targetIppon;
    final neededPoints = (targetIppon - currentWinnerIppon).clamp(
      1,
      targetIppon,
    );

    int maxClock = match.events.isEmpty
        ? 0
        : match.events
              .map((e) => e.logicalClock)
              .reduce((a, b) => a > b ? a : b);

    MatchModel currentProcessingMatch = match;
    for (int i = 0; i < neededPoints; i++) {
      final event = ScoreEventLegacyAdapter.fromLegacy(
        id: const Uuid().v4(),
        side: winnerSide,
        type: PointType.fusen,
        timestamp: DateTime.now(),
        userId: user.id,
        sequence: currentProcessingMatch.events.isEmpty
            ? 1
            : currentProcessingMatch.events.last.sequence + 1,
        logicalClock: maxClock + i + 1,
        isRetirement: true,
      );

      currentProcessingMatch = _addScore.execute(
        user,
        currentProcessingMatch,
        event,
        rule,
      );
    }

    return currentProcessingMatch;
  }
}
