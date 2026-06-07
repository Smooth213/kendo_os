// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProgramModel _$ProgramModelFromJson(Map<String, dynamic> json) =>
    _ProgramModel(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      title: json['title'] as String,
      fileUrl: json['fileUrl'] as String,
      fileType: json['fileType'] as String,
      pageCount: (json['pageCount'] as num?)?.toInt() ?? 1,
      isOcrProcessed: json['isOcrProcessed'] as bool?,
      ocrWords: json['ocrWords'] as List<dynamic>?,
      createdAt: const TimestampConverter().fromJson(
        json['createdAt'] as Timestamp,
      ),
    );

Map<String, dynamic> _$ProgramModelToJson(_ProgramModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournamentId': instance.tournamentId,
      'title': instance.title,
      'fileUrl': instance.fileUrl,
      'fileType': instance.fileType,
      'pageCount': instance.pageCount,
      'isOcrProcessed': instance.isOcrProcessed,
      'ocrWords': instance.ocrWords,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };

_StrokeModel _$StrokeModelFromJson(Map<String, dynamic> json) => _StrokeModel(
  id: json['id'] as String,
  programId: json['programId'] as String,
  pageIndex: (json['pageIndex'] as num).toInt(),
  authorId: json['authorId'] as String,
  colorValue: (json['colorValue'] as num).toInt(),
  strokeWidth: (json['strokeWidth'] as num).toDouble(),
  points: (json['points'] as List<dynamic>)
      .map((e) => (e as num).toDouble())
      .toList(),
  isShared: json['isShared'] as bool,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$StrokeModelToJson(_StrokeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'programId': instance.programId,
      'pageIndex': instance.pageIndex,
      'authorId': instance.authorId,
      'colorValue': instance.colorValue,
      'strokeWidth': instance.strokeWidth,
      'points': instance.points,
      'isShared': instance.isShared,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
