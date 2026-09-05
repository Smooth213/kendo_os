import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_share_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_screen.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 観客用大会ホームのヘッダーアクション（お知らせベル ＆ その他メニュー）
class ViewerHomeHeaderActions extends ConsumerWidget {
  final String tournamentId;
  final bool isDark;
  final Color iconColor;

  const ViewerHomeHeaderActions({
    super.key,
    required this.tournamentId,
    required this.isDark,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NotificationBellButton(
          tournamentId: tournamentId,
          isStaffRoom: false,
          color: iconColor,
        ),
        IconButton(
          icon: Icon(Icons.qr_code_2, color: iconColor),
          tooltip: '大会を共有する',
          onPressed: () {
            ViewerShareDialog.show(
              context,
              tournamentId: tournamentId,
              dojoId: ref.read(currentDojoIdProvider),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_horiz_rounded, color: iconColor, size: 26),
          tooltip: 'メニュー',
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
          color: themeColors.cardBackground,
          elevation: 6,
          onSelected: (value) {
            switch (value) {
              case 'share':
                ViewerShareDialog.show(
                  context,
                  tournamentId: tournamentId,
                  dojoId: ref.read(currentDojoIdProvider),
                );
                break;
              case 'settings':
                ViewerSettingsBottomSheet.show(context);
                break;
              case 'faq':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmbeddedManualScreen(
                      initialFilePath: 'docs/manuals/faq/viewer_faq.md',
                    ),
                  ),
                );
                break;
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem<String>(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.qr_code_2, color: themeColors.textColor, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '大会を共有する',
                    style: TextStyle(
                      color: themeColors.textColor,
                      fontSize: AppFontSize.body,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: themeColors.textColor, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '表示設定',
                    style: TextStyle(
                      color: themeColors.textColor,
                      fontSize: AppFontSize.body,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'faq',
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: themeColors.textColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '観戦ヘルプ・FAQ',
                    style: TextStyle(
                      color: themeColors.textColor,
                      fontSize: AppFontSize.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}
