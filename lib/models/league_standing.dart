import 'package:freezed_annotation/freezed_annotation.dart';

part 'league_standing.freezed.dart';

@freezed
abstract class LeagueStanding with _$LeagueStanding {
  const factory LeagueStanding({
    required String playerName,
    @Default(0) int matchesPlayed,
    @Default(0) int wins,
    @Default(0) int losses,
    @Default(0) int draws,
    @Default(0) int pointsFor,    // 取得本数
    @Default(0) int pointsAgainst,// 喪失本数
  }) = _LeagueStanding;
}