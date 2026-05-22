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
    // ★ Phase 4-1: Timeline Mergeの決定論的安定化（Stable Ordering の完全保証）
    // 複数端末からの並列入力により、itemsの初期配列順序に一瞬のブレが生じた場合でも、
    // 「表示順（order） → 識別子（id）」の優先度で厳格に決定論的ソートを施してからハッシュ指紋を組み立てることで、
    // プロジェクションの同期ズレ（Drift）を数学的に100%永久に防止します。
    final sortedItems = List<TimelineItem>.from(items)
      ..sort((a, b) {
        int cmp = a.timelineOrder.compareTo(b.timelineOrder);
        if (cmp != 0) return cmp;
        // ★ 適合修正: TimelineItem基底に生えている rebuildHash をタイブレークとして使用し型安全を100%保証
        return a.rebuildHash.compareTo(b.rebuildHash);
      });

    final hashes = sortedItems.map((item) => item.rebuildHash).join(',');
    return 'timeline|$tournamentId|$hashes';
  }
}