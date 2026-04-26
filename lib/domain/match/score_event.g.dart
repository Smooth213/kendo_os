// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScoreEvent _$ScoreEventFromJson(Map<String, dynamic> json) => _ScoreEvent(
  id: json['id'] as String? ?? '',
  side: $enumDecode(_$SideEnumMap, json['side']),
  strikeType:
      $enumDecodeNullable(_$StrikeTypeEnumMap, json['strikeType']) ??
      StrikeType.none,
  isIppon: json['isIppon'] as bool? ?? false,
  isHansoku: json['isHansoku'] as bool? ?? false,
  isFusen: json['isFusen'] as bool? ?? false,
  isHantei: json['isHantei'] as bool? ?? false,
  type: $enumDecode(_$PointTypeEnumMap, json['type']),
  timestamp: const TimestampConverter().fromJson(json['timestamp']),
  userId: json['userId'] as String?,
  sequence: (json['sequence'] as num?)?.toInt() ?? 0,
  isCanceled: json['isCanceled'] as bool? ?? false,
);

Map<String, dynamic> _$ScoreEventToJson(_ScoreEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'side': _$SideEnumMap[instance.side]!,
      'strikeType': _$StrikeTypeEnumMap[instance.strikeType]!,
      'isIppon': instance.isIppon,
      'isHansoku': instance.isHansoku,
      'isFusen': instance.isFusen,
      'isHantei': instance.isHantei,
      'type': _$PointTypeEnumMap[instance.type]!,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'userId': instance.userId,
      'sequence': instance.sequence,
      'isCanceled': instance.isCanceled,
    };

const _$SideEnumMap = {Side.red: 'red', Side.white: 'white', Side.none: 'none'};

const _$StrikeTypeEnumMap = {
  StrikeType.men: 'men',
  StrikeType.kote: 'kote',
  StrikeType.dou: 'dou',
  StrikeType.tsuki: 'tsuki',
  StrikeType.none: 'none',
};

const _$PointTypeEnumMap = {
  PointType.men: 'men',
  PointType.kote: 'kote',
  PointType.doIdo: 'doIdo',
  PointType.tsuki: 'tsuki',
  PointType.hansoku: 'hansoku',
  PointType.undo: 'undo',
  PointType.fusen: 'fusen',
  PointType.hantei: 'hantei',
  PointType.restore: 'restore',
};
