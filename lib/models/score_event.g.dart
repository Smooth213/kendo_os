// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScoreEvent _$ScoreEventFromJson(Map<String, dynamic> json) => _ScoreEvent(
  id: json['id'] as String? ?? '',
  side: $enumDecode(_$SideEnumMap, json['side']),
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
      'type': _$PointTypeEnumMap[instance.type]!,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'userId': instance.userId,
      'sequence': instance.sequence,
      'isCanceled': instance.isCanceled,
    };

const _$SideEnumMap = {Side.red: 'red', Side.white: 'white', Side.none: 'none'};

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
