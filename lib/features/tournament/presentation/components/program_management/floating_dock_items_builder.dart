import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/manual_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/viewer_qr_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_items_order_provider.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 フローティングドックのスピードダイヤル項目（全9機能・並び替え対応）を生成するビルダー
class FloatingDockItemsBuilder {
  static List<DockSubItem> build({
    required BuildContext context,
    required String tournamentId,
    required bool isViewerMode,
    required AppThemeColors themeColors,
    required int unreadCount,
    required VoidCallback onCollapse,
    List<DockItemType>? customOrder,
    String? timerDisplay,
    bool isTimerRunning = false,
  }) {
    final order = customOrder ?? DockItemsOrderNotifier.defaultOrder;

    return order.map((type) {
      switch (type) {
        case DockItemType.program:
          return DockSubItem(
            icon: Icons.menu_book_rounded,
            color: themeColors.primaryAccent,
            label: 'プログラム',
            onTap: () {
              onCollapse();
              FloatingDockSheetManager.show(
                context: context,
                builder: (_) => ProgramBottomSheet(
                  tournamentId: tournamentId,
                  isViewerMode: isViewerMode,
                ),
              );
            },
          );

        case DockItemType.matchStatus:
          return DockSubItem(
            icon: Icons.groups_rounded,
            color: AppKendoColors.indigo,
            label: '試合状況',
            onTap: () {
              onCollapse();
              FloatingDockSheetManager.show(
                context: context,
                builder: (_) => TeamMatchStatusScreen(
                  tournamentId: tournamentId,
                  isBottomSheet: true,
                  onFullScreen: () {
                    FloatingDockSheetManager.close(immediate: true);
                    context.push(
                      '/court-status?tournamentId=$tournamentId&viewer=$isViewerMode',
                    );
                  },
                ),
              );
            },
          );

        case DockItemType.officialRecord:
          return DockSubItem(
            icon: Icons.scoreboard_rounded,
            color: AppKendoColors.ipponGold,
            label: '対戦表',
            onTap: () {
              onCollapse();
              FloatingDockSheetManager.show(
                context: context,
                builder: (_) => OfficialRecordScreen(
                  tournamentId: tournamentId,
                  isBottomSheet: true,
                  onFullScreen: () {
                    FloatingDockSheetManager.close(immediate: true);
                    context.push(
                      '/official-record?id=$tournamentId&viewer=$isViewerMode',
                    );
                  },
                ),
              );
            },
          );

        case DockItemType.quickMemo:
          return DockSubItem(
            icon: Icons.brush_rounded,
            color: AppKendoColors.pink,
            label: 'クイックメモ',
            onTap: () {
              onCollapse();
              FloatingDockSheetManager.show(
                context: context,
                builder: (_) =>
                    QuickMemoBottomSheet(tournamentId: tournamentId),
              );
            },
          );

        case DockItemType.timer:
          return DockSubItem(
            icon: isTimerRunning ? Icons.timer_rounded : Icons.timer_outlined,
            color: isTimerRunning
                ? AppKendoColors.deepOrange
                : AppKendoColors.orangeAccent,
            label: timerDisplay != null && isTimerRunning
                ? timerDisplay
                : 'タイマー',
            onTap: () {
              onCollapse();
              DockTimerBottomSheet.show(context);
            },
          );

        case DockItemType.viewerQr:
          return DockSubItem(
            icon: Icons.qr_code_2_rounded,
            color: AppKendoColors.teal,
            label: '観戦QR',
            onTap: () {
              onCollapse();
              ViewerQrBottomSheet.show(
                context,
                tournamentId: tournamentId,
                isViewerMode: isViewerMode,
              );
            },
          );

        case DockItemType.announcements:
          return DockSubItem(
            icon: Icons.notifications_rounded,
            color: AppKendoColors.deepOrange,
            label: 'お知らせ',
            badgeCount: unreadCount,
            onTap: () {
              onCollapse();
              FloatingDockSheetManager.show(
                context: context,
                builder: (_) => AnnounceHistoryBottomSheet(
                  tournamentId: tournamentId,
                  isStaffRoom: !isViewerMode,
                ),
              );
            },
          );

        case DockItemType.manual:
          return DockSubItem(
            icon: Icons.help_outline_rounded,
            color: AppKendoColors.teal,
            label: 'ヘルプ',
            onTap: () {
              onCollapse();
              FloatingDockSheetManager.show(
                context: context,
                builder: (_) => ManualBottomSheet(isViewerMode: isViewerMode),
              );
            },
          );

        case DockItemType.settings:
          return DockSubItem(
            icon: Icons.settings_rounded,
            color: themeColors.subTextColor,
            label: '設定',
            onTap: () {
              onCollapse();
              if (isViewerMode) {
                ViewerSettingsBottomSheet.show(context);
              } else {
                FloatingDockSheetManager.show(
                  context: context,
                  builder: (_) => SettingsScreen(
                    isBottomSheet: true,
                    onFullScreen: () {
                      FloatingDockSheetManager.close(immediate: true);
                      context.push('/settings');
                    },
                  ),
                );
              }
            },
          );
      }
    }).toList();
  }
}
