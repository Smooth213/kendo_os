// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchRule _$MatchRuleFromJson(Map<String, dynamic> json) => _MatchRule(
  ipponLimit: (json['ipponLimit'] as num?)?.toInt() ?? 2,
  hansokuLimit: (json['hansokuLimit'] as num?)?.toInt() ?? 2,
  isIpponShobu: json['isIpponShobu'] as bool? ?? false,
  matchTimeMinutes: (json['matchTimeMinutes'] as num?)?.toDouble() ?? 3.0,
  isRunningTime: json['isRunningTime'] as bool? ?? false,
  hasHantei: json['hasHantei'] as bool? ?? false,
  isEnchoUnlimited: json['isEnchoUnlimited'] as bool? ?? false,
  enchoTimeMinutes: (json['enchoTimeMinutes'] as num?)?.toDouble() ?? 3.0,
  enchoCount: (json['enchoCount'] as num?)?.toInt() ?? 1,
  isKachinuki: json['isKachinuki'] as bool? ?? false,
  kachinukiUnlimitedType: json['kachinukiUnlimitedType'] as String? ?? '大将対大将',
  hasRepresentativeMatch: json['hasRepresentativeMatch'] as bool? ?? true,
  isDaihyoIpponShobu: json['isDaihyoIpponShobu'] as bool? ?? true,
  positions:
      (json['positions'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const ['選手'],
  baseOrder:
      (json['baseOrder'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  teamName: json['teamName'] as String? ?? '',
  category: json['category'] as String? ?? '',
  note: json['note'] as String? ?? '',
  isLeague: json['isLeague'] as bool? ?? false,
  leagueOrder:
      (json['leagueOrder'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  hasLeagueDaihyo: json['hasLeagueDaihyo'] as bool? ?? false,
  winPoint: (json['winPoint'] as num?)?.toDouble() ?? 0.0,
  lossPoint: (json['lossPoint'] as num?)?.toDouble() ?? 0.0,
  drawPoint: (json['drawPoint'] as num?)?.toDouble() ?? 0.0,
  isRenseikai: json['isRenseikai'] as bool? ?? false,
  renseikaiType: json['renseikaiType'] as String? ?? '一試合制',
  overallTimeMinutes: (json['overallTimeMinutes'] as num?)?.toInt() ?? 30,
);

Map<String, dynamic> _$MatchRuleToJson(_MatchRule instance) =>
    <String, dynamic>{
      'ipponLimit': instance.ipponLimit,
      'hansokuLimit': instance.hansokuLimit,
      'isIpponShobu': instance.isIpponShobu,
      'matchTimeMinutes': instance.matchTimeMinutes,
      'isRunningTime': instance.isRunningTime,
      'hasHantei': instance.hasHantei,
      'isEnchoUnlimited': instance.isEnchoUnlimited,
      'enchoTimeMinutes': instance.enchoTimeMinutes,
      'enchoCount': instance.enchoCount,
      'isKachinuki': instance.isKachinuki,
      'kachinukiUnlimitedType': instance.kachinukiUnlimitedType,
      'hasRepresentativeMatch': instance.hasRepresentativeMatch,
      'isDaihyoIpponShobu': instance.isDaihyoIpponShobu,
      'positions': instance.positions,
      'baseOrder': instance.baseOrder,
      'teamName': instance.teamName,
      'category': instance.category,
      'note': instance.note,
      'isLeague': instance.isLeague,
      'leagueOrder': instance.leagueOrder,
      'hasLeagueDaihyo': instance.hasLeagueDaihyo,
      'winPoint': instance.winPoint,
      'lossPoint': instance.lossPoint,
      'drawPoint': instance.drawPoint,
      'isRenseikai': instance.isRenseikai,
      'renseikaiType': instance.renseikaiType,
      'overallTimeMinutes': instance.overallTimeMinutes,
    };
