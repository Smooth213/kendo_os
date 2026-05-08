import 'package:freezed_annotation/freezed_annotation.dart';
import 'match_projection.dart';
import '../../domain/entities/tournament_model.dart';
import '../../domain/services/team_match_calculator.dart';
import '../../domain/services/standings_calculator.dart';

part 'tournament_projection.freezed.dart';

@freezed
abstract class TeamMatchProjection with _$TeamMatchProjection {
  const factory TeamMatchProjection({
    required String groupName,
    required String redTeamName,
    required String whiteTeamName,
    required String matchType,
    required String note,
    required bool isKachinuki,
    required bool isLeague,
    // ★ Phase 5: リスト表示用の軽量データ(MatchListProjection)を持つように変更
    required List<MatchListProjection> matches,
    required TeamMatchResult result,
    @Default([]) List<LeagueTeamStat> leagueStandings,
  }) = _TeamMatchProjection;
}

@freezed
abstract class TournamentProjection with _$TournamentProjection {
  const factory TournamentProjection({
    required TournamentModel tournament,
    // ★ Phase 5: リスト表示用の軽量データ(MatchListProjection)を持つように変更
    required List<MatchListProjection> allMatches,
    required Map<String, TeamMatchProjection> teamMatches,
    // --- 追加: 公式記録用の集計データ ---
    required Map<String, List<String>> categoryToGroupKeys, // カテゴリ名 -> グループ名リスト
  }) = _TournamentProjection;
}