import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

/// リーグ戦終了時の同点・タイブレーク（順位決定戦要否）検出ヘルパー
class TimelineTieBreakDetector {
  static List<List<dynamic>> detectTieGroups({
    required List<MatchModel> normalMatches,
    required MatchRule? rule,
  }) {
    final tieGroups = <List<dynamic>>[];
    if (rule == null) return tieGroups;

    final stats = KendoRuleEngine.calculateLeagueStandings(normalMatches, rule);
    if (stats.length <= 1) return tieGroups;

    List<dynamic> currentTie = [stats.first];
    for (int i = 1; i < stats.length; i++) {
      final prev = stats[i - 1];
      final curr = stats[i];
      bool isTie =
          (prev.customPoints - curr.customPoints).abs() < 0.001 &&
          prev.matchWins == curr.matchWins &&
          prev.individualWinners == curr.individualWinners &&
          prev.totalPointsScored == curr.totalPointsScored;
      if (isTie) {
        currentTie.add(curr);
      } else {
        if (currentTie.length > 1) {
          tieGroups.add(List.from(currentTie));
        }
        currentTie = [curr];
      }
    }
    if (currentTie.length > 1) {
      tieGroups.add(currentTie);
    }

    return tieGroups;
  }
}
