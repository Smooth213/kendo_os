// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TournamentModel _$TournamentModelFromJson(Map<String, dynamic> json) =>
    _TournamentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      date: const TimestampConverter().fromJson(json['date']),
      venue: json['venue'] as String,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String? ?? '',
    );

Map<String, dynamic> _$TournamentModelToJson(_TournamentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'date': const TimestampConverter().toJson(instance.date),
      'venue': instance.venue,
      'categories': instance.categories,
      'status': instance.status,
      'notes': instance.notes,
    };
