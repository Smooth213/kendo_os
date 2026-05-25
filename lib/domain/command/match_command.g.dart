// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchCommand _$MatchCommandFromJson(Map<String, dynamic> json) =>
    _MatchCommand(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      commandType: json['commandType'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      operatorId: json['operatorId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MatchCommandToJson(_MatchCommand instance) =>
    <String, dynamic>{
      'id': instance.id,
      'matchId': instance.matchId,
      'commandType': instance.commandType,
      'payload': instance.payload,
      'operatorId': instance.operatorId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
