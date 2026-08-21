import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_share_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 部内戦ホーム画面のアクション・ダイアログヘルパー
class BunaiksenHomeActionHelper {
  /// カレンダー日付ピッカー
  static Future<void> handleDatePicker({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime viewDate,
    required Set<String> availableDates,
    required AppThemeColors themeColors,
    required bool isDark,
  }) async {
    final todayStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final viewDateStr = DateFormat('yyyyMMdd').format(viewDate);
    final bool isViewDateSelectable =
        viewDateStr == todayStr || availableDates.contains(viewDateStr);
    final safeInitialDate = isViewDateSelectable ? viewDate : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      selectableDayPredicate: (date) {
        final dateStr = DateFormat('yyyyMMdd').format(date);
        final tStr = DateFormat('yyyyMMdd').format(DateTime.now());
        return availableDates.contains(dateStr) || dateStr == tStr;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: themeColors.primaryAccent,
                    onPrimary: context.appColors.textColor,
                    surface: themeColors.cardBackground,
                    onSurface: AppKendoColors.pureWhite,
                  )
                : ColorScheme.light(
                    primary: themeColors.primaryAccent,
                    onPrimary: AppKendoColors.pureWhite,
                    surface: themeColors.cardBackground,
                    onSurface: AppKendoColors.pureBlack,
                  ),
            dialogTheme: DialogThemeData(
              backgroundColor: themeColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(bunaiksenViewDateProvider.notifier).state = picked;
    }
  }

  /// 試合削除確認ダイアログ
  static void confirmDeleteMatch({
    required BuildContext context,
    required WidgetRef ref,
    required String matchId,
  }) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: '試合の削除',
        titleIcon: Icons.warning_amber_rounded,
        iconColor: AppKendoColors.red,
        content: const Text('この試合データを完全に削除します。この操作は取り消せません。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(matchCommandProvider).deleteMatch(matchId);
            },
            child: const Text(
              '削除',
              style: TextStyle(
                color: AppKendoColors.red,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 試合編集シート表示
  static void showEditNoteDialog({
    required BuildContext context,
    required MatchModel match,
    required AppThemeColors themeColors,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return MatchEditSheet(
          matches: [match],
          tournamentId: match.tournamentId,
          themeColors: themeColors,
        );
      },
    );
  }

  /// 共有ダイアログ表示
  static void showShareDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String tournamentId,
    required String dateDisplay,
  }) {
    final dojoId = ref.read(currentDojoIdProvider);
    BunaiksenShareDialog.show(
      context,
      tournamentId: tournamentId,
      dateDisplay: dateDisplay,
      dojoId: dojoId,
    );
  }
}
