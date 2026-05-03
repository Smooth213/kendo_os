// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchMeta _$MatchMetaFromJson(Map<String, dynamic> json) => _MatchMeta(
  matchType: json['matchType'] as String,
  redName: json['redName'] as String,
  whiteName: json['whiteName'] as String,
  note: json['note'] as String? ?? '',
  tournamentId: json['tournamentId'] as String?,
  category: json['category'] as String?,
  groupName: json['groupName'] as String?,
  matchOrder: (json['matchOrder'] as num?)?.toInt(),
  refereeNames:
      (json['refereeNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  countForStandings: json['countForStandings'] as bool? ?? false,
  isAutoAssigned: json['isAutoAssigned'] as bool? ?? false,
);

Map<String, dynamic> _$MatchMetaToJson(_MatchMeta instance) =>
    <String, dynamic>{
      'matchType': instance.matchType,
      'redName': instance.redName,
      'whiteName': instance.whiteName,
      'note': instance.note,
      'tournamentId': instance.tournamentId,
      'category': instance.category,
      'groupName': instance.groupName,
      'matchOrder': instance.matchOrder,
      'refereeNames': instance.refereeNames,
      'countForStandings': instance.countForStandings,
      'isAutoAssigned': instance.isAutoAssigned,
    };
