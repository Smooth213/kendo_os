import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:uuid/uuid.dart';

/// タイムライン用 他コート簡易入力ダイアログ
class TimelineSummaryInputDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    List<MatchModel> matches,
  ) {
    final normalMatches = matches
        .where((m) => m.matchType != '代表戦' && m.matchType != '順位決定戦')
        .toList();
    if (normalMatches.isEmpty) return;

    final int totalMatches = normalMatches.length;
    int rWins = 0, rPts = 0, wWins = 0, wPts = 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rTeam = normalMatches.first.redName.split(':').first.trim();
    final wTeam = normalMatches.first.whiteName.split(':').first.trim();

    showAppDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          Widget buildCounter(
            String label,
            int value,
            VoidCallback onMinus,
            VoidCallback onPlus,
            Color color,
          ) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: AppFontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: color),
                      onPressed: value > 0
                          ? () {
                              onMinus();
                              setState(() {});
                            }
                          : null,
                    ),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$value',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: AppFontSize.headline,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: color),
                      onPressed: () {
                        onPlus();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            );
          }

          bool isValid =
              (rWins + wWins <= totalMatches) &&
              (rPts >= rWins && rPts <= rWins * 2) &&
              (wPts >= wWins && wPts <= wWins * 2);
          String errorMsg = '';
          if (rWins + wWins > totalMatches) {
            errorMsg = '勝者数の合計が試合数($totalMatches)を超えています';
          } else if (rPts < rWins) {
            errorMsg = '赤の本数が少なすぎます（1勝につき最低1本）';
          } else if (rPts > rWins * 2) {
            errorMsg = '赤の本数が多すぎます（1勝につき最大2本）';
          } else if (wPts < wWins) {
            errorMsg = '白の本数が少なすぎます';
          } else if (wPts > wWins * 2) {
            errorMsg = '白の本数が多すぎます';
          }

          return AppDialog(
            backgroundColor: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
            titleWidget: const Text(
              '他コートの簡易入力',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '他チームの試合結果（勝者数と本数）だけを素早く記録します。',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      color: AppKendoColors.grey,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFE53935).withValues(alpha: 0.15)
                          : const Color(0xFFE53935),
                      borderRadius: AppRadius.medium,
                      border: Border.all(color: const Color(0xFFE53935)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          rTeam,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFE53935)
                                : const Color(0xFFE53935),
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.subhead,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        buildCounter('勝者数', rWins, () => rWins--, () {
                          if (rWins + wWins < totalMatches) {
                            rWins++;
                          }
                        }, AppKendoColors.red),
                        buildCounter('取得本数', rPts, () => rPts--, () {
                          if (rPts < rWins * 2) {
                            rPts++;
                          }
                        }, AppKendoColors.red),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2196F3).withValues(alpha: 0.15)
                          : const Color(0xFF2196F3),
                      borderRadius: AppRadius.medium,
                      border: Border.all(color: const Color(0xFF2196F3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          wTeam,
                          style: TextStyle(
                            color: context.appColors.infoColor,
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.subhead,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        buildCounter('勝者数', wWins, () => wWins--, () {
                          if (rWins + wWins < totalMatches) {
                            wWins++;
                          }
                        }, AppKendoColors.blue),
                        buildCounter('取得本数', wPts, () => wPts--, () {
                          if (wPts < wWins * 2) {
                            wPts++;
                          }
                        }, AppKendoColors.blue),
                      ],
                    ),
                  ),
                  if (errorMsg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        errorMsg,
                        style: const TextStyle(
                          color: AppKendoColors.red,
                          fontSize: AppFontSize.small,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
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
                onPressed: () async {
                  if (!isValid) {
                    showAppDialog(
                      context: context,
                      builder: (dialogCtx) => AppDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.large,
                        ),
                        titleWidget: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppKendoColors.orange,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text('入力エラー'),
                          ],
                        ),
                        content: Text(
                          errorMsg,
                          style: const TextStyle(
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('確認'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  showAppDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  try {
                    int rw = rWins, rp = rPts, ww = wWins, wp = wPts;
                    for (var m in normalMatches) {
                      List<ScoreEvent> events = [];
                      int matchRedScore = 0;
                      int matchWhiteScore = 0;
                      final now = ref.read(timeSourceProvider).now();
                      if (rw > 0) {
                        rw--;
                        int p = (rp > rw) ? 2 : 1;
                        if (p > rp) p = rp;
                        rp -= p;
                        matchRedScore = p;
                        for (int i = 0; i < p; i++) {
                          events.add(
                            ScoreEventLegacyAdapter.fromLegacy(
                              id: const Uuid().v4(),
                              type: PointType.fusen,
                              side: Side.red,
                              timestamp: now,
                            ),
                          );
                        }
                      } else if (ww > 0) {
                        ww--;
                        int p = (wp > ww) ? 2 : 1;
                        if (p > wp) p = wp;
                        wp -= p;
                        matchWhiteScore = p;
                        for (int i = 0; i < p; i++) {
                          events.add(
                            ScoreEventLegacyAdapter.fromLegacy(
                              id: const Uuid().v4(),
                              type: PointType.fusen,
                              side: Side.white,
                              timestamp: now,
                            ),
                          );
                        }
                      }
                      final String newNote = m.note.contains('[SUMMARY]')
                          ? m.note
                          : '${m.note} [SUMMARY]'.trim();
                      final updated = m.copyWith(
                        status: 'approved',
                        note: newNote,
                        events: events,
                        redScore: matchRedScore,
                        whiteScore: matchWhiteScore,
                      );
                      await ref
                          .read(matchApplicationServiceProvider)
                          .saveMatch(updated);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackBar.showError(context, 'エラー: $e');
                    }
                  } finally {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKendoColors.indigo,
                  foregroundColor: AppKendoColors.pureWhite,
                  elevation: 0,
                ),
                child: const Text(
                  '記録を確定する',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
