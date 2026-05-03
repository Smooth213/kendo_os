import 'tournament_projection.dart';
import '../mappers/match_projection_mapper.dart';
import '../../domain/entities/tournament_model.dart';
import '../../domain/entities/match_model.dart';
import '../../domain/services/team_match_calculator.dart';
import '../../domain/services/kendo_rule_engine.dart';

class TournamentProjectionMapper {
  static TournamentProjection fromModels(
    TournamentModel tournament,
    List<MatchModel> matches,
  ) {
    final engine = KendoRuleEngine();

    // 全試合の変換
    final allMatchProjections = matches.map((m) {
      final analysis = engine.analyzeHistory(m.events, m, m.rule);
      return MatchProjectionMapper.toProjection(m, analysis);
    }).toList();

    // 団体戦・リーグ戦のグループ化と集計
    final teamMatches = <String, TeamMatchProjection>{};
    final groupedMatches = <String, List<MatchModel>>{};

    for (var m in matches) {
      if (m.groupName != null && m.groupName!.isNotEmpty) {
        groupedMatches.putIfAbsent(m.groupName!, () => []).add(m);
      }
    }

    groupedMatches.forEach((groupName, groupList) {
      groupList.sort((a, b) => a.order.compareTo(b.order));
      final firstMatch = groupList.first;
      
      final result = TeamMatchCalculator.calculate(groupList);
      final matchProjections = groupList.map((m) {
        final analysis = engine.analyzeHistory(m.events, m, m.rule);
        return MatchProjectionMapper.toProjection(m, analysis);
      }).toList();

      final isLeague = firstMatch.note.contains('[リーグ戦]') || (firstMatch.rule?.isLeague ?? false);
      List<LeagueTeamStat> standings = [];
      if (isLeague && firstMatch.rule != null) {
        standings = KendoRuleEngine.calculateLeagueStandings(
          groupList.where((m) => !m.note.contains('[順位決定戦]')).toList(), 
          firstMatch.rule!
        );
      }

      teamMatches[groupName] = TeamMatchProjection(
        groupName: groupName,
        redTeamName: firstMatch.redName.contains(':') ? firstMatch.redName.split(':').first.trim() : firstMatch.redName,
        whiteTeamName: firstMatch.whiteName.contains(':') ? firstMatch.whiteName.split(':').first.trim() : firstMatch.whiteName,
        matchType: firstMatch.matchType,
        note: firstMatch.note,
        isKachinuki: firstMatch.isKachinuki,
        isLeague: isLeague,
        matches: matchProjections,
        result: result,
        leagueStandings: standings,
      );
    });

    final categoryToGroupKeys = <String, List<String>>{};
    for (var m in matches) {
      if (m.groupName == null || m.groupName!.isEmpty) continue;
      final cat = (m.category != null && m.category!.isNotEmpty) ? m.category! : '一般';
      
      categoryToGroupKeys.putIfAbsent(cat, () => []);
      if (!categoryToGroupKeys[cat]!.contains(m.groupName!)) {
        categoryToGroupKeys[cat]!.add(m.groupName!);
      }
    }

    return TournamentProjection(
      tournament: tournament,
      allMatches: allMatchProjections,
      teamMatches: teamMatches,
      categoryToGroupKeys: categoryToGroupKeys,
    );
  }
}