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
    if (permissions.isReadOnly || oldIndex == newIndex) {
      return;
    }

    final item = list[oldIndex];
    double newOrder;
    if (newIndex == 0) {
      newOrder = list.first.timelineOrder - 100.0;
    } else if (newIndex == list.length - 1) {
      newOrder = list.last.timelineOrder + 100.0;
    } else {
      final prevOrder =
          list[newIndex > oldIndex ? newIndex : newIndex - 1].timelineOrder;
      final nextOrder =
          list[newIndex > oldIndex ? newIndex + 1 : newIndex].timelineOrder;
      newOrder = (prevOrder + nextOrder) / 2.0;
    }
    if (newOrder == list[newIndex].timelineOrder) {
      newOrder += 0.001;
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
    if (permissions.isReadOnly || oldIndex == newIndex) return;

    final item = list[oldIndex];
    double newOrder;
    if (newIndex == 0) {
      newOrder = list.first.order - 100.0;
    } else if (newIndex == list.length - 1) {
      newOrder = list.last.order + 100.0;
    } else {
      final prevOrder =
          list[newIndex > oldIndex ? newIndex : newIndex - 1].order;
      final nextOrder =
          list[newIndex > oldIndex ? newIndex + 1 : newIndex].order;
      newOrder = (prevOrder + nextOrder) / 2.0;
    }
    if (newOrder == list[newIndex].order) {
      newOrder += 0.001;
    }

    try {
      await ref.read(matchApplicationServiceProvider).saveMatchesBulk([
        item.copyWith(order: newOrder),
      ]);
    } catch (e) {
      debugPrint('並び替え保存エラー: $e');
    }
  }

  /// トップレベルタイムライン（コメント/試合グループ）の並び替え
  static Future<void> onReorderTimeline(
    List<ReorderableTimelineItem> list,
    int oldIndex,
    int newIndex,
    WidgetRef ref,
  ) async {
    final permissions = ref.read(permissionProvider);
    if (permissions.isReadOnly || oldIndex == newIndex) return;

    final item = list[oldIndex];
    double newOrder;
    if (newIndex == 0) {
      newOrder = list.first.order - 100.0;
    } else if (newIndex == list.length - 1) {
      newOrder = list.last.order + 100.0;
    } else {
      final prevOrder =
          list[newIndex > oldIndex ? newIndex : newIndex - 1].order;
      final nextOrder =
          list[newIndex > oldIndex ? newIndex + 1 : newIndex].order;
      newOrder = (prevOrder + nextOrder) / 2.0;
    }
    if (newOrder == list[newIndex].order) {
      newOrder += 0.001;
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
    }
  }
}
