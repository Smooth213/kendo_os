import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/match_strategy.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_infinite_handler_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_renseikai_next_button.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/last_used_settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 試合画面最下部のアクションボタンエリア（確定・次試合遷移・終了・延長・判定など）
class MatchBottomActionSection extends ConsumerWidget {
  final MatchModel match;
  final MatchRule rule;
  final bool isApproved;
  final bool isViewOnly;
  final bool isTie;
  final bool isAllDone;
  final bool isDark;
  final String myUserId;
  final List<MatchModel> teamMatches;
  final VoidCallback onAddRenseikaiNext;
  final Future<bool> Function(String title, String content) onShowConfirmDialog;
  final void Function(
    BuildContext context,
    MatchModel match,
    MatchModel? nextMatch,
  )
  onShowMatchFinishedDialog;
  final Future<String?> Function(MatchModel match) onShowHanteiDialog;

  const MatchBottomActionSection({
    super.key,
    required this.match,
    required this.rule,
    required this.isApproved,
    required this.isViewOnly,
    required this.isTie,
    required this.isAllDone,
    required this.isDark,
    required this.myUserId,
    required this.teamMatches,
    required this.onAddRenseikaiNext,
    required this.onShowConfirmDialog,
    required this.onShowMatchFinishedDialog,
    required this.onShowHanteiDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
      child: _buildContent(context, ref, settings),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SettingsModel settings,
  ) {
    if (isApproved) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: Text(
            '公式記録確定済み',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              color: AppKendoColors.grey,
            ),
          ),
        ),
      );
    }

    if (rule.isRenseikai &&
        rule.renseikaiType == '時間制' &&
        (match.matchType == rule.positions.last || match.matchType == '錬成会') &&
        match.status == 'finished') {
      return MatchRenseikaiNextButton(
        match: match,
        isViewOnly: isViewOnly,
        currentUserId: myUserId,
        onAddNext: onAddRenseikaiNext,
        onConfirmAndFinish: () async {
          if (settings.showConfirmDialog) {
            final confirmed = await onShowConfirmDialog(
              '記録の確定',
              'この試合の記録を確定して終了しますか？\n確定後は点数の修正ができなくなります。',
            );
            if (!confirmed) return;
          }

          await ref
              .read(matchApplicationServiceProvider)
              .approveMatch(match.id);

          if (!context.mounted) return;
          onShowMatchFinishedDialog(context, match, null);
        },
      );
    }

    if (match.status == 'finished') {
      final confirmAction = isViewOnly
          ? null
          : () async {
              if (settings.haptic) {
                HapticFeedback.heavyImpact();
              }

              if (match.isKachinuki && match.matchType == '無限勝ち抜き') {
                if (settings.showConfirmDialog) {
                  final confirmed = await onShowConfirmDialog(
                    '記録の確定',
                    'この試合の記録を確定して次に進みますか？\n確定後は点数の修正ができなくなります。',
                  );
                  if (!confirmed) return;
                }
                String winnerColor = 'draw';
                if ((match.redScore as num).toInt() >
                    (match.whiteScore as num).toInt()) {
                  winnerColor = 'red';
                } else if ((match.whiteScore as num).toInt() >
                    (match.redScore as num).toInt()) {
                  winnerColor = 'white';
                }

                if (!context.mounted) return;
                showAppDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                await MatchInfiniteHandlerHelper.handleMatchFinish(
                  context: context,
                  ref: ref,
                  currentMatch: match,
                  winnerColor: winnerColor,
                );
                return;
              }

              if (settings.showConfirmDialog) {
                final confirmed = await onShowConfirmDialog(
                  '記録の確定',
                  'この試合の記録を確定して次に進みますか？\n確定後は点数の修正ができなくなります。',
                );
                if (!confirmed) return;
              }

              await ref
                  .read(matchApplicationServiceProvider)
                  .approveMatch(match.id);

              if (!context.mounted) return;

              final matches = ref.read(matchListProvider);
              final groupNextMatches = matches
                  .where(
                    (m) =>
                        m.groupName == match.groupName &&
                        m.order > match.order &&
                        m.status != 'approved' &&
                        m.status != 'finished',
                  )
                  .toList();
              groupNextMatches.sort((a, b) => a.order.compareTo(b.order));

              if (groupNextMatches.isNotEmpty) {
                final nextM = groupNextMatches.first;
                final currentRedTeam = match.redName.contains(':')
                    ? match.redName.split(':').first.trim()
                    : match.redName;
                final currentWhiteTeam = match.whiteName.contains(':')
                    ? match.whiteName.split(':').first.trim()
                    : match.whiteName;
                final nextRedTeam = nextM.redName.contains(':')
                    ? nextM.redName.split(':').first.trim()
                    : nextM.redName;
                final nextWhiteTeam = nextM.whiteName.contains(':')
                    ? nextM.whiteName.split(':').first.trim()
                    : nextM.whiteName;

                bool isCardEndingPosition =
                    match.matchType == '大将' ||
                    match.matchType == '代表戦' ||
                    match.matchType == '個人戦' ||
                    match.matchType == '選手';

                if (currentRedTeam == nextRedTeam &&
                    currentWhiteTeam == nextWhiteTeam &&
                    !isCardEndingPosition &&
                    !match.isKachinuki) {
                  context.push('/match/${nextM.id}');
                } else {
                  onShowMatchFinishedDialog(context, match, nextM);
                }
              } else {
                bool hasDaihyo = rule.isLeague
                    ? rule.hasLeagueDaihyo
                    : rule.hasRepresentativeMatch;
                if (isTie &&
                    match.groupName != null &&
                    match.matchType != '代表戦' &&
                    hasDaihyo) {
                  context.push('/team-scoreboard/${match.groupName}');
                } else {
                  onShowMatchFinishedDialog(context, match, null);
                }
              }
            };

      final bool isTrulyTeamMatch =
          match.groupName != null && teamMatches.length > 1;

      return GestureDetector(
        onDoubleTap: settings.confirmBehavior == 'double'
            ? confirmAction
            : null,
        child: ElevatedButton.icon(
          onPressed: settings.confirmBehavior == 'single'
              ? confirmAction
              : (isViewOnly
                    ? null
                    : () => AppSnackBar.show(
                        context,
                        settings.confirmBehavior == 'double'
                            ? 'ダブルタップで確定してください'
                            : '長押しで確定してください',
                      )),
          onLongPress: settings.confirmBehavior == 'long'
              ? confirmAction
              : null,
          icon: Icon(
            (isTie && isTrulyTeamMatch)
                ? Icons.balance
                : (isAllDone ? Icons.emoji_events : Icons.verified),
            size: 24,
          ),
          label: Text(
            (isTie && isTrulyTeamMatch)
                ? '記録確定・星取表へ'
                : (isAllDone
                      ? ((match.tournamentId != null &&
                                match.tournamentId!.startsWith('bunaiksen_'))
                            ? '確定・部内戦ホームへ'
                            : '確定・大会ホームへ')
                      : '確定・次へ'),
            style: const TextStyle(
              fontSize: AppFontSize.subhead,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isTie
                ? AppKendoColors.hansokuRed
                : (isAllDone
                      ? const Color(0xFF303F9F)
                      : const Color(0xFF00897B)),
            foregroundColor: AppKendoColors.pureWhite,
            minimumSize: const Size(double.infinity, 36),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
            elevation: 4,
          ),
        ),
      );
    } else {
      final finishAction = isViewOnly
          ? null
          : () async {
              if (settings.haptic) {
                HapticFeedback.heavyImpact();
              }
              final strategy = MatchStrategyFactory.getStrategy(
                match,
                teamMatches.length,
              );
              final lastSettings = ref.read(lastUsedSettingsProvider);

              if (match.isKachinuki && match.matchType == '無限勝ち抜き') {
                if (settings.showConfirmDialog) {
                  final confirmed = await onShowConfirmDialog(
                    '試合終了',
                    'この試合を終了しますか？',
                  );
                  if (!confirmed) return;
                }
                String winnerColor = 'draw';
                if ((match.redScore as num).toInt() >
                    (match.whiteScore as num).toInt()) {
                  winnerColor = 'red';
                } else if ((match.whiteScore as num).toInt() >
                    (match.redScore as num).toInt()) {
                  winnerColor = 'white';
                }

                if (!context.mounted) return;
                showAppDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                await MatchInfiniteHandlerHelper.handleMatchFinish(
                  context: context,
                  ref: ref,
                  currentMatch: match,
                  winnerColor: winnerColor,
                );
                return;
              }

              if (match.redScore == match.whiteScore) {
                final nextAction = strategy.getNextActionOnTie(
                  match: match,
                  lastSettings: lastSettings,
                );

                if (nextAction == NextMatchAction.startExtension) {
                  final confirmed = await onShowConfirmDialog(
                    '延長戦',
                    '延長戦に入りますか？',
                  );
                  if (!confirmed) return;

                  final rule = match.rule;
                  final double extMins =
                      (match.extensionTimeMinutes != null &&
                          match.extensionTimeMinutes! > 0)
                      ? match.extensionTimeMinutes!
                      : (match.matchType == '代表戦'
                            ? (rule?.daihyoEnchoTimeMinutes ??
                                  ((lastSettings['daihyoEnchoTimeMinutes'] ??
                                              lastSettings['extensionTimeMinutes'] ??
                                              3.0)
                                          as num)
                                      .toDouble())
                            : (rule?.enchoTimeMinutes ??
                                  ((lastSettings['extensionTimeMinutes'] ?? 3.0)
                                          as num)
                                      .toDouble()));
                  final int currentExtCount = '延長'
                      .allMatches(match.note)
                      .length;
                  final extStr = '延長${currentExtCount + 1}回目';

                  final currentTime = ref.read(timeSourceProvider).now();
                  await ref
                      .read(matchApplicationServiceProvider)
                      .saveMatch(
                        match
                            .updateRemainingSeconds(
                              (extMins * 60).toInt(),
                              currentTime,
                            )
                            .copyWith(
                              timerStartedAt: null,
                              note: match.note.isEmpty
                                  ? extStr
                                  : '${match.note} ($extStr)',
                              extensionTimeMinutes: extMins,
                            ),
                      );

                  if (!context.mounted) return;
                  AppSnackBar.show(context, '$extStr（$extMins分）を開始します');
                  return;
                }

                if (nextAction == NextMatchAction.showHantei) {
                  final hanteiResult = await onShowHanteiDialog(match);
                  if (hanteiResult == null) return;

                  try {
                    if (hanteiResult == 'red' || hanteiResult == 'white') {
                      final side = hanteiResult == 'red'
                          ? Side.red
                          : Side.white;
                      await ref
                          .read(matchApplicationServiceProvider)
                          .finishMatchManually(match.id, hanteiWinner: side);
                    } else if (hanteiResult == 'draw') {
                      await ref
                          .read(matchApplicationServiceProvider)
                          .finishMatchManually(match.id);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackBar.showError(context, '判定の保存に失敗しました: $e');
                    }
                  }
                  return;
                }
              }

              if (settings.showConfirmDialog) {
                final confirmed = await onShowConfirmDialog(
                  '試合終了',
                  'この試合を終了しますか？',
                );
                if (!confirmed) return;
              }

              await ref
                  .read(matchApplicationServiceProvider)
                  .finishMatchManually(match.id);
            };

      return Consumer(
        builder: (context, ref, child) {
          final isProcessing = ref.watch(isMatchCommandProcessingProvider);
          final effectiveFinishAction = isProcessing ? null : finishAction;

          return GestureDetector(
            onDoubleTap: settings.confirmBehavior == 'double'
                ? effectiveFinishAction
                : null,
            child: ElevatedButton(
              onPressed: settings.confirmBehavior == 'single'
                  ? effectiveFinishAction
                  : (isViewOnly
                        ? null
                        : () => AppSnackBar.show(
                            context,
                            settings.confirmBehavior == 'double'
                                ? 'ダブルタップで終了してください'
                                : '長押しで終了してください',
                          )),
              onLongPress: settings.confirmBehavior == 'long'
                  ? effectiveFinishAction
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppKendoColors.blueAccent,
                foregroundColor: AppKendoColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 0),
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                elevation: 0,
              ),
              child: const Text(
                '試合終了',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
          );
        },
      );
    }
  }
}
