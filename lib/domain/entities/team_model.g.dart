// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamModel _$TeamModelFromJson(Map<String, dynamic> json) => _TeamModel(
  id: json['id'] as String,
  tournamentId: json['tournamentId'] as String,
  category: json['category'] as String,
  teamName: json['teamName'] as String,
  matchType: json['matchType'] as String? ?? '団体戦（5人制）',
  playerNames:
      (json['playerNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$TeamModelToJson(_TeamModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournamentId': instance.tournamentId,
      'category': instance.category,
      'teamName': instance.teamName,
      'matchType': instance.matchType,
      'playerNames': instance.playerNames,
    };
