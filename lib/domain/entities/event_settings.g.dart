// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventSettings _$EventSettingsFromJson(Map<String, dynamic> json) =>
    _EventSettings(
      id: json['id'] as String? ?? 'test_event_v2',
      name: json['name'] as String? ?? '新規大会',
      defaultFormat:
          $enumDecodeNullable(_$MatchFormatEnumMap, json['defaultFormat']) ??
          MatchFormat.individual,
      defaultDurationSeconds:
          (json['defaultDurationSeconds'] as num?)?.toInt() ?? 180,
    );

Map<String, dynamic> _$EventSettingsToJson(_EventSettings instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'defaultFormat': _$MatchFormatEnumMap[instance.defaultFormat]!,
      'defaultDurationSeconds': instance.defaultDurationSeconds,
    };

const _$MatchFormatEnumMap = {
  MatchFormat.individual: 'individual',
  MatchFormat.team: 'team',
};
