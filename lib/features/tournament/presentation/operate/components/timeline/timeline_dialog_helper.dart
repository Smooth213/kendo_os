import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/sheets/order_reorder_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// タイムライン画面用ダイアログ・ボトムシート呼び出しヘルパー
class TimelineDialogHelper {
  /// グループメモ編集シート表示
  static void showEditGroupNoteDialog(
    BuildContext context,
    WidgetRef ref,
    List<MatchModel> groupList,
  ) {
    if (groupList.isEmpty) return;
    final firstMatch = groupList.first;

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return MatchEditSheet(
          matches: groupList,
          tournamentId: firstMatch.tournamentId,
          themeColors: AppThemeColors.ofMode(
            isDark: Theme.of(context).brightness == Brightness.dark,
            mode: 'operate',
          ),
        );
      },
    );
  }

  /// 試合順並び替えシート表示
  static void showOrderReorderSheet(
    BuildContext context,
    WidgetRef ref,
    List<MatchModel> groupList,
  ) {
    final sortedMatches = List<MatchModel>.from(groupList)
      ..sort((a, b) => a.order.compareTo(b.order));

    if (sortedMatches.isEmpty) return;

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return OrderReorderBottomSheet(sortedMatches: sortedMatches);
      },
    );
  }
}
