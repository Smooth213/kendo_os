import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kendo_os/domain/entities/timeline_item.dart';

part 'timeline_projection.freezed.dart';

@freezed
abstract class TimelineProjection with _$TimelineProjection {
  const TimelineProjection._();

  const factory TimelineProjection({
    required String tournamentId,
    @Default([]) List<TimelineItem> items,
    required DateTime lastUpdatedAt,
  }) = _TimelineProjection;

  String get rebuildHash {
    final hashes = items.map((item) => item.rebuildHash).join(',');
    return 'timeline|$tournamentId|$hashes';
  }
}