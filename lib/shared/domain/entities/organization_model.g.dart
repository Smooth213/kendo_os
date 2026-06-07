// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrganizationModel _$OrganizationModelFromJson(Map<String, dynamic> json) =>
    _OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      memberNames:
          (json['memberNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$OrganizationModelToJson(_OrganizationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'memberNames': instance.memberNames,
    };
