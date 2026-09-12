import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 部内戦ドック：カレンダー日付切替・稽古日アーカイブ選択シート
class BunaiksenDockCalendarSheet extends ConsumerWidget {
  const BunaiksenDockCalendarSheet({super.key});

  static void show(BuildContext context) {
    FloatingDockSheetManager.show(
      context: context,
      builder: (_) => const BunaiksenDockCalendarSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final currentDate = ref.watch(bunaiksenViewDateProvider);
    final isToday = _isSameDay(currentDate, DateTime.now());

    return DockDraggableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: DockBottomSheetHeader(
                      title: '部内戦カレンダー・稽古日',
                      icon: Icons.calendar_month_rounded,
                      iconColor: AppKendoColors.teal,
                    ),
                  ),
                  if (!isToday)
                    TextButton.icon(
                      icon: const Icon(Icons.today_rounded, size: 16),
                      label: const Text('今日に戻る'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppKendoColors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                      ),
                      onPressed: () {
                        AppHaptics.selection();
                        ref.read(bunaiksenViewDateProvider.notifier).state =
                            DateTime.now();
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                children: [
                  // 現在選択中の日付バナー
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppKendoColors.teal.withValues(alpha: 0.12),
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: AppKendoColors.teal.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          color: AppKendoColors.teal,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          DateFormat(
                            'yyyy年MM月dd日 (E)',
                            'ja',
                          ).format(currentDate),
                          style: TextStyle(
                            fontSize: AppFontSize.headline,
                            fontWeight: AppFontWeight.bold,
                            color: themeColors.textColor,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: const BoxDecoration(
                              color: AppKendoColors.teal,
                              borderRadius: AppRadius.tiny,
                            ),
                            child: const Text(
                              '今日',
                              style: TextStyle(
                                fontSize: AppFontSize.badge,
                                fontWeight: AppFontWeight.bold,
                                color: AppKendoColors.pureWhite,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // カレンダーピッカー
                  CalendarDatePicker(
                    initialDate: currentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    onDateChanged: (newDate) {
                      AppHaptics.selection();
                      ref.read(bunaiksenViewDateProvider.notifier).state =
                          newDate;
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
