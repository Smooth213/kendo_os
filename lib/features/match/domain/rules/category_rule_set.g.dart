// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_rule_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryRuleSet _$CategoryRuleSetFromJson(Map<String, dynamic> json) =>
    _CategoryRuleSet(
      normalRule: json['normalRule'] == null
          ? const MatchRule()
          : MatchRule.fromJson(json['normalRule'] as Map<String, dynamic>),
      advancedRule: json['advancedRule'] == null
          ? const MatchRule()
          : MatchRule.fromJson(json['advancedRule'] as Map<String, dynamic>),
      useAdvancedRule: json['useAdvancedRule'] as bool? ?? false,
      advancedKeywords:
          (json['advancedKeywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['準決勝', '準決', '決勝', 'final', '3位決定', '3決', 'ベスト4'],
      matchType: json['matchType'] as String? ?? '個人戦',
      isMultiScene: json['isMultiScene'] as bool? ?? false,
      useHonsenRule: json['useHonsenRule'] as bool? ?? true,
      useRenseikaiRule: json['useRenseikaiRule'] as bool? ?? true,
      useMoushiawaseRule: json['useMoushiawaseRule'] as bool? ?? true,
      renseikaiRule: json['renseikaiRule'] == null
          ? const MatchRule(
              matchTimeMinutes: 2,
              isRunningTime: true,
              hasHantei: true,
              enchoCount: 0,
              isEnchoUnlimited: false,
              isRenseikai: true,
              matchScene: 'renseikai',
            )
          : MatchRule.fromJson(json['renseikaiRule'] as Map<String, dynamic>),
      moushiawaseRule: json['moushiawaseRule'] == null
          ? const MatchRule(
              matchTimeMinutes: 2,
              isRunningTime: true,
              hasHantei: true,
              enchoCount: 0,
              isEnchoUnlimited: false,
              isRenseikai: true,
              matchScene: 'moushiawase',
            )
          : MatchRule.fromJson(json['moushiawaseRule'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CategoryRuleSetToJson(_CategoryRuleSet instance) =>
    <String, dynamic>{
      'normalRule': instance.normalRule.toJson(),
      'advancedRule': instance.advancedRule.toJson(),
      'useAdvancedRule': instance.useAdvancedRule,
      'advancedKeywords': instance.advancedKeywords,
      'matchType': instance.matchType,
      'isMultiScene': instance.isMultiScene,
      'useHonsenRule': instance.useHonsenRule,
      'useRenseikaiRule': instance.useRenseikaiRule,
      'useMoushiawaseRule': instance.useMoushiawaseRule,
      'renseikaiRule': instance.renseikaiRule.toJson(),
      'moushiawaseRule': instance.moushiawaseRule.toJson(),
    };
