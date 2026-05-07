import 'package:kendo_os/domain/entities/tournament_model.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/application/projections/tournament_projection.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/services/team_match_calculator.dart'; 

class TournamentProjectionMapper {
  // 既存の旧型変換メソッド（下位互換性のため残す）
  static TournamentProjection fromModels(TournamentModel tournament, List<MatchModel> matches) {
    final engine = KendoRuleEngine();
    final projections = matches.map((m) {
      final analysis = engine.analyzeHistory(m.events, m, m.rule);
      return MatchProjectionMapper.toProjection(m, analysis);
    }).toList();

    return _buildTournamentProjection(tournament, projections);
  }

  // ★ B-4: すでに構築済みのProjectionリストからTournamentProjectionを生成する
  static TournamentProjection fromProjections(TournamentModel tournament, List<MatchProjection> projections) {
    return _buildTournamentProjection(tournament, projections);
  }

  // 内部の共通組み立てロジック
  static TournamentProjection _buildTournamentProjection(
    TournamentModel tournament, 
    List<MatchProjection> projections,
  ) {
    final Map<String, TeamMatchProjection> teamMatches = {};
    final Map<String, Set<String>> categoryToGroupKeys = {};

    for (var p in projections) {
      if (p.groupName.isEmpty) continue;
      
      final cat = '全カテゴリ';
      categoryToGroupKeys.putIfAbsent(cat, () => {}).add(p.groupName);

      if (!teamMatches.containsKey(p.groupName)) {
        final groupProjections = projections.where((m) => m.groupName == p.groupName).toList();

        // 団体戦結果の簡易計算（Projectionのデータだけで計算する）
        int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
        bool hasDaihyo = false; // ★ 追加
        bool allFinished = groupProjections.every((m) => m.status == 'approved' || m.status == 'finished');
        
        for (var m in groupProjections) {
          if (m.matchType == '代表戦') {
            hasDaihyo = true; // ★ 追加
          }
          if (m.status == 'approved' || m.status == 'finished') {
            if (m.redScore > m.whiteScore) {
              rWins++;
            } else if (m.whiteScore > m.redScore) {
              wWins++;
            }
            rPts += m.redScore;
            wPts += m.whiteScore;
          }
        }
        
        String winner = 'draw';
        if (allFinished) {
          if (rWins > wWins) {
            winner = 'red';
          } else if (wWins > rWins) {
            winner = 'white';
          } else if (rPts > wPts) {
            winner = 'red';
          } else if (wPts > rPts) {
            winner = 'white';
          }
        }

        teamMatches[p.groupName] = TeamMatchProjection(
          groupName: p.groupName,
          matchType: p.matchType,
          redTeamName: p.redName.contains(':') ? p.redName.split(':').first.trim() : p.redName,
          whiteTeamName: p.whiteName.contains(':') ? p.whiteName.split(':').first.trim() : p.whiteName,
          isKachinuki: p.isKachinuki,
          isLeague: p.note.contains('[リーグ戦]'),
          note: p.note,
          matches: groupProjections,
          result: TeamMatchResult(
            teamWinner: winner,
            redWins: rWins,
            whiteWins: wWins,
            redPoints: rPts,
            whitePoints: wPts,
            allFinished: allFinished,
            hasDaihyo: hasDaihyo, // ★ 修正: 必須パラメータ追加
            isTie: winner == 'draw', // ★ 修正: 必須パラメータ追加
          ),
        );
      }
    }

    return TournamentProjection(
      tournament: tournament,
      allMatches: projections, 
      teamMatches: teamMatches,
      categoryToGroupKeys: categoryToGroupKeys.map((k, v) => MapEntry(k, v.toList())),
    );
  }
}