import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_timer_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 錬成・申合せ時のマスタータイマー表示・操作Widget
class RenseikaiMasterTimerWidget extends ConsumerWidget {
  final String groupName;
  final bool isInputLocked;

  const RenseikaiMasterTimerWidget({
    super.key,
    required this.groupName,
    required this.isInputLocked,
  });

  String _formatTime(int seconds) {
    if (seconds < 0) return '0:00';
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterTime = ref.watch(renseikaiMasterTimerProvider(groupName));
    final isRunning = ref.watch(isMasterTimerRunningProvider(groupName));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTimeUp = masterTime == 0;

    final timerBgColor = isRunning
        ? (isDark
              ? context.appColors.primaryAccent.withValues(alpha: 0.4)
              : context.appColors.primaryAccent)
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));
    final timerBorderColor = isRunning
        ? (isDark
              ? context.appColors.primaryAccent
              : context.appColors.primaryAccent)
        : (isDark ? const Color(0xFF38383A) : const Color(0xFF009688));
    final timerTextColor = isRunning
        ? (isDark
              ? context.appColors.primaryAccent
              : context.appColors.primaryAccent)
        : (isDark
              ? context.appColors.subTextColor
              : context.appColors.subTextColor);

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isInputLocked
            ? null
            : () {
                ref
                    .read(renseikaiMasterTimerProvider(groupName).notifier)
                    .toggleTimer();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: timerBgColor,
            borderRadius: AppRadius.giant,
            border: Border.all(
              color: isTimeUp
                  ? AppKendoColors.red
                  : (isInputLocked
                        ? AppKendoColors.grey.withValues(alpha: 0.3)
                        : timerBorderColor),
              width: (isRunning && !isInputLocked) ? 4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRunning ? Icons.pause_circle : Icons.play_circle,
                color: isTimeUp
                    ? AppKendoColors.red
                    : (isRunning
                          ? (isDark
                                ? const Color(0xFF009688)
                                : const Color(0xFF009688))
                          : AppKendoColors.grey),
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'トータル',
                    style: TextStyle(
                      fontSize: AppFontSize.badge,
                      fontWeight: AppFontWeight.bold,
                      color: isTimeUp
                          ? AppKendoColors.red
                          : (isDark
                                ? const Color(0xFF009688)
                                : const Color(0xFF009688)),
                    ),
                  ),
                  Text(
                    _formatTime(masterTime),
                    style: TextStyle(
                      fontSize: AppFontSize.heroXl,
                      fontWeight: AppFontWeight.black,
                      height: 1.1,
                      color: isTimeUp ? AppKendoColors.red : timerTextColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
