import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 独立型カウントダウンタイマー＆ストップウォッチ・ボトムシート
class DockTimerBottomSheet extends ConsumerWidget {
  const DockTimerBottomSheet({super.key});

  static void show(BuildContext context) {
    FloatingDockSheetManager.show(
      context: context,
      builder: (_) => const DockTimerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final timerState = ref.watch(dockTimerProvider);
    final timerNotifier = ref.read(dockTimerProvider.notifier);

    final isStopwatch = timerState.mode == DockTimerMode.stopwatch;
    final isRunning = timerState.isRunning;
    final isFinished = timerState.isFinished;

    return DockDraggableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          children: [
            DockBottomSheetHeader(
              title: isStopwatch ? 'ストップウォッチ' : '独立型タイマー',
              icon: isStopwatch
                  ? Icons.timer_outlined
                  : Icons.hourglass_top_rounded,
              iconColor: AppKendoColors.orangeAccent,
            ),
            const SizedBox(height: AppSpacing.sm),

            // モード切替タブ (カウントダウン ⇄ ストップウォッチ)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              decoration: BoxDecoration(
                color: themeColors.surface,
                borderRadius: AppRadius.round,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (isStopwatch) timerNotifier.toggleMode();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: !isStopwatch
                              ? themeColors.cardBackground
                              : AppKendoColors.transparent,
                          borderRadius: AppRadius.round,
                          boxShadow: !isStopwatch
                              ? [
                                  BoxShadow(
                                    color: AppKendoColors.black.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'カウントダウン',
                          style: TextStyle(
                            fontSize: AppFontSize.bodySmall,
                            fontWeight: !isStopwatch
                                ? AppFontWeight.bold
                                : AppFontWeight.regular,
                            color: !isStopwatch
                                ? themeColors.textColor
                                : themeColors.subTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!isStopwatch) timerNotifier.toggleMode();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isStopwatch
                              ? themeColors.cardBackground
                              : AppKendoColors.transparent,
                          borderRadius: AppRadius.round,
                          boxShadow: isStopwatch
                              ? [
                                  BoxShadow(
                                    color: AppKendoColors.black.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'ストップウォッチ',
                          style: TextStyle(
                            fontSize: AppFontSize.bodySmall,
                            fontWeight: isStopwatch
                                ? AppFontWeight.bold
                                : AppFontWeight.regular,
                            color: isStopwatch
                                ? themeColors.textColor
                                : themeColors.subTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 特大デジタル時計表示
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isFinished
                      ? AppKendoColors.hansokuRed.withValues(alpha: 0.15)
                      : themeColors.cardBackground,
                  borderRadius: AppRadius.large,
                  border: Border.all(
                    color: isFinished
                        ? AppKendoColors.hansokuRed
                        : (isRunning
                              ? AppKendoColors.orangeAccent
                              : themeColors.separatorColor.withValues(
                                  alpha: 0.4,
                                )),
                    width: isRunning ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    if (isFinished)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          '⏰ TIME UP !',
                          style: TextStyle(
                            fontSize: AppFontSize.subhead,
                            fontWeight: AppFontWeight.bold,
                            color: AppKendoColors.hansokuRed,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    Text(
                      timerState.formattedDisplay,
                      style: TextStyle(
                        fontSize: AppFontSize.scoreboardTimer,
                        fontWeight: AppFontWeight.bold,
                        fontFamily: 'monospace',
                        color: isFinished
                            ? AppKendoColors.hansokuRed
                            : (isRunning
                                  ? AppKendoColors.orangeAccent
                                  : themeColors.textColor),
                        letterSpacing: 2.0,
                      ),
                    ),
                    if (!isStopwatch)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        child: ClipRRect(
                          borderRadius: AppRadius.small,
                          child: LinearProgressIndicator(
                            value: timerState.progress,
                            minHeight: 6,
                            backgroundColor: themeColors.separatorColor
                                .withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFinished
                                  ? AppKendoColors.hansokuRed
                                  : AppKendoColors.orangeAccent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // カウントダウン時: 定型プリセットチップ群
            if (!isStopwatch) ...[
              const Text(
                '定型プリセット',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _PresetButton(
                    label: '3分 (試合間)',
                    seconds: 180,
                    isActive: timerState.initialSeconds == 180 && !isRunning,
                    onTap: () => timerNotifier.setPreset(180),
                  ),
                  _PresetButton(
                    label: '5分 (回り稽古)',
                    seconds: 300,
                    isActive: timerState.initialSeconds == 300 && !isRunning,
                    onTap: () => timerNotifier.setPreset(300),
                  ),
                  _PresetButton(
                    label: '10分 (アップ)',
                    seconds: 600,
                    isActive: timerState.initialSeconds == 600 && !isRunning,
                    onTap: () => timerNotifier.setPreset(600),
                  ),
                  _PresetButton(
                    label: '15分 (合同稽古)',
                    seconds: 900,
                    isActive: timerState.initialSeconds == 900 && !isRunning,
                    onTap: () => timerNotifier.setPreset(900),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // クイック延長ボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => timerNotifier.addSeconds(30),
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: const Text('+30秒'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => timerNotifier.addSeconds(60),
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: const Text('+1分'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 操作ボタン群 (スタート/ストップ、リセット)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: timerNotifier.toggleStartPause,
                    icon: Icon(
                      isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppKendoColors.pureWhite,
                    ),
                    label: Text(
                      isRunning ? '一時停止' : 'スタート',
                      style: const TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: AppFontWeight.bold,
                        color: AppKendoColors.pureWhite,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunning
                          ? AppKendoColors.deepOrange
                          : AppKendoColors.orangeAccent,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: timerNotifier.reset,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: themeColors.textColor,
                    ),
                    label: Text(
                      'リセット',
                      style: TextStyle(
                        color: themeColors.textColor,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      side: BorderSide(color: themeColors.separatorColor),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final int seconds;
  final bool isActive;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.seconds,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppKendoColors.orangeAccent.withValues(alpha: 0.2)
              : themeColors.cardBackground,
          borderRadius: AppRadius.round,
          border: Border.all(
            color: isActive
                ? AppKendoColors.orangeAccent
                : themeColors.separatorColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.bodySmall,
            fontWeight: isActive ? AppFontWeight.bold : AppFontWeight.regular,
            color: isActive
                ? AppKendoColors.orangeAccent
                : themeColors.textColor,
          ),
        ),
      ),
    );
  }
}
