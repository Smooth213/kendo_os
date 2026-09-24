import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';

/// タイムライン並び替えロジック集約ヘルパー
class TimelineReorderHelper {
  /// アコーディオン内部のタイムラインアイテム（試合・見出しコメント）の並び替え
  static Future<void> onReorderInnerTimeline(
    List<TimelineItem> list,
    int oldIndex,
    int newIndex,
    WidgetRef ref,
  ) async {
    final permissions = ref.read(permissionProvider);
    if (permissions.isReadOnly) return;

    final targetIndex = newIndex;
    if (oldIndex == targetIndex) return;

    final item = list[oldIndex];
    final remaining = List<TimelineItem>.of(list)..removeAt(oldIndex);
    if (remaining.isEmpty) return;

    // リストは timelineOrder 降順 (大きい順) にソートされている
    double newOrder;
    if (targetIndex <= 0) {
      // 先頭に配置: 最上位のアイテムよりさらに大きくする
      newOrder = remaining.first.timelineOrder + 100.0;
    } else if (targetIndex >= remaining.length) {
      // 末尾に配置: 最下位のアイテムよりさらに小さくする
      newOrder = remaining.last.timelineOrder - 100.0;
    } else {
      // remaining[targetIndex - 1] と remaining[targetIndex] の間に挿入
      final upperOrder = remaining[targetIndex - 1].timelineOrder;
      final lowerOrder = remaining[targetIndex].timelineOrder;
      newOrder = (upperOrder + lowerOrder) / 2.0;
      if (newOrder == upperOrder || newOrder == lowerOrder) {
        newOrder = upperOrder - 0.001;
      }
    }

    if (item is MatchCommentModel) {
      try {
        await ref
            .read(commentCommandProvider)
            .updateCommentOrder(item, newOrder);
      } catch (e) {
        debugPrint('コメント並び替え保存エラー: $e');
      }
    } else if (item is MatchModel) {
      try {
        await ref.read(matchApplicationServiceProvider).saveMatchesBulk([
          item.copyWith(order: newOrder),
        ]);
      } catch (e) {
        debugPrint('試合並び替え保存エラー: $e');
      }
    }
  }

  /// 試合一覧の並び替え
  static Future<void> onReorderMatches(
    List<MatchModel> list,
    int oldIndex,
    int newIndex,
    WidgetRef ref,
  ) async {
    final permissions = ref.read(permissionProvider);
    if (permissions.isReadOnly) return;

    final targetIndex = newIndex;
    if (oldIndex == targetIndex) return;

    final item = list[oldIndex];
    final remaining = List<MatchModel>.of(list)..removeAt(oldIndex);
    if (remaining.isEmpty) return;

    // 試合一覧のソート順判定 (先頭が末尾より小さい場合は昇順)
    final isAscending =
        remaining.length >= 2 && remaining.first.order < remaining.last.order;

    double newOrder;
    if (isAscending) {
      if (targetIndex <= 0) {
        newOrder = remaining.first.order - 100.0;
      } else if (targetIndex >= remaining.length) {
        newOrder = remaining.last.order + 100.0;
      } else {
        final prevOrder = remaining[targetIndex - 1].order;
        final nextOrder = remaining[targetIndex].order;
        newOrder = (prevOrder + nextOrder) / 2.0;
        if (newOrder == prevOrder || newOrder == nextOrder) {
          newOrder = prevOrder + 0.001;
        }
      }
    } else {
      if (targetIndex <= 0) {
        newOrder = remaining.first.order + 100.0;
      } else if (targetIndex >= remaining.length) {
        newOrder = remaining.last.order - 100.0;
      } else {
        final upperOrder = remaining[targetIndex - 1].order;
        final lowerOrder = remaining[targetIndex].order;
        newOrder = (upperOrder + lowerOrder) / 2.0;
        if (newOrder == upperOrder || newOrder == lowerOrder) {
          newOrder = upperOrder - 0.001;
        }
      }
    }

    try {
      await ref.read(matchApplicationServiceProvider).saveMatchesBulk([
        item.copyWith(order: newOrder),
      ]);
    } catch (e) {
      debugPrint('並び替え保存エラー: $e');
    }
  }

  /// トップレベルタイムライン（コメント/試合グループ/個人戦選手）の並び替え
  static Future<void> onReorderTimeline(
    List<ReorderableTimelineItem> list,
    int oldIndex,
    int newIndex,
    WidgetRef ref,
  ) async {
    final permissions = ref.read(permissionProvider);
    if (permissions.isReadOnly) return;

    final targetIndex = newIndex;
    if (oldIndex == targetIndex) return;

    final item = list[oldIndex];
    final remaining = List<ReorderableTimelineItem>.of(list)
      ..removeAt(oldIndex);
    if (remaining.isEmpty) return;

    // リストは order 降順 (大きい順) にソートされている
    double newOrder;
    if (targetIndex <= 0) {
      // 先頭に配置: 最上位のアイテムよりさらに大きくする
      newOrder = remaining.first.order + 100.0;
    } else if (targetIndex >= remaining.length) {
      // 末尾に配置: 最下位のアイテムよりさらに小さくする
      newOrder = remaining.last.order - 100.0;
    } else {
      // remaining[targetIndex - 1] と remaining[targetIndex] の間に挿入
      final upperOrder = remaining[targetIndex - 1].order;
      final lowerOrder = remaining[targetIndex].order;
      newOrder = (upperOrder + lowerOrder) / 2.0;
      if (newOrder == upperOrder || newOrder == lowerOrder) {
        newOrder = upperOrder - 0.001;
      }
    }

    if (item is CommentTimelineItem) {
      try {
        await ref
            .read(commentCommandProvider)
            .updateCommentOrder(item.comment, newOrder);
      } catch (e) {
        debugPrint('コメント並び替え保存エラー: $e');
      }
    } else if (item is MatchGroupTimelineItem) {
      final offsetOrder = newOrder - item.order;
      final updatedMatches = item.matches
          .map((m) => m.copyWith(order: m.order + offsetOrder))
          .toList();
      try {
        await ref
            .read(matchApplicationServiceProvider)
            .saveMatchesBulk(updatedMatches);
      } catch (e) {
        debugPrint('グループ並び替え保存エラー: $e');
      }
    } else if (item is IndividualPlayerTimelineItem) {
      final offsetOrder = newOrder - item.order;
      final updatedMatches = item.matches
          .map((m) => m.copyWith(order: m.order + offsetOrder))
          .toList();
      try {
        await ref
            .read(matchApplicationServiceProvider)
            .saveMatchesBulk(updatedMatches);
      } catch (e) {
        debugPrint('個人戦選手並び替え保存エラー: $e');
      }
    }
  }
}
