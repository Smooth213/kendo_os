import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_timer_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart'; // ★ 追加: matchListProvider
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/application/services/kendo_haptics.dart';

class TimerWidget extends ConsumerWidget {
  final String matchId;
  final bool isInputLocked;

  const TimerWidget({
    super.key,
    required this.matchId,
    required this.isInputLocked,
  });

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showTimerEditDialog(
    BuildContext context,
    WidgetRef ref,
    MatchModel match,
  ) {
    final remainingSeconds = match.calculateRemainingSeconds(
      ref.read(timeSourceProvider).now(),
    );
    int m = (remainingSeconds / 60).floor();
    int s = remainingSeconds % 60;

    // iOS Native カラー
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final inputBgColor = context.appColors.inputBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;

    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: '時間修正',
        content: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: '$m',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontSize.display,
                  fontWeight: AppFontWeight.bold,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBgColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.medium,
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.medium,
                    borderSide: BorderSide(
                      color: const Color(0xFF3F51B5),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (v) => m = int.tryParse(v) ?? 0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: AppFontSize.display,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                initialValue: '$s',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontSize.display,
                  fontWeight: AppFontWeight.bold,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBgColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.medium,
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.medium,
                    borderSide: BorderSide(
                      color: const Color(0xFF3F51B5),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (v) => s = int.tryParse(v) ?? 0,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // ★ 修正: matchTimerProvider を使用
              ref
                  .read(matchTimerProvider)
                  .updateRemainingSeconds(matchId, (m * 60) + s);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF3F51B5)
                  : const Color(0xFF3F51B5),
              foregroundColor: const Color(0xFFFFFFFF),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.small,
              ),
            ),
            child: const Text(
              '更新',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ 修正：試合終了時(finished)にタイマーを「SizedBox.shrink()」で消滅させる処理を完全撤廃。
    // これにより、試合終了後もタイマーの枠（最終時間）がそのまま残り、下のボタンが上に伸びるレイアウト崩れが消滅します。
    // ※ 操作ロック（isInputLocked）は親から渡されているため、終了後に誤ってタイマーを動かしてしまう心配はありません。

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxs,
        ), // ★ 画面の圧迫を防ぐため余白をスリム化
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildTimerContent(context, ref),
        ),
      ),
    );
  }

  // ★ タイマーの中身をヘルパー関数として分離
  Widget _buildTimerContent(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(
      matchListProvider.select(
        (list) =>
            list.where((m) => m.id == matchId).firstOrNull?.timerIsRunning ??
            false,
      ),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerBgColor = isRunning
        ? (isDark
              ? context.appColors.errorColor.withValues(alpha: 0.4)
              : context.appColors.errorColor)
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));
    final timerBorderColor = isRunning
        ? (isDark ? context.appColors.errorColor : context.appColors.errorColor)
        : (isDark ? const Color(0xFF38383A) : const Color(0xFF3F51B5));
    final timerTextColor = isRunning
        ? (isDark ? context.appColors.errorColor : context.appColors.errorColor)
        : (context.appColors.textColor);

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // ★ 修正：透明な余白部分のタップ漏れを完全に防ぐ魔法のコード
      // ★ 修正: matchTimerProvider を使用
      onTap: isInputLocked
          ? null
          : () async {
              await KendoHaptics.timerToggle(isStarting: !isRunning);
              ref.read(matchTimerProvider).toggleTimer(matchId);
            },
      onLongPress: isInputLocked
          ? null
          : () {
              final match = ref
                  .read(matchListProvider)
                  .firstWhere((m) => m.id == matchId);
              _showTimerEditDialog(context, ref, match);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: timerBgColor,
          borderRadius: AppRadius.full,
          // ★ 修正：ロック時はボーダーを薄いグレーにし、太さも細く(1)固定する
          border: Border.all(
            color: isInputLocked
                ? AppKendoColors.grey.withValues(alpha: 0.3)
                : timerBorderColor,
            width: (isRunning && !isInputLocked) ? 4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ★ 修正：ロック時は「南京錠アイコン」にし、色もグレーにする
            Icon(
              isInputLocked
                  ? Icons.lock_outline
                  : (isRunning ? Icons.pause_circle : Icons.play_circle),
              color: isInputLocked
                  ? const Color(0x8A000000)
                  : (isRunning
                        ? (isDark
                              ? const Color(0xFFE53935)
                              : const Color(0xFFE53935))
                        : (isDark
                              ? const Color(0xFF3F51B5)
                              : const Color(0xFF3F51B5))),
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Consumer(
              builder: (context, ref, child) {
                final seconds = ref.watch(
                  liveRemainingSecondsProvider(matchId),
                );
                return Text(
                  _formatTime(seconds),
                  style: TextStyle(
                    fontSize: AppFontSize.scoreboardLarge,
                    fontWeight: AppFontWeight.bold,
                    // fontFamily: 'Courier',
                    height: 1.1,
                    // ★ 修正：ロック時はテキストもグレーアウトして「非アクティブ」を強調
                    color: isInputLocked
                        ? const Color(0x8A000000)
                        : timerTextColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
