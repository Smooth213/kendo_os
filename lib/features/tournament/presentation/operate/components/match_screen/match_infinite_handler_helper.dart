import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_infinite_next_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/bunaiksen_infinite_engine_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 試合画面用 無限勝ち抜き結果処理ヘルパー
class MatchInfiniteHandlerHelper {
  static Future<void> handleMatchFinish({
    required BuildContext context,
    required WidgetRef ref,
    required MatchModel currentMatch,
    required String winnerColor,
  }) async {
    final finishedMatch = currentMatch
        .copyWith(status: 'finished', timerStartedAt: null)
        .updateRemainingSeconds(0, ref.read(timeSourceProvider).now());
    await ref.read(matchApplicationServiceProvider).saveMatch(finishedMatch);

    final engine = ref.read(bunaiksenInfiniteEngineProvider);
    final nextMatch = await engine.processMatchResult(
      finishedMatch,
      winnerColor,
    );

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // プログレスダイアログを閉じる

    if (nextMatch != null) {
      final streaks = ref.read(bunaiksenInfiniteStreakProvider);
      final winnerStreak = streaks[nextMatch.redName] ?? 0;

      showAppDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return MatchInfiniteNextDialog(
            redName: nextMatch.redName,
            whiteName: nextMatch.whiteName,
            winnerStreak: winnerStreak,
            onFinishInfinite: () {
              Navigator.of(dialogContext).pop();
              ref.read(bunaiksenInfiniteQueueProvider.notifier).setPlayers([]);
              ref.read(bunaiksenInfiniteStreakProvider.notifier).clearAll();
              context.pop();
            },
            onRestAndReturn: () {
              Navigator.of(dialogContext).pop();
              final queueNotifier = ref.read(
                bunaiksenInfiniteQueueProvider.notifier,
              );
              final currentQueue = ref.read(bunaiksenInfiniteQueueProvider);
              final filteredQueue = currentQueue
                  .where(
                    (p) => p != nextMatch.redName && p != nextMatch.whiteName,
                  )
                  .toList();
              queueNotifier.setPlayers([
                nextMatch.redName,
                nextMatch.whiteName,
                ...filteredQueue,
              ]);
              context.pop();
            },
            onStartNextMatchImmediately: () async {
              Navigator.of(dialogContext).pop();
              final startMatch = nextMatch.copyWith(status: 'in_progress');
              await ref
                  .read(matchApplicationServiceProvider)
                  .saveMatch(startMatch);
              if (context.mounted) {
                context.pushReplacement('/match/${nextMatch.id}');
              }
            },
          );
        },
      );
    } else {
      AppSnackBar.show(context, '待機列の選手がいなくなりました。無限稽古を終了します');
      context.pop();
    }
  }
}
