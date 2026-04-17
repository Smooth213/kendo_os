import 'package:freezed_annotation/freezed_annotation.dart';
import 'event_settings.dart';
import 'score_event.dart';

part 'kendo_match.freezed.dart';
part 'kendo_match.g.dart';

enum MatchStatus { waiting, playing, done } 

@freezed
abstract class TeamInfo with _$TeamInfo {
  const factory TeamInfo({
    required String teamId,
    required String name,
    @Default([]) List<String> memberIds,
  }) = _TeamInfo;

  factory TeamInfo.fromJson(Map<String, dynamic> json) => _$TeamInfoFromJson(json);
}

@freezed
abstract class SubMatch with _$SubMatch {
  const factory SubMatch({
    required String id,
    required String positionName,
    String? redPlayerId,
    String? whitePlayerId,
    @Default('赤') String redPlayerName,
    @Default('白') String whitePlayerName,
    @Default(MatchStatus.waiting) MatchStatus status,
    @Default(0) int elapsedTime,
    @Default(false) bool isTimerRunning,
    @Default([]) List<ScoreEvent> events,
  }) = _SubMatch;

  factory SubMatch.fromJson(Map<String, dynamic> json) => _$SubMatchFromJson(json);
}

@freezed
abstract class KendoMatch with _$KendoMatch {
  const KendoMatch._();

  const factory KendoMatch({
    required String id,
    required String eventId,
    required String title,
    @Default('manual') String source,
    @Default(0) int order,
    @Default(MatchFormat.individual) MatchFormat type,
    TeamInfo? teamA,
    TeamInfo? teamB,
    @Default(MatchStatus.waiting) MatchStatus status,
    String? scorerId,
    @Default([]) List<String> referees,
    @Default([]) List<SubMatch> subMatches,
  }) = _KendoMatch;

  factory KendoMatch.fromJson(Map<String, dynamic> json) => _$KendoMatchFromJson(json);
}