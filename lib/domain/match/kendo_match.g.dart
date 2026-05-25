// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kendo_match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamInfo _$TeamInfoFromJson(Map<String, dynamic> json) => _TeamInfo(
  teamId: json['teamId'] as String,
  name: json['name'] as String,
  memberIds:
      (json['memberIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$TeamInfoToJson(_TeamInfo instance) => <String, dynamic>{
  'teamId': instance.teamId,
  'name': instance.name,
  'memberIds': instance.memberIds,
};

_SubMatch _$SubMatchFromJson(Map<String, dynamic> json) => _SubMatch(
  id: json['id'] as String,
  positionName: json['positionName'] as String,
  redPlayerId: json['redPlayerId'] as String?,
  whitePlayerId: json['whitePlayerId'] as String?,
  redPlayerName: json['redPlayerName'] as String? ?? '赤',
  whitePlayerName: json['whitePlayerName'] as String? ?? '白',
  status:
      $enumDecodeNullable(_$MatchStatusEnumMap, json['status']) ??
      MatchStatus.waiting,
  elapsedTime: (json['elapsedTime'] as num?)?.toInt() ?? 0,
  isTimerRunning: json['isTimerRunning'] as bool? ?? false,
  events:
      (json['events'] as List<dynamic>?)
          ?.map((e) => ScoreEvent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubMatchToJson(_SubMatch instance) => <String, dynamic>{
  'id': instance.id,
  'positionName': instance.positionName,
  'redPlayerId': instance.redPlayerId,
  'whitePlayerId': instance.whitePlayerId,
  'redPlayerName': instance.redPlayerName,
  'whitePlayerName': instance.whitePlayerName,
  'status': _$MatchStatusEnumMap[instance.status]!,
  'elapsedTime': instance.elapsedTime,
  'isTimerRunning': instance.isTimerRunning,
  'events': instance.events.map((e) => e.toJson()).toList(),
};

const _$MatchStatusEnumMap = {
  MatchStatus.waiting: 'waiting',
  MatchStatus.playing: 'playing',
  MatchStatus.done: 'done',
};

_KendoMatch _$KendoMatchFromJson(Map<String, dynamic> json) => _KendoMatch(
  id: json['id'] as String,
  eventId: json['eventId'] as String,
  title: json['title'] as String,
  source: json['source'] as String? ?? 'manual',
  order: (json['order'] as num?)?.toInt() ?? 0,
  type:
      $enumDecodeNullable(_$MatchFormatEnumMap, json['type']) ??
      MatchFormat.individual,
  teamA: json['teamA'] == null
      ? null
      : TeamInfo.fromJson(json['teamA'] as Map<String, dynamic>),
  teamB: json['teamB'] == null
      ? null
      : TeamInfo.fromJson(json['teamB'] as Map<String, dynamic>),
  status:
      $enumDecodeNullable(_$MatchStatusEnumMap, json['status']) ??
      MatchStatus.waiting,
  scorerId: json['scorerId'] as String?,
  referees:
      (json['referees'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  subMatches:
      (json['subMatches'] as List<dynamic>?)
          ?.map((e) => SubMatch.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$KendoMatchToJson(_KendoMatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'title': instance.title,
      'source': instance.source,
      'order': instance.order,
      'type': _$MatchFormatEnumMap[instance.type]!,
      'teamA': instance.teamA?.toJson(),
      'teamB': instance.teamB?.toJson(),
      'status': _$MatchStatusEnumMap[instance.status]!,
      'scorerId': instance.scorerId,
      'referees': instance.referees,
      'subMatches': instance.subMatches.map((e) => e.toJson()).toList(),
    };

const _$MatchFormatEnumMap = {
  MatchFormat.individual: 'individual',
  MatchFormat.team: 'team',
};
