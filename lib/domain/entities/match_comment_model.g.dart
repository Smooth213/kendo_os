// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchCommentModel _$MatchCommentModelFromJson(Map<String, dynamic> json) =>
    _MatchCommentModel(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String?,
      category: json['category'] as String?,
      groupName: json['groupName'] as String?,
      text: json['text'] as String,
      order: json['order'] == null
          ? 0.0
          : const DoubleConverter().fromJson(json['order']),
      syncState:
          $enumDecodeNullable(_$SyncStateEnumMap, json['syncState']) ??
          SyncState.synced,
      lastUpdatedAt: const SafeTimestampConverter().fromJson(
        json['lastUpdatedAt'],
      ),
    );

Map<String, dynamic> _$MatchCommentModelToJson(_MatchCommentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournamentId': instance.tournamentId,
      'category': instance.category,
      'groupName': instance.groupName,
      'text': instance.text,
      'order': const DoubleConverter().toJson(instance.order),
      'syncState': _$SyncStateEnumMap[instance.syncState]!,
      'lastUpdatedAt': const SafeTimestampConverter().toJson(
        instance.lastUpdatedAt,
      ),
    };

const _$SyncStateEnumMap = {
  SyncState.localOnly: 'localOnly',
  SyncState.syncing: 'syncing',
  SyncState.synced: 'synced',
  SyncState.conflict: 'conflict',
};
