// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Organization _$OrganizationFromJson(Map<String, dynamic> json) =>
    _Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      memberNames:
          (json['memberNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$OrganizationToJson(_Organization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'memberNames': instance.memberNames,
    };

_TeamTemplate _$TeamTemplateFromJson(Map<String, dynamic> json) =>
    _TeamTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      orderedMemberNames:
          (json['orderedMemberNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$TeamTemplateToJson(_TeamTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'orderedMemberNames': instance.orderedMemberNames,
    };
