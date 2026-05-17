import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import '../../infrastructure/persistence/converters/json_converters.dart';
import 'timeline_item.dart';
import 'match_model.dart'; // SyncState, コンバーター等の共有

part 'match_comment_model.freezed.dart';
part 'match_comment_model.g.dart';

@freezed
abstract class MatchCommentModel with _$MatchCommentModel implements TimelineItem {
  const MatchCommentModel._();

  const factory MatchCommentModel({
    required String id,
    String? tournamentId,
    String? category,
    String? groupName,
    required String text,
    @DoubleConverter() @Default(0.0) double order,
    @Default(SyncState.synced) SyncState syncState,
    @SafeTimestampConverter() DateTime? lastUpdatedAt,
  }) = _MatchCommentModel;

  factory MatchCommentModel.fromJson(Map<String, dynamic> json) => _$MatchCommentModelFromJson(json);

  @override
  String get timelineId => id;
  
  @override
  double get timelineOrder => order;
  
  @override
  TimelineItemType get itemType => TimelineItemType.comment;
}