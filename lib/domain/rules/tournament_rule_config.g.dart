// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_rule_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimeConfig _$TimeConfigFromJson(Map<String, dynamic> json) => _TimeConfig(
  matchTimeMinutes: (json['matchTimeMinutes'] as num?)?.toDouble() ?? 3.0,
  isRunningTime: json['isRunningTime'] as bool? ?? false,
);

Map<String, dynamic> _$TimeConfigToJson(_TimeConfig instance) =>
    <String, dynamic>{
      'matchTimeMinutes': instance.matchTimeMinutes,
      'isRunningTime': instance.isRunningTime,
    };

_EnchoConfig _$EnchoConfigFromJson(Map<String, dynamic> json) => _EnchoConfig(
  isEnchoUnlimited: json['isEnchoUnlimited'] as bool? ?? false,
  enchoTimeMinutes: (json['enchoTimeMinutes'] as num?)?.toDouble() ?? 3.0,
  enchoCount: (json['enchoCount'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$EnchoConfigToJson(_EnchoConfig instance) =>
    <String, dynamic>{
      'isEnchoUnlimited': instance.isEnchoUnlimited,
      'enchoTimeMinutes': instance.enchoTimeMinutes,
      'enchoCount': instance.enchoCount,
    };

_ScoringConfig _$ScoringConfigFromJson(Map<String, dynamic> json) =>
    _ScoringConfig(
      ipponLimit: (json['ipponLimit'] as num?)?.toInt() ?? 2,
      isIpponShobu: json['isIpponShobu'] as bool? ?? false,
    );

Map<String, dynamic> _$ScoringConfigToJson(_ScoringConfig instance) =>
    <String, dynamic>{
      'ipponLimit': instance.ipponLimit,
      'isIpponShobu': instance.isIpponShobu,
    };

_HansokuConfig _$HansokuConfigFromJson(Map<String, dynamic> json) =>
    _HansokuConfig(hansokuLimit: (json['hansokuLimit'] as num?)?.toInt() ?? 2);

Map<String, dynamic> _$HansokuConfigToJson(_HansokuConfig instance) =>
    <String, dynamic>{'hansokuLimit': instance.hansokuLimit};

_TeamConfig _$TeamConfigFromJson(Map<String, dynamic> json) => _TeamConfig(
  isKachinuki: json['isKachinuki'] as bool? ?? false,
  kachinukiUnlimitedType: json['kachinukiUnlimitedType'] as String? ?? '大将対大将',
  hasRepresentativeMatch: json['hasRepresentativeMatch'] as bool? ?? true,
  isDaihyoIpponShobu: json['isDaihyoIpponShobu'] as bool? ?? true,
);

Map<String, dynamic> _$TeamConfigToJson(_TeamConfig instance) =>
    <String, dynamic>{
      'isKachinuki': instance.isKachinuki,
      'kachinukiUnlimitedType': instance.kachinukiUnlimitedType,
      'hasRepresentativeMatch': instance.hasRepresentativeMatch,
      'isDaihyoIpponShobu': instance.isDaihyoIpponShobu,
    };

_DrawConfig _$DrawConfigFromJson(Map<String, dynamic> json) =>
    _DrawConfig(hasHantei: json['hasHantei'] as bool? ?? false);

Map<String, dynamic> _$DrawConfigToJson(_DrawConfig instance) =>
    <String, dynamic>{'hasHantei': instance.hasHantei};

_TournamentRuleConfig _$TournamentRuleConfigFromJson(
  Map<String, dynamic> json,
) => _TournamentRuleConfig(
  schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
  time: json['time'] == null
      ? const TimeConfig()
      : TimeConfig.fromJson(json['time'] as Map<String, dynamic>),
  encho: json['encho'] == null
      ? const EnchoConfig()
      : EnchoConfig.fromJson(json['encho'] as Map<String, dynamic>),
  scoring: json['scoring'] == null
      ? const ScoringConfig()
      : ScoringConfig.fromJson(json['scoring'] as Map<String, dynamic>),
  hansoku: json['hansoku'] == null
      ? const HansokuConfig()
      : HansokuConfig.fromJson(json['hansoku'] as Map<String, dynamic>),
  team: json['team'] == null
      ? const TeamConfig()
      : TeamConfig.fromJson(json['team'] as Map<String, dynamic>),
  draw: json['draw'] == null
      ? const DrawConfig()
      : DrawConfig.fromJson(json['draw'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TournamentRuleConfigToJson(
  _TournamentRuleConfig instance,
) => <String, dynamic>{
  'schemaVersion': instance.schemaVersion,
  'time': instance.time.toJson(),
  'encho': instance.encho.toJson(),
  'scoring': instance.scoring.toJson(),
  'hansoku': instance.hansoku.toJson(),
  'team': instance.team.toJson(),
  'draw': instance.draw.toJson(),
};
