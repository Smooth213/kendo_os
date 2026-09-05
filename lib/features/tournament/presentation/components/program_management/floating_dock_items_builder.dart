import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/manual_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 フローティングドックのスピードダイヤル項目（7機能）を生成するビルダー
class FloatingDockItemsBuilder {
  static List<DockSubItem> build({
    required BuildContext context,
    required String tournamentId,
    required bool isViewerMode,
    required AppThemeColors themeColors,
    required int unreadCount,
    required VoidCallback onCollapse,
  }) {
    return [
      DockSubItem(
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
      ),
      DockSubItem(
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
                  '/team-match-status?id=$tournamentId&viewer=$isViewerMode',
                );
              },
            ),
          );
        },
      ),
      DockSubItem(
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
      ),
      DockSubItem(
        icon: Icons.brush_rounded,
        color: AppKendoColors.pink,
        label: 'クイックメモ',
        onTap: () {
          onCollapse();
          FloatingDockSheetManager.show(
            context: context,
            builder: (_) => QuickMemoBottomSheet(tournamentId: tournamentId),
          );
        },
      ),
      DockSubItem(
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
      ),
      DockSubItem(
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
      ),
      DockSubItem(
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
      ),
    ];
  }
}
