// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchRule _$MatchRuleFromJson(Map<String, dynamic> json) => _MatchRule(
  positions:
      (json['positions'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const ['選手'],
  matchTimeMinutes: (json['matchTimeMinutes'] as num?)?.toDouble() ?? 3.0,
  isRunningTime: json['isRunningTime'] as bool? ?? false,
  isLeague: json['isLeague'] as bool? ?? false,
  category: json['category'] as String? ?? '',
  note: json['note'] as String? ?? '',
  isRenseikai: json['isRenseikai'] as bool? ?? false,
  baseOrder:
      (json['baseOrder'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  teamName: json['teamName'] as String? ?? '',
  isKachinuki: json['isKachinuki'] as bool? ?? false,
  kachinukiUnlimitedType: json['kachinukiUnlimitedType'] as String? ?? '大将対大将',
  hasLeagueDaihyo: json['hasLeagueDaihyo'] as bool? ?? false,
  renseikaiType: json['renseikaiType'] as String? ?? '一試合制',
  overallTimeMinutes: (json['overallTimeMinutes'] as num?)?.toInt() ?? 30,
  isDaihyoIpponShobu: json['isDaihyoIpponShobu'] as bool? ?? true,
  hasRepresentativeMatch: json['hasRepresentativeMatch'] as bool? ?? true,
  isEnchoUnlimited: json['isEnchoUnlimited'] as bool? ?? false,
  enchoTimeMinutes: (json['enchoTimeMinutes'] as num?)?.toDouble() ?? 3.0,
  enchoCount: (json['enchoCount'] as num?)?.toInt() ?? 1,
  hasHantei: json['hasHantei'] as bool? ?? false,
  leagueOrder:
      (json['leagueOrder'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  winPoint: (json['winPoint'] as num?)?.toDouble() ?? 0.0,
  lossPoint: (json['lossPoint'] as num?)?.toDouble() ?? 0.0,
  drawPoint: (json['drawPoint'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$MatchRuleToJson(_MatchRule instance) =>
    <String, dynamic>{
      'positions': instance.positions,
      'matchTimeMinutes': instance.matchTimeMinutes,
      'isRunningTime': instance.isRunningTime,
      'isLeague': instance.isLeague,
      'category': instance.category,
      'note': instance.note,
      'isRenseikai': instance.isRenseikai,
      'baseOrder': instance.baseOrder,
      'teamName': instance.teamName,
      'isKachinuki': instance.isKachinuki,
      'kachinukiUnlimitedType': instance.kachinukiUnlimitedType,
      'hasLeagueDaihyo': instance.hasLeagueDaihyo,
      'renseikaiType': instance.renseikaiType,
      'overallTimeMinutes': instance.overallTimeMinutes,
      'isDaihyoIpponShobu': instance.isDaihyoIpponShobu,
      'hasRepresentativeMatch': instance.hasRepresentativeMatch,
      'isEnchoUnlimited': instance.isEnchoUnlimited,
      'enchoTimeMinutes': instance.enchoTimeMinutes,
      'enchoCount': instance.enchoCount,
      'hasHantei': instance.hasHantei,
      'leagueOrder': instance.leagueOrder,
      'winPoint': instance.winPoint,
      'lossPoint': instance.lossPoint,
      'drawPoint': instance.drawPoint,
    };
