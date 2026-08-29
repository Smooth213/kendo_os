import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_share_dialog.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

class ViewerBunaiksenHeaderActions extends ConsumerWidget {
  final String tournamentId;
  final String dateDisplay;
  final String dojoId;
  final bool isDark;
  final bool isQrAccess;
  final Set<String> availableDates;

  const ViewerBunaiksenHeaderActions({
    super.key,
    required this.tournamentId,
    required this.dateDisplay,
    required this.dojoId,
    required this.isDark,
    required this.isQrAccess,
    required this.availableDates,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen_viewer');

    final iconColor = isDark
        ? const Color(0xFFFFFFFF)
        : themeColors.primaryAccent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isQrAccess)
          IconButton(
            icon: Icon(Icons.calendar_month, color: iconColor),
            tooltip: '日付選択',
            onPressed: () async {
              DateTime initialDate = DateTime.now();
              if (tournamentId.startsWith('bunaiksen_') &&
                  tournamentId.length == 18) {
                final dateStr = tournamentId.substring(10);
                if (dateStr.length == 8) {
                  final parsed = DateTime.tryParse(dateStr);
                  if (parsed != null) {
                    initialDate = parsed;
                  }
                }
              }

              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                selectableDayPredicate: (DateTime date) {
                  final dStr = DateFormat('yyyyMMdd').format(date);
                  final todayStr = DateFormat(
                    'yyyyMMdd',
                  ).format(DateTime.now());
                  return dStr == todayStr || availableDates.contains(dStr);
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
                final nextTournamentId =
                    'bunaiksen_${DateFormat('yyyyMMdd').format(picked)}';
                if (!context.mounted) return;
                context.pushReplacement(
                  '/bunaiksen-viewer-home/$nextTournamentId?role=viewer&dojoId=$dojoId',
                );
              }
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
              case 'record':
                context.push('/bunaiksen-viewer-record/$tournamentId');
                break;
              case 'share':
                ViewerBunaiksenShareDialog.show(
                  context,
                  ref,
                  tournamentId: tournamentId,
                  dateDisplay: dateDisplay,
                );
                break;
              case 'settings':
                showAppBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const ViewerSettingsBottomSheet(),
                );
                break;
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem<String>(
              value: 'record',
              child: Row(
                children: [
                  Icon(
                    Icons.leaderboard_outlined,
                    color: themeColors.textColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '部内戦 成績一覧',
                    style: TextStyle(
                      color: themeColors.textColor,
                      fontSize: AppFontSize.body,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.qr_code_2, color: themeColors.textColor, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '観戦リンクを共有する',
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
          ],
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}
